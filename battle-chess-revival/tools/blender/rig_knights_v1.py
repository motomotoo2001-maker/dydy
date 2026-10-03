#!/usr/bin/env python3
"""Convert a production Knight GLB into a bone-parented rigged GLB with authored clips.

This C1 pass deliberately preserves named mesh objects while adding an Armature.
The current PieceView named-part system remains compatible until gameplay switches
to AnimationPlayer-driven clips.
"""
import argparse, math, sys
from pathlib import Path
import bpy
from math import radians


def parse_args():
    argv=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    p=argparse.ArgumentParser()
    p.add_argument("--input",required=True)
    p.add_argument("--output",required=True)
    p.add_argument("--side",choices=("white","black"),required=True)
    return p.parse_args(argv)


def add_bone(arm,name,head,tail,parent=None):
    b=arm.edit_bones.new(name); b.head=head; b.tail=tail
    if parent: b.parent=arm.edit_bones.get(parent)
    return b


def reset_pose(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode="XYZ"
        pb.location=(0,0,0)
        pb.rotation_euler=(0,0,0)
        pb.scale=(1,1,1)


def key(pb,frame,loc=(0,0,0),rot=(0,0,0),scale=(1,1,1)):
    pb.location=loc
    pb.rotation_euler=tuple(radians(v) for v in rot)
    pb.scale=scale
    pb.keyframe_insert("location",frame=frame)
    pb.keyframe_insert("rotation_euler",frame=frame)
    pb.keyframe_insert("scale",frame=frame)


def make_action(arm,name,length,keys):
    act=bpy.data.actions.new(name)
    if arm.animation_data is None: arm.animation_data_create()
    arm.animation_data.action=act
    reset_pose(arm)
    # Establish stable zero keys on every controlled bone.
    controlled=["root","horse_body","horse_head","rider_root","rider_head",
                "leg.fl","leg.fr","leg.rl","leg.rr","plume","shield","lance","cape"]
    for f in (1,length):
        for b in controlled:
            if b in arm.pose.bones:key(arm.pose.bones[b],f)
    for bone,frame,loc,rot,scale in keys:
        if bone in arm.pose.bones:key(arm.pose.bones[bone],frame,loc,rot,scale)
    # Stash in NLA so glTF exporter includes every action.
    tr=arm.animation_data.nla_tracks.new(); tr.name=name
    st=tr.strips.new(name,1,act); st.action_frame_start=1; st.action_frame_end=length
    arm.animation_data.action=None
    return act


def bone_for(name):
    if name.startswith(("Pedestal","Saddle","ChestBarding","ChestEmblem")): return "root"
    if name.startswith(("HorseBody","HorseChest","HorseRump","HorseNeck","Tail","ManeDetail")): return "horse_body"
    if name.startswith(("HorseHead","Muzzle","Nostril","HorseEye","Ear_","Mane")): return "horse_head"
    if name.startswith(("Leg_FL",)): return "leg.fl"
    if name.startswith(("Leg_FR",)): return "leg.fr"
    if name.startswith(("Leg_RL",)): return "leg.rl"
    if name.startswith(("Leg_RR",)): return "leg.rr"
    if name.startswith(("RiderTorso","RiderChestPlate","RiderBelt","Pauldron_","Arm_","Gauntlet_")): return "rider_root"
    if name.startswith(("RiderHead","RiderNose","RiderEye","Helmet","NoseGuard","HelmetRim","HelmetHorn")): return "rider_head"
    if name.startswith(("Plume","Production_Plume")): return "plume"
    if name.startswith(("KnightShield","KnightShieldRim","ShieldMark")): return "shield"
    if name.startswith(("LanceShaft","LanceTip")): return "lance"
    if name.startswith(("Cape","BardingSpike")): return "cape"
    return "root"


def main():
    a=parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path(a.input).resolve()))
    meshes=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    if not meshes: raise RuntimeError("Knight rig input contains no mesh objects")

    # Clear imported animation if any; production Knight V1 is static.
    for o in meshes:o.animation_data_clear()

    arm_data=bpy.data.armatures.new(f"{a.side}_knight_Skeleton")
    arm=bpy.data.objects.new(f"{a.side}_knight_Armature",arm_data)
    bpy.context.collection.objects.link(arm)
    arm.show_in_front=True
    bpy.context.view_layer.objects.active=arm; arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    add_bone(arm_data,"root",(0,0,.18),(0,0,.55))
    add_bone(arm_data,"horse_body",(0,0,.55),(0,0,1.25),"root")
    add_bone(arm_data,"horse_head",(0,-.30,1.20),(0,-.72,1.70),"horse_body")
    add_bone(arm_data,"rider_root",(0,0,1.18),(0,0,1.88),"horse_body")
    add_bone(arm_data,"rider_head",(0,0,1.78),(0,0,2.18),"rider_root")
    add_bone(arm_data,"leg.fl",(-.24,-.28,.72),(-.24,-.36,.28),"horse_body")
    add_bone(arm_data,"leg.fr",(.24,-.28,.72),(.24,-.36,.28),"horse_body")
    add_bone(arm_data,"leg.rl",(-.24,.30,.72),(-.24,.24,.28),"horse_body")
    add_bone(arm_data,"leg.rr",(.24,.30,.72),(.24,.24,.28),"horse_body")
    add_bone(arm_data,"plume",(0,0,2.02),(0,0,2.48),"rider_head")
    add_bone(arm_data,"shield",(-.34,-.12,1.30),(-.34,-.12,1.70),"rider_root")
    add_bone(arm_data,"lance",(.36,-.05,1.05),(.36,-.12,2.25),"rider_root")
    add_bone(arm_data,"cape",(0,.15,1.60),(0,.25,1.10),"rider_root")
    bpy.ops.object.mode_set(mode="OBJECT")

    # Bone-parent rigid mesh groups while preserving world transforms.
    for o in meshes:
        mw=o.matrix_world.copy()
        o.parent=arm; o.parent_type="BONE"; o.parent_bone=bone_for(o.name)
        o.matrix_world=mw

    s=1 if a.side=="white" else -1
    # Authored clips.
    make_action(arm,"Idle",48,[
        ("horse_head",13,(0,0,0),(-3,0,1.5*s),(1,1,1)),
        ("horse_head",25,(0,0,0),(2,0,-1*s),(1,1,1)),
        ("rider_root",13,(0,0.015,0),(1.5,0,-1*s),(1,1,1)),
        ("rider_root",37,(0,-0.01,0),(-1,0,1*s),(1,1,1)),
        ("plume",13,(0,0,0),(0,4,6*s),(1,1,1)),
        ("plume",37,(0,0,0),(0,-3,-5*s),(1,1,1)),
    ])
    make_action(arm,"Selected",20,[
        ("root",10,(0,0,.055),(0,0,-2*s),(1.035,1.035,1.035)),
        ("horse_head",10,(0,0,0),(-6,0,2*s),(1,1,1)),
        ("rider_root",10,(0,0,0),(3,0,-3*s),(1,1,1)),
    ])
    make_action(arm,"Move",30,[
        ("horse_body",8,(0,-.025,.03),(-4,0,0),(1.02,.97,1.02)),
        ("leg.fl",8,(0,-.04,.03),(18,0,0),(1,1,1)),
        ("leg.rr",8,(0,.03,.02),(-15,0,0),(1,1,1)),
        ("leg.fr",20,(0,-.04,.03),(18,0,0),(1,1,1)),
        ("leg.rl",20,(0,.03,.02),(-15,0,0),(1,1,1)),
        ("horse_head",15,(0,-.02,0),(-7,0,0),(1,1,1)),
    ])
    make_action(arm,"Hit",18,[
        ("horse_body",6,(0,.03,-.02),(10,0,8*s),(1.06,.90,1.06)),
        ("rider_root",6,(0,.02,0),(-12,0,-10*s),(1,1,1)),
        ("rider_head",6,(0,0,0),(8,0,8*s),(1,1,1)),
    ])
    make_action(arm,"Victory",30,[
        ("horse_head",12,(0,.02,.04),(-14,0,0),(1,1,1)),
        ("rider_root",12,(0,0,.05),(-6,0,-8*s),(1,1,1)),
        ("lance",12,(0,0,0),(0,0,-18*s),(1,1,1)),
        ("plume",12,(0,0,0),(0,7,12*s),(1,1,1)),
    ])
    make_action(arm,"Defeat",30,[
        ("horse_head",15,(0,-.04,-.05),(16,0,5*s),(1,1,1)),
        ("rider_root",15,(0,0,-.08),(16,0,10*s),(.96,.90,.96)),
        ("rider_head",15,(0,0,0),(12,0,8*s),(1,1,1)),
        ("lance",15,(0,0,0),(0,0,28*s),(1,1,1)),
    ])
    make_action(arm,"DoubleKick",36,[
        ("horse_body",8,(0,-.04,.02),(-9,0,0),(1.02,.96,1.02)),
        ("rider_root",8,(0,.02,0),(10,0,0),(1,1,1)),
        ("leg.rl",14,(0,.10,.06),(-62,0,0),(1,1,1)),
        ("leg.rr",14,(0,.10,.06),(-62,0,0),(1,1,1)),
        ("horse_body",14,(0,-.08,.05),(-15,0,0),(1.04,.93,1.04)),
        ("rider_root",14,(0,.03,0),(14,0,0),(1,1,1)),
        ("leg.rl",21,(0,-.12,.02),(48,0,0),(1,1,1)),
        ("leg.rr",21,(0,-.12,.02),(48,0,0),(1,1,1)),
        ("horse_body",21,(0,.04,0),(7,0,0),(.98,1.04,.98)),
        ("plume",21,(0,0,0),(0,7,16*s),(1,1,1)),
    ])

    # Export armature + all meshes and all NLA tracks.
    bpy.ops.object.select_all(action="DESELECT");arm.select_set(True)
    for o in meshes:o.select_set(True)
    bpy.context.view_layer.objects.active=arm
    out=Path(a.output).resolve();out.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(out),export_format="GLB",use_selection=True,
        export_cameras=False,export_lights=False,export_animations=True,
        export_nla_strips=True,export_apply=False
    )
    print("KNIGHT_RIG_EXPORT_PASS",a.side,out,"meshes=",len(meshes),"actions=",len(bpy.data.actions))


if __name__=="__main__":main()
