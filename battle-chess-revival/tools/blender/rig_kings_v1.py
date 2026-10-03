#!/usr/bin/env python3
"""Rig production King GLBs and author gameplay/capture clips."""
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
    if parent:b.parent=arm.edit_bones.get(parent)
    return b

def key(pb,frame,loc=(0,0,0),rot=(0,0,0),scale=(1,1,1)):
    pb.rotation_mode="XYZ"; pb.location=loc; pb.rotation_euler=tuple(radians(v) for v in rot); pb.scale=scale
    pb.keyframe_insert("location",frame=frame); pb.keyframe_insert("rotation_euler",frame=frame); pb.keyframe_insert("scale",frame=frame)

def reset_pose(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode="XYZ"; pb.location=(0,0,0); pb.rotation_euler=(0,0,0); pb.scale=(1,1,1)

def make_action(arm,name,length,keys):
    act=bpy.data.actions.new(name)
    if arm.animation_data is None:arm.animation_data_create()
    arm.animation_data.action=act; reset_pose(arm)
    bones=["root","body","head","beard","arm.l","arm.r","scepter","coat"]
    for f in (1,length):
        for b in bones:
            if b in arm.pose.bones:key(arm.pose.bones[b],f)
    for bone,frame,loc,rot,scale in keys:
        if bone in arm.pose.bones:key(arm.pose.bones[bone],frame,loc,rot,scale)
    tr=arm.animation_data.nla_tracks.new(); tr.name=name
    st=tr.strips.new(name,1,act); st.action_frame_start=1; st.action_frame_end=length
    arm.animation_data.action=None

def bone_for(name):
    if name.startswith(("Pedestal","RobeTrim","WaistRing")):return "root"
    if name.startswith(("Head","Nose","Eye_","Brow_","Mouth","Crown")):return "head"
    if name.startswith(("Beard","Moustache","FurCollar")):return "beard"
    if name.startswith(("Arm_L","Shoulder_L","Hand_L","Cuff_L")):return "arm.l"
    if name.startswith(("Arm_R","Shoulder_R","Hand_R","Cuff_R")):return "arm.r"
    if name.startswith(("Scepter","ScepterRing","ScepterGem","ScepterCrown")):return "scepter"
    if name.startswith(("V3_CoatPanel","CoatPoint","CoatStripe","Cape")):return "coat"
    return "body"

def main():
    a=parse_args(); bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path(a.input).resolve()))
    meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    if not meshes:raise RuntimeError("King rig input contains no meshes")
    for o in meshes:o.animation_data_clear()

    arm_data=bpy.data.armatures.new(f"{a.side}_king_Skeleton")
    arm=bpy.data.objects.new(f"{a.side}_king_Armature",arm_data)
    bpy.context.collection.objects.link(arm); arm.show_in_front=True
    bpy.context.view_layer.objects.active=arm; arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    add_bone(arm_data,"root",(0,0,.18),(0,0,.48))
    add_bone(arm_data,"body",(0,0,.48),(0,0,1.50),"root")
    add_bone(arm_data,"head",(0,0,1.48),(0,0,2.03),"body")
    add_bone(arm_data,"beard",(0,-.08,1.66),(0,-.12,1.35),"head")
    add_bone(arm_data,"arm.l",(-.22,0,1.40),(-.42,-.04,.96),"body")
    add_bone(arm_data,"arm.r",(.22,0,1.40),(.42,-.04,.96),"body")
    add_bone(arm_data,"scepter",(.44,0,.45),(.44,0,2.22),"root")
    add_bone(arm_data,"coat",(0,.14,1.35),(0,.20,.65),"body")
    bpy.ops.object.mode_set(mode="OBJECT")
    for o in meshes:
        mw=o.matrix_world.copy(); o.parent=arm; o.parent_type="BONE"; o.parent_bone=bone_for(o.name); o.matrix_world=mw

    s=1 if a.side=="white" else -1
    make_action(arm,"Idle",48,[
        ("head",13,(0,0,0),(-1.2,0,1.0*s),(1,1,1)),("head",37,(0,0,0),(1,0,-1*s),(1,1,1)),
        ("beard",13,(0,.008,0),(-2,0,1*s),(1,1,1)),("beard",37,(0,-.006,0),(2,0,-1*s),(1,1,1)),
        ("scepter",13,(0,0,0),(0,0,1.7*s),(1,1,1)),("scepter",37,(0,0,0),(0,0,-1.3*s),(1,1,1)),
    ])
    make_action(arm,"Selected",20,[
        ("root",10,(0,0,.05),(0,0,-2*s),(1.035,1.035,1.035)),
        ("head",10,(0,0,0),(-4,0,3*s),(1,1,1)),("scepter",10,(0,0,0),(0,0,-8*s),(1,1,1)),
        ("arm.r",10,(0,0,0),(0,0,-7*s),(1,1,1)),
    ])
    make_action(arm,"Move",30,[
        ("body",8,(0,-.02,.015),(-5,0,-3*s),(1.02,.97,1.02)),("body",20,(0,.015,0),(4,0,2*s),(.99,1.02,.99)),
        ("coat",8,(0,.035,.02),(-8,0,4*s),(1,1,1)),("scepter",15,(0,0,0),(0,0,-10*s),(1,1,1)),
    ])
    make_action(arm,"Hit",18,[
        ("body",6,(0,.025,-.02),(10,0,9*s),(1.06,.90,1.06)),("head",6,(0,0,0),(8,0,8*s),(1,1,1)),
        ("beard",6,(0,.03,.01),(10,0,-6*s),(1,1,1)),("scepter",6,(0,0,0),(0,0,18*s),(1,1,1)),
        ("coat",6,(0,.045,.03),(12,0,-8*s),(1,1,1)),
    ])
    make_action(arm,"Victory",30,[
        ("body",12,(0,0,.05),(-6,0,-5*s),(1.03,1.04,1.03)),("head",12,(0,0,0),(-7,0,-4*s),(1,1,1)),
        ("scepter",12,(0,0,0),(0,0,-24*s),(1,1,1)),("arm.l",12,(0,0,.02),(0,0,14*s),(1,1,1)),
        ("coat",12,(0,.05,.03),(-10,0,5*s),(1,1,1)),
    ])
    make_action(arm,"Defeat",30,[
        ("body",15,(0,0,-.08),(17,0,10*s),(1.03,.88,1.03)),("head",15,(0,0,-.03),(14,0,8*s),(1,1,1)),
        ("beard",15,(0,.04,-.02),(14,0,-10*s),(1,1,1)),("scepter",15,(0,0,0),(0,0,30*s),(1,1,1)),
        ("coat",15,(0,.07,0),(16,0,-10*s),(1,1,1)),
    ])
    make_action(arm,"TrapdoorCommand",40,[
        # Reach for remote / command pose.
        ("body",8,(0,-.015,.01),(-4,0,-5*s),(1.01,.99,1.01)),
        ("arm.r",8,(0,-.03,.02),(0,0,-24*s),(1,1,1)),("scepter",8,(0,0,0),(0,0,-18*s),(1,1,1)),
        ("coat",8,(0,.035,.02),(-6,0,3*s),(1,1,1)),
        # CLICK pose.
        ("body",17,(0,.015,.02),(-8,0,8*s),(1.03,.97,1.03)),
        ("head",17,(0,0,0),(-5,0,10*s),(1,1,1)),("arm.r",17,(0,-.06,.04),(0,0,-38*s),(1,1,1)),
        ("scepter",17,(0,0,0),(0,0,-28*s),(1,1,1)),("beard",17,(0,.025,.01),(-6,0,5*s),(1,1,1)),
        ("coat",17,(0,.06,.04),(-12,0,6*s),(1,1,1)),
        # Smug recoil/recovery.
        ("body",28,(0,0,.025),(-3,0,-4*s),(1.01,1.02,1.01)),("head",28,(0,0,0),(-6,0,-6*s),(1,1,1)),
        ("scepter",28,(0,0,0),(0,0,9*s),(1,1,1)),
    ])

    bpy.ops.object.select_all(action="DESELECT"); arm.select_set(True)
    for o in meshes:o.select_set(True)
    bpy.context.view_layer.objects.active=arm
    out=Path(a.output).resolve(); out.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out),export_format="GLB",use_selection=True,
        export_cameras=False,export_lights=False,export_animations=True,export_nla_strips=True,export_apply=False)
    print("KING_RIG_EXPORT_PASS",a.side,out,"meshes=",len(meshes),"actions=",len(bpy.data.actions))

if __name__=="__main__":main()
