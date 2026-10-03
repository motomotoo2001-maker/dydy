#!/usr/bin/env python3
"""Rig/export unified production Pawn assets with full authored clip sets.

Both White and Black use the same animation contract:
Idle, Selected, Move, Hit, Victory, Defeat and ToeStab.
Named production mesh objects are rigid bone-parented so the existing visual
style is preserved while Godot receives Skeleton3D + AnimationPlayer clips.
"""
import argparse
import sys
from math import radians
from pathlib import Path
import bpy


def parse_args():
    argv=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    p=argparse.ArgumentParser()
    p.add_argument("--side",choices=("white","black"),required=True)
    p.add_argument("--output",required=True)
    p.add_argument("--save-blend")
    return p.parse_args(argv)


def add_bone(arm,name,head,tail,parent=None):
    b=arm.edit_bones.new(name); b.head=head; b.tail=tail
    if parent: b.parent=arm.edit_bones.get(parent)
    return b


def key(pb,frame,loc=(0,0,0),rot=(0,0,0),scale=(1,1,1)):
    pb.rotation_mode="XYZ"
    pb.location=loc
    pb.rotation_euler=tuple(radians(v) for v in rot)
    pb.scale=scale
    pb.keyframe_insert("location",frame=frame)
    pb.keyframe_insert("rotation_euler",frame=frame)
    pb.keyframe_insert("scale",frame=frame)


def reset_pose(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode="XYZ"
        pb.location=(0,0,0); pb.rotation_euler=(0,0,0); pb.scale=(1,1,1)


def make_action(arm,name,length,keys,bones):
    act=bpy.data.actions.new(name)
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action=act
    reset_pose(arm)
    for f in (1,length):
        for b in bones:
            if b in arm.pose.bones:
                key(arm.pose.bones[b],f)
    for bone,frame,loc,rot,scale in keys:
        if bone in arm.pose.bones:
            key(arm.pose.bones[bone],frame,loc,rot,scale)
    tr=arm.animation_data.nla_tracks.new(); tr.name=name
    st=tr.strips.new(name,1,act); st.action_frame_start=1; st.action_frame_end=length
    arm.animation_data.action=None


def main():
    args=parse_args(); side=args.side
    prefix="WP_" if side=="white" else "BP_"
    tag="white_pawn" if side=="white" else "black_pawn"
    center=-1.18 if side=="white" else 1.18
    src=[o for o in list(bpy.data.objects) if o.type=="MESH" and o.name.startswith(prefix)]
    if not src:
        raise RuntimeError(f"No {prefix} source meshes in opened .blend")

    def export_name(source_name):
        base=source_name[len(prefix):] if source_name.startswith(prefix) else source_name
        if base.startswith("Plume_"):
            return "Production_"+base
        mapping={
            "Helmet":"Helmet_Dome","HelmetCrest":"Helmet_Crest",
            "SpearShaft":"Spear_Shaft","SpearHead":"Spear_Head",
            "SpearNeck":"Spear_Neck","SpearPommel":"Spear_Pommel"
        } if side=="white" else {
            "WeaponShaft":"Knife_Grip","BladeCore":"Knife_Blade","BladeGuard":"Knife_Guard",
            "Cape":"Production_Cape","EarL":"Ear_L","EarR":"Ear_R"
        }
        return mapping.get(base,base)

    clones=[]
    for o in src:
        c=o.copy(); c.data=o.data.copy(); c.animation_data_clear()
        bpy.context.collection.objects.link(c)
        c["source_name"]=o.name
        c.name=export_name(o.name); c.data.name=c.name
        c.matrix_world=o.matrix_world.copy()
        c.matrix_world.translation.x-=center
        c.parent=None
        clones.append(c)

    for o in list(bpy.data.objects):
        if o not in clones:
            bpy.data.objects.remove(o,do_unlink=True)

    arm_data=bpy.data.armatures.new(f"{tag}_Skeleton")
    arm=bpy.data.objects.new(f"{tag}_Armature",arm_data)
    bpy.context.collection.objects.link(arm)
    arm.show_in_front=True
    bpy.context.view_layer.objects.active=arm; arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    add_bone(arm_data,"root",(0,0,.18),(0,0,.48))
    add_bone(arm_data,"pelvis",(0,0,.48),(0,0,1.05),"root")
    add_bone(arm_data,"spine",(0,0,1.05),(0,0,1.62),"pelvis")
    add_bone(arm_data,"neck",(0,0,1.62),(0,0,1.92),"spine")
    add_bone(arm_data,"head",(0,0,1.92),(0,0,2.62),"neck")
    add_bone(arm_data,"arm.L",(-.25,0,1.53),(-.62,-.03,1.08),"spine")
    add_bone(arm_data,"arm.R",(.25,0,1.53),(.62,-.03,1.08),"spine")
    add_bone(arm_data,"leg.L",(-.20,0,1.00),(-.23,0,.55),"pelvis")
    add_bone(arm_data,"foot.L",(-.23,0,.55),(-.23,-.18,.28),"leg.L")
    add_bone(arm_data,"leg.R",(.20,0,1.00),(.23,0,.55),"pelvis")
    add_bone(arm_data,"foot.R",(.23,0,.55),(.23,-.18,.28),"leg.R")
    add_bone(arm_data,"weapon.L",(-.73,-.08,.30),(-.73,-.08,2.95),"root")
    add_bone(arm_data,"shield.R",(.60,-.18,.85),(.60,-.18,1.60),"root")
    add_bone(arm_data,"plume",(0,0,2.72),(0,0,3.45),"head")
    if side=="black":
        add_bone(arm_data,"cape",(0,.24,1.60),(0,.30,.78),"spine")
    bpy.ops.object.mode_set(mode="OBJECT")

    def bone_for(obj):
        n=str(obj.get("source_name",obj.name))
        if any(k in n for k in ("Base0","Base1","Base2","Ring")): return "root"
        if any(k in n for k in ("Boot_L","Sole_L","BootTrim_L")): return "foot.L"
        if any(k in n for k in ("Boot_R","Sole_R","BootTrim_R")): return "foot.R"
        if any(k in n for k in ("Shin_L","Knee_L")): return "leg.L"
        if any(k in n for k in ("Shin_R","Knee_R")): return "leg.R"
        if any(k in n for k in ("PauldronL","ArmL","HandL")): return "arm.L"
        if any(k in n for k in ("PauldronR","ArmR","HandR")): return "arm.R"
        if any(k in n for k in ("Spear","Weapon","Blade")): return "weapon.L"
        if "Shield" in n: return "shield.R"
        if "Plume_" in n or "PlumeSocket" in n: return "plume"
        if side=="black" and "Cape" in n: return "cape"
        if any(k in n for k in ("Head","Ear","Hair","Eye","Iris","Pupil","Highlight","Nose","Cheek","Brow","Smile","Mouth","Tooth","Helmet","Rivet")): return "head"
        return "spine"

    for o in clones:
        mw=o.matrix_world.copy()
        o.parent=arm; o.parent_type="BONE"; o.parent_bone=bone_for(o)
        o.matrix_world=mw

    s=1 if side=="white" else -1
    bones=["root","pelvis","spine","head","arm.L","arm.R","leg.L","leg.R","foot.L","foot.R","weapon.L","shield.R","plume"]
    if side=="black": bones.append("cape")

    make_action(arm,"Idle",48,[
        ("pelvis",13,(0,.012,0),(0,0,-1.2*s),(1,1,1)),
        ("pelvis",37,(0,-.010,0),(0,0,1.0*s),(1,1,1)),
        ("spine",13,(0,0,0),(1.5,0,-1.5*s),(1,1,1)),
        ("head",13,(0,0,0),(-1.2,0,1.3*s),(1,1,1)),
        ("head",37,(0,0,0),(1.0,0,-1.0*s),(1,1,1)),
        ("plume",13,(0,0,0),(0,5,7*s),(1,1,1)),
        ("plume",37,(0,0,0),(0,-4,-6*s),(1,1,1)),
        *(([("cape",13,(0,.018,0),(-3,0,2*s),(1,1,1)),("cape",37,(0,-.012,0),(3,0,-2*s),(1,1,1))]) if side=="black" else [])
    ],bones)

    make_action(arm,"Selected",20,[
        ("root",10,(0,0,.055),(0,0,-2*s),(1.035,1.035,1.035)),
        ("spine",10,(0,0,0),(-4,0,-4*s),(1,1,1)),
        ("head",10,(0,0,0),(-5,0,4*s),(1,1,1)),
        ("weapon.L",10,(0,0,0),(-8,0,10*s),(1,1,1)),
        ("shield.R",10,(0,.03,0),(0,0,-8*s),(1,1,1)),
        ("plume",10,(0,0,0),(0,8,10*s),(1,1,1)),
    ],bones)

    make_action(arm,"Move",30,[
        ("pelvis",8,(0,-.03,.02),(7,0,-3*s),(1.02,.97,1.02)),
        ("pelvis",20,(0,.02,0),(-4,0,2*s),(.99,1.02,.99)),
        ("spine",8,(0,-.01,0),(8,0,-4*s),(1,1,1)),
        ("foot.L",8,(0,-.07,.04),(-12,0,0),(1,1,1)),
        ("foot.R",8,(0,.04,0),(7,0,0),(1,1,1)),
        ("foot.L",20,(0,.04,0),(7,0,0),(1,1,1)),
        ("foot.R",20,(0,-.07,.04),(-12,0,0),(1,1,1)),
        ("weapon.L",15,(0,0,0),(-12,0,5*s),(1,1,1)),
        ("plume",15,(0,0,0),(0,5,8*s),(1,1,1)),
    ],bones)

    make_action(arm,"Hit",18,[
        ("pelvis",6,(0,.03,-.02),(10,0,8*s),(1.06,.90,1.06)),
        ("spine",6,(0,.02,0),(14,0,10*s),(1,1,1)),
        ("head",6,(0,0,0),(10,0,8*s),(1,1,1)),
        ("weapon.L",6,(0,0,0),(18,0,18*s),(1,1,1)),
        ("shield.R",6,(0,.06,0),(0,0,14*s),(1,1,1)),
    ],bones)

    make_action(arm,"Victory",30,[
        ("root",12,(0,0,.06),(0,0,-4*s),(1.04,1.04,1.04)),
        ("spine",12,(0,0,0),(-8,0,-7*s),(1,1,1)),
        ("head",12,(0,0,0),(-8,0,-5*s),(1,1,1)),
        ("weapon.L",12,(0,.02,.03),(-24,0,-18*s),(1,1,1)),
        ("shield.R",12,(0,.04,.02),(0,0,-16*s),(1,1,1)),
        ("plume",12,(0,0,0),(0,10,14*s),(1,1,1)),
    ],bones)

    make_action(arm,"Defeat",30,[
        ("root",15,(0,0,-.08),(0,0,9*s),(1.03,.88,1.03)),
        ("pelvis",15,(0,0,-.05),(15,0,10*s),(1,1,1)),
        ("spine",15,(0,0,-.03),(18,0,12*s),(1,1,1)),
        ("head",15,(0,0,-.02),(14,0,10*s),(1,1,1)),
        ("weapon.L",15,(0,0,0),(30,0,28*s),(1,1,1)),
        ("shield.R",15,(0,-.02,0),(0,0,24*s),(1,1,1)),
        *(([("cape",15,(0,.07,0),(16,0,-10*s),(1,1,1))]) if side=="black" else [])
    ],bones)

    # Signature ToeStab: compact wind-up, jab/contact, recoil, flourish.
    make_action(arm,"ToeStab",36,[
        ("pelvis",7,(0,.07,0),(0,0,-4*s),(1,1,1)),
        ("spine",7,(0,0,0),(8,0,-10*s),(1,1,1)),
        ("head",7,(0,0,0),(-6,0,8*s),(1,1,1)),
        ("arm.L",7,(0,0,0),(10,0,18*s),(1,1,1)),
        ("weapon.L",7,(0,0,0),(-10,0,10*s),(1,1,1)),
        ("shield.R",7,(0,.05,0),(0,0,-10*s),(1,1,1)),
        ("plume",7,(0,0,0),(0,10,12*s),(1,1,1)),
        *(([("cape",7,(0,.03,0),(8,0,-6),(1,1,1))]) if side=="black" else []),

        ("root",14,(0,-.10,0),(0,0,0),(1,1,1)),
        ("pelvis",14,(0,-.10,.02),(12,0,0),(1,1,1)),
        ("spine",14,(0,-.06,0),(18,0,4*s),(1,1,1)),
        ("head",14,(0,-.03,0),(-10,0,-4*s),(1,1,1)),
        ("arm.L",14,(0,-.08,0),(-18,0,-8*s),(1,1,1)),
        ("weapon.L",14,(0,0,0),(52,0,0),(1,1,1)),
        ("arm.R",14,(0,.02,0),(6,0,10*s),(1,1,1)),
        ("shield.R",14,(0,.12,.02),(5,0,12*s),(1,1,1)),
        ("foot.L",14,(0,-.06,.02),(-8,0,0),(1,1,1)),
        ("foot.R",14,(0,.03,0),(4,0,0),(1,1,1)),
        ("plume",14,(0,0,0),(5,0,-6*s),(1,1,1)),
        *(([("cape",14,(0,.10,.02),(-16,0,10),(1,1,1))]) if side=="black" else []),

        ("root",18,(0,-.08,0),(0,0,0),(1,1,1)),
        ("pelvis",18,(0,-.06,.01),(8,0,0),(1,1,1)),
        ("spine",18,(0,-.03,0),(12,0,2*s),(1,1,1)),
        ("head",18,(0,0,0),(-5,0,2),(1,1,1)),
        ("weapon.L",18,(0,0,0),(38,0,0),(1,1,1)),
        ("shield.R",18,(0,.08,0),(3,0,8*s),(1,1,1)),
        ("plume",18,(0,0,0),(3,0,4*s),(1,1,1)),
        *(([("cape",18,(0,.06,0),(-10,0,6),(1,1,1))]) if side=="black" else []),

        ("root",24,(0,.04,0),(0,0,0),(1,1,1)),
        ("pelvis",24,(0,.04,0),(-5,0,2*s),(1,1,1)),
        ("spine",24,(0,.02,0),(-8,0,-4*s),(1,1,1)),
        ("head",24,(0,0,0),(5,0,5*s),(1,1,1)),
        ("weapon.L",24,(0,0,0),(-6,0,0),(1,1,1)),
        ("shield.R",24,(0,-.03,0),(-3,0,-5*s),(1,1,1)),
        ("plume",24,(0,0,0),(-4,0,6*s),(1,1,1)),
        *(([("cape",24,(0,-.02,0),(10,0,-5),(1,1,1))]) if side=="black" else [])
    ],bones)

    output=Path(args.output).resolve(); output.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT"); arm.select_set(True)
    for o in clones:o.select_set(True)
    bpy.context.view_layer.objects.active=arm
    arm.scale=(.585,.585,.585); bpy.context.view_layer.update()
    bpy.ops.export_scene.gltf(
        filepath=str(output),export_format="GLB",use_selection=True,
        export_cameras=False,export_lights=False,export_animations=True,
        export_nla_strips=True,export_apply=False
    )
    if args.save_blend:
        bpy.ops.wm.save_as_mainfile(filepath=str(Path(args.save_blend).resolve()))
    print("PAWN_RIG_EXPORT_PASS",side,output,"meshes=",len(clones),"actions=",len(bpy.data.actions))


if __name__=="__main__":
    main()
