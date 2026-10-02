#!/usr/bin/env python3
"""Rig/export the Blender-authored production-v2 pawn asset."""
import argparse
import bpy
from math import radians
from pathlib import Path

def parse_args():
    import sys
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--side", choices=("white", "black"), required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--save-blend")
    return p.parse_args(argv)

def add_bone(arm, name, head, tail, parent=None):
    b = arm.edit_bones.new(name); b.head=head; b.tail=tail
    if parent: b.parent=arm.edit_bones.get(parent)
    return b

def main():
    args=parse_args(); side=args.side
    prefix="WP_" if side=="white" else "BP_"
    tag="white_pawn" if side=="white" else "black_pawn"
    center=-1.18 if side=="white" else 1.18
    src=[o for o in list(bpy.data.objects) if o.type=="MESH" and o.name.startswith(prefix)]
    if not src: raise RuntimeError(f"No {prefix} source meshes in opened .blend")
    def export_name(source_name):
        base=source_name[len(prefix):] if source_name.startswith(prefix) else source_name
        if base.startswith("Plume_"): return "Production_"+base
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
        c=o.copy(); c.data=o.data.copy(); c.animation_data_clear(); bpy.context.collection.objects.link(c)
        c["source_name"]=o.name; c.name=export_name(o.name); c.data.name=c.name
        c.matrix_world=o.matrix_world.copy(); c.matrix_world.translation.x-=center; c.parent=None; clones.append(c)
    for o in list(bpy.data.objects):
        if o not in clones: bpy.data.objects.remove(o,do_unlink=True)
    arm_data=bpy.data.armatures.new(f"{tag}_Skeleton")
    arm_obj=bpy.data.objects.new(f"{tag}_Armature",arm_data); bpy.context.collection.objects.link(arm_obj)
    arm_obj.show_in_front=True; bpy.context.view_layer.objects.active=arm_obj; arm_obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    add_bone(arm_data,"root",(0,0,0.18),(0,0,0.48))
    add_bone(arm_data,"pelvis",(0,0,0.48),(0,0,1.05),"root")
    add_bone(arm_data,"spine",(0,0,1.05),(0,0,1.62),"pelvis")
    add_bone(arm_data,"neck",(0,0,1.62),(0,0,1.92),"spine")
    add_bone(arm_data,"head",(0,0,1.92),(0,0,2.62),"neck")
    add_bone(arm_data,"arm.L",(-0.25,0,1.53),(-0.62,-0.03,1.08),"spine")
    add_bone(arm_data,"arm.R",(0.25,0,1.53),(0.62,-0.03,1.08),"spine")
    add_bone(arm_data,"leg.L",(-0.20,0,1.00),(-0.23,0,0.55),"pelvis")
    add_bone(arm_data,"foot.L",(-0.23,0,0.55),(-0.23,-0.18,0.28),"leg.L")
    add_bone(arm_data,"leg.R",(0.20,0,1.00),(0.23,0,0.55),"pelvis")
    add_bone(arm_data,"foot.R",(0.23,0,0.55),(0.23,-0.18,0.28),"leg.R")
    add_bone(arm_data,"weapon.L",(-0.73,-0.08,0.30),(-0.73,-0.08,2.95),"root")
    add_bone(arm_data,"shield.R",(0.60,-0.18,0.85),(0.60,-0.18,1.60),"root")
    add_bone(arm_data,"plume",(0,0,2.72),(0,0,3.45),"head")
    if side=="black": add_bone(arm_data,"cape",(0,0.24,1.60),(0,0.30,0.78),"spine")
    bpy.ops.object.mode_set(mode="POSE")
    for pb in arm_obj.pose.bones: pb.rotation_mode="XYZ"
    bpy.ops.object.mode_set(mode="OBJECT"); arm_obj.select_set(False)
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
        mw=o.matrix_world.copy(); o.parent=arm_obj; o.parent_type="BONE"; o.parent_bone=bone_for(o); o.matrix_world=mw
    scene=bpy.context.scene; scene.frame_start=1; scene.frame_end=36
    def key(bone,frame,loc=(0,0,0),rot=(0,0,0),scale=(1,1,1)):
        pb=arm_obj.pose.bones[bone]; pb.location=loc; pb.rotation_euler=tuple(radians(v) for v in rot); pb.scale=scale
        pb.keyframe_insert("location",frame=frame); pb.keyframe_insert("rotation_euler",frame=frame); pb.keyframe_insert("scale",frame=frame)
    frames=(1,7,14,18,24,36)
    animated=["root","pelvis","spine","head","arm.L","arm.R","weapon.L","shield.R","foot.L","foot.R","plume"]
    if side=="black": animated.append("cape")
    for f in frames:
        for b in animated: key(b,f)
    sign=1 if side=="white" else -1
    key("pelvis",7,(0,0.07,0),(0,0,-4*sign)); key("spine",7,(0,0,0),(8,0,-10*sign)); key("head",7,(0,0,0),(-6,0,8*sign))
    key("arm.L",7,(0,0,0),(10,0,18*sign)); key("weapon.L",7,(0,0,0),(-10,0,10*sign)); key("shield.R",7,(0,0.05,0),(0,0,-10*sign)); key("plume",7,(0,0,0),(0,10,12*sign))
    if side=="black": key("cape",7,(0,0.03,0),(8,0,-6))
    key("root",14,(0,-0.10,0)); key("pelvis",14,(0,-0.10,0.02),(12,0,0)); key("spine",14,(0,-0.06,0),(18,0,4*sign)); key("head",14,(0,-0.03,0),(-10,0,-4*sign))
    key("arm.L",14,(0,-0.08,0),(-18,0,-8*sign)); key("weapon.L",14,(0,0,0),(52,0,0)); key("arm.R",14,(0,0.02,0),(6,0,10*sign)); key("shield.R",14,(0,0.12,0.02),(5,0,12*sign))
    key("foot.L",14,(0,-0.06,0.02),(-8,0,0)); key("foot.R",14,(0,0.03,0),(4,0,0)); key("plume",14,(0,0,0),(5,0,-6*sign))
    if side=="black": key("cape",14,(0,0.10,0.02),(-16,0,10))
    key("root",18,(0,-0.08,0)); key("pelvis",18,(0,-0.06,0.01),(8,0,0)); key("spine",18,(0,-0.03,0),(12,0,2*sign)); key("head",18,(0,0,0),(-5,0,2))
    key("weapon.L",18,(0,0,0),(38,0,0)); key("shield.R",18,(0,0.08,0),(3,0,8*sign)); key("plume",18,(0,0,0),(3,0,4*sign))
    if side=="black": key("cape",18,(0,0.06,0),(-10,0,6))
    key("root",24,(0,0.04,0)); key("pelvis",24,(0,0.04,0),(-5,0,2*sign)); key("spine",24,(0,0.02,0),(-8,0,-4*sign)); key("head",24,(0,0,0),(5,0,5*sign))
    key("weapon.L",24,(0,0,0),(-6,0,0)); key("shield.R",24,(0,-0.03,0),(-3,0,-5*sign)); key("plume",24,(0,0,0),(-4,0,6*sign))
    if side=="black": key("cape",24,(0,-0.02,0),(10,0,-5))
    if arm_obj.animation_data and arm_obj.animation_data.action: arm_obj.animation_data.action.name="ToeStab"
    output=Path(args.output).resolve(); output.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT"); arm_obj.select_set(True)
    for o in clones: o.select_set(True)
    bpy.context.view_layer.objects.active=arm_obj
    arm_obj.scale=(0.585,0.585,0.585); bpy.context.view_layer.update()
    bpy.ops.export_scene.gltf(filepath=str(output),export_format="GLB",use_selection=True,export_cameras=False,export_lights=False,export_animations=True,export_apply=False)
    if args.save_blend: bpy.ops.wm.save_as_mainfile(filepath=str(Path(args.save_blend).resolve()))
    print("PAWN_RIG_EXPORT_PASS",side,output)

if __name__=="__main__":
    main()
