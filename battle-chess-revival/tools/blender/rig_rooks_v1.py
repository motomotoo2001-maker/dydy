#!/usr/bin/env python3
"""Rig production Rook GLBs and author gameplay/capture clips."""
import argparse, sys
from pathlib import Path
from math import radians
import bpy

def parse_args():
    av=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    p=argparse.ArgumentParser()
    p.add_argument("--input",required=True); p.add_argument("--output",required=True)
    p.add_argument("--side",choices=("white","black"),required=True)
    return p.parse_args(av)

def add_bone(arm,name,head,tail,parent=None):
    b=arm.edit_bones.new(name); b.head=head; b.tail=tail
    if parent: b.parent=arm.edit_bones.get(parent)
    return b

def key(pb,frame,loc=(0,0,0),rot=(0,0,0),scale=(1,1,1)):
    pb.rotation_mode="XYZ"; pb.location=loc
    pb.rotation_euler=tuple(radians(v) for v in rot); pb.scale=scale
    pb.keyframe_insert("location",frame=frame); pb.keyframe_insert("rotation_euler",frame=frame); pb.keyframe_insert("scale",frame=frame)

def reset_pose(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode="XYZ"; pb.location=(0,0,0); pb.rotation_euler=(0,0,0); pb.scale=(1,1,1)

def make_action(arm,name,length,keys):
    act=bpy.data.actions.new(name)
    if arm.animation_data is None: arm.animation_data_create()
    arm.animation_data.action=act; reset_pose(arm)
    bones=["root","body","crown","arm.l","arm.r","fist.l","fist.r"]
    for f in (1,length):
        for b in bones:
            if b in arm.pose.bones:key(arm.pose.bones[b],f)
    for bone,frame,loc,rot,scale in keys:
        if bone in arm.pose.bones:key(arm.pose.bones[bone],frame,loc,rot,scale)
    tr=arm.animation_data.nla_tracks.new(); tr.name=name
    st=tr.strips.new(name,1,act); st.action_frame_start=1; st.action_frame_end=length
    arm.animation_data.action=None

def bone_for(name):
    if name.startswith(("Pedestal","WaistBand")): return "root"
    if name.startswith(("Crown","Brow","Eye","Mouth")): return "crown"
    if name.startswith(("Arm_L","Shoulder_L","ShoulderPlate_L","SideBand_L","SideInset_L")): return "arm.l"
    if name.startswith(("Arm_R","Shoulder_R","ShoulderPlate_R","SideBand_R","SideInset_R")): return "arm.r"
    if name.startswith(("Fist_L","FistBand_L","V3_FistKnuckle_L")): return "fist.l"
    if name.startswith(("Fist_R","FistBand_R","V3_FistKnuckle_R")): return "fist.r"
    return "body"

def main():
    a=parse_args(); bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path(a.input).resolve()))
    meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    if not meshes: raise RuntimeError("Rook rig input contains no meshes")
    for o in meshes:o.animation_data_clear()

    arm_data=bpy.data.armatures.new(f"{a.side}_rook_Skeleton")
    arm=bpy.data.objects.new(f"{a.side}_rook_Armature",arm_data)
    bpy.context.collection.objects.link(arm); arm.show_in_front=True
    bpy.context.view_layer.objects.active=arm; arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    add_bone(arm_data,"root",(0,0,.18),(0,0,.48))
    add_bone(arm_data,"body",(0,0,.48),(0,0,1.42),"root")
    add_bone(arm_data,"crown",(0,0,1.35),(0,0,1.88),"body")
    add_bone(arm_data,"arm.l",(-.30,0,1.25),(-.52,-.02,.82),"body")
    add_bone(arm_data,"arm.r",(.30,0,1.25),(.52,-.02,.82),"body")
    add_bone(arm_data,"fist.l",(-.50,-.04,.82),(-.55,-.10,.45),"arm.l")
    add_bone(arm_data,"fist.r",(.50,-.04,.82),(.55,-.10,.45),"arm.r")
    bpy.ops.object.mode_set(mode="OBJECT")

    for o in meshes:
        mw=o.matrix_world.copy(); o.parent=arm; o.parent_type="BONE"; o.parent_bone=bone_for(o.name); o.matrix_world=mw

    s=1 if a.side=="white" else -1
    make_action(arm,"Idle",48,[
        ("body",13,(0,0,.008),(0,0,1.0*s),(1,1,1)),("body",37,(0,0,-.006),(0,0,-1.0*s),(1,1,1)),
        ("fist.l",13,(0,0,.01),(0,0,2.0*s),(1,1,1)),("fist.r",37,(0,0,.01),(0,0,-2.0*s),(1,1,1)),
    ])
    make_action(arm,"Selected",20,[
        ("root",10,(0,0,.045),(0,0,-2*s),(1.035,1.035,1.035)),
        ("arm.l",10,(0,0,0),(0,0,7*s),(1,1,1)),("arm.r",10,(0,0,0),(0,0,-7*s),(1,1,1)),
        ("fist.l",10,(0,0,.02),(0,0,10*s),(1,1,1)),("fist.r",10,(0,0,.02),(0,0,-10*s),(1,1,1)),
    ])
    make_action(arm,"Move",30,[
        ("body",8,(0,-.02,.015),(-4,0,-2*s),(1.03,.96,1.03)),("body",20,(0,.015,0),(3,0,2*s),(.99,1.02,.99)),
        ("arm.l",8,(0,0,0),(0,0,8*s),(1,1,1)),("arm.r",20,(0,0,0),(0,0,-8*s),(1,1,1)),
        ("fist.l",8,(0,-.02,.02),(0,0,12*s),(1,1,1)),("fist.r",20,(0,-.02,.02),(0,0,-12*s),(1,1,1)),
    ])
    make_action(arm,"Hit",18,[
        ("body",6,(0,.03,-.02),(9,0,8*s),(1.08,.86,1.08)),
        ("crown",6,(0,0,0),(5,0,8*s),(1,1,1)),
        ("arm.l",6,(0,0,0),(0,0,16*s),(1,1,1)),("arm.r",6,(0,0,0),(0,0,-16*s),(1,1,1)),
    ])
    make_action(arm,"Victory",30,[
        ("body",12,(0,0,.06),(-5,0,-4*s),(1.05,1.05,1.05)),
        ("arm.l",12,(0,0,.03),(0,0,24*s),(1,1,1)),("arm.r",12,(0,0,.03),(0,0,-24*s),(1,1,1)),
        ("fist.l",12,(0,-.02,.05),(0,0,30*s),(1,1,1)),("fist.r",12,(0,-.02,.05),(0,0,-30*s),(1,1,1)),
    ])
    make_action(arm,"Defeat",30,[
        ("body",15,(0,0,-.09),(15,0,9*s),(1.07,.84,1.07)),
        ("crown",15,(0,0,-.02),(11,0,8*s),(1,1,1)),
        ("arm.l",15,(0,0,-.03),(0,0,-15*s),(1,1,1)),("arm.r",15,(0,0,-.03),(0,0,15*s),(1,1,1)),
    ])
    make_action(arm,"JumpCrush",42,[
        # Compress before launch.
        ("body",7,(0,0,-.06),(5,0,0),(1.16,.64,1.16)),
        ("arm.l",7,(0,0,0),(0,0,24*s),(1,1,1)),("arm.r",7,(0,0,0),(0,0,-24*s),(1,1,1)),
        ("fist.l",7,(0,0,-.02),(0,0,34*s),(1,1,1)),("fist.r",7,(0,0,-.02),(0,0,-34*s),(1,1,1)),
        # Stretch upward in the authored pose; world-space travel stays in BattleDirector.
        ("body",15,(0,0,.16),(-10,0,0),(.90,1.18,.90)),
        ("arm.l",15,(0,0,.04),(0,0,38*s),(1,1,1)),("arm.r",15,(0,0,.04),(0,0,-38*s),(1,1,1)),
        ("fist.l",15,(0,0,.08),(0,0,48*s),(1,1,1)),("fist.r",15,(0,0,.08),(0,0,-48*s),(1,1,1)),
        # Slam/contact.
        ("body",27,(0,0,-.09),(12,0,0),(1.18,.58,1.18)),
        ("crown",27,(0,0,-.02),(7,0,0),(1,1,1)),
        ("fist.l",27,(0,-.05,-.10),(0,0,-18*s),(1,1,1)),("fist.r",27,(0,-.05,-.10),(0,0,18*s),(1,1,1)),
        # Recover.
        ("body",35,(0,0,.03),(-3,0,0),(1.02,1.03,1.02)),
    ])

    bpy.ops.object.select_all(action="DESELECT"); arm.select_set(True)
    for o in meshes:o.select_set(True)
    bpy.context.view_layer.objects.active=arm
    out=Path(a.output).resolve(); out.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out),export_format="GLB",use_selection=True,
        export_cameras=False,export_lights=False,export_animations=True,export_nla_strips=True,export_apply=False)
    print("ROOK_RIG_EXPORT_PASS",a.side,out,"meshes=",len(meshes),"actions=",len(bpy.data.actions))

if __name__=="__main__": main()
