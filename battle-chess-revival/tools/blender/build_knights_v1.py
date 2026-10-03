#!/usr/bin/env python3
"""Build production-v1 White/Black Knight GLBs for Battle Chess Revival.

The models are deliberately authored as separate named mesh parts so the
existing PieceView transform animation layer can keep driving HorseHead,
Mane, RiderTorso, Plume and every Leg_* object before the Skeleton3D pass.
"""
import argparse
import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--white-output", required=True)
    p.add_argument("--black-output", required=True)
    return p.parse_args(argv)


def material(name, color, metallic=0.0, roughness=0.45):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1.0)
    bs.inputs["Metallic"].default_value = metallic
    bs.inputs["Roughness"].default_value = roughness
    return m


def finish(obj, mat=None, smooth=True):
    # Keep Blender object and mesh-data names identical. Trimesh contract
    # validation reads geometry names, while Godot animations read node names.
    if getattr(obj, "data", None) is not None:
        obj.data.name = obj.name
    if mat is not None:
        obj.data.materials.append(mat)
    if smooth and obj.type == "MESH":
        for p in obj.data.polygons:
            p.use_smooth = True
    return obj


def sphere(name, pos, scale, mat, segments=48, rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments, ring_count=rings, location=pos
    )
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, mat)


def rounded_box(name, pos, scale, mat, rot=(0, 0, 0), bevel=0.05):
    bpy.ops.mesh.primitive_cube_add(location=pos, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    mod = o.modifiers.new("SoftBevel", "BEVEL")
    mod.width = bevel
    mod.segments = 3
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o, mat)


def cyl(name, pos, radius, depth, mat, rot=(0, 0, 0), vertices=48):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=pos, rotation=rot
    )
    o = bpy.context.object
    o.name = name
    return finish(o, mat)


def cone(name, pos, r1, r2, depth, mat, rot=(0, 0, 0), vertices=48):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices, radius1=r1, radius2=r2, depth=depth,
        location=pos, rotation=rot
    )
    o = bpy.context.object
    o.name = name
    return finish(o, mat)


def torus(name, pos, major, minor, mat, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major, minor_radius=minor,
        major_segments=64, minor_segments=16,
        location=pos, rotation=rot
    )
    o = bpy.context.object
    o.name = name
    return finish(o, mat)


def tube(name, points, radius, mat, resolution=3):
    curve = bpy.data.curves.new(name + "_Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = resolution
    curve.bevel_depth = radius
    curve.bevel_resolution = 3
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for bp, co in zip(spline.bezier_points, points):
        bp.co = co
        bp.handle_left_type = "AUTO"
        bp.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.object
    obj.name = name
    obj.data.name = name
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def parent_all(root, objects):
    for o in objects:
        o.parent = root


def make_palette(side):
    if side == "white":
        return {
            "base": material("WK_Ivory", (0.80, 0.77, 0.68), 0.02, 0.40),
            "base_hi": material("WK_IvoryHi", (0.95, 0.92, 0.84), 0.00, 0.32),
            "cloth": material("WK_Blue", (0.10, 0.24, 0.40), 0.02, 0.50),
            "cloth_hi": material("WK_BlueHi", (0.18, 0.39, 0.60), 0.02, 0.38),
            "metal": material("WK_Gold", (0.66, 0.42, 0.12), 0.78, 0.24),
            "steel": material("WK_Steel", (0.42, 0.47, 0.52), 0.82, 0.22),
            "leather": material("WK_Leather", (0.20, 0.11, 0.07), 0.02, 0.66),
            "skin": material("WK_Skin", (0.72, 0.46, 0.30), 0.00, 0.58),
            "mane": material("WK_Mane", (0.15, 0.12, 0.10), 0.00, 0.66),
            "eye": material("WK_Eye", (0.08, 0.14, 0.18), 0.15, 0.20),
            "dark": material("WK_Dark", (0.06, 0.055, 0.06), 0.12, 0.46),
            "accent": material("WK_Plume", (0.08, 0.30, 0.48), 0.02, 0.42),
        }
    return {
        "base": material("BK_Charcoal", (0.08, 0.07, 0.085), 0.18, 0.38),
        "base_hi": material("BK_Armor", (0.19, 0.18, 0.21), 0.68, 0.28),
        "cloth": material("BK_Crimson", (0.34, 0.035, 0.045), 0.02, 0.48),
        "cloth_hi": material("BK_Violet", (0.22, 0.075, 0.29), 0.05, 0.44),
        "metal": material("BK_Bronze", (0.38, 0.20, 0.075), 0.72, 0.28),
        "steel": material("BK_Steel", (0.30, 0.32, 0.36), 0.80, 0.20),
        "leather": material("BK_Leather", (0.10, 0.055, 0.04), 0.02, 0.70),
        "skin": material("BK_Skin", (0.34, 0.18, 0.16), 0.00, 0.58),
        "mane": material("BK_Mane", (0.025, 0.02, 0.028), 0.02, 0.70),
        "eye": material("BK_EyeGlow", (0.68, 0.08, 0.035), 0.08, 0.18),
        "dark": material("BK_Dark", (0.018, 0.016, 0.020), 0.18, 0.42),
        "accent": material("BK_Plume", (0.56, 0.045, 0.06), 0.04, 0.40),
    }


def pedestal(P, prefix, objects):
    objects.append(cyl("PedestalLower", (0, 0, 0.07), 0.48, 0.14, P["dark"], vertices=64))
    objects.append(torus("PedestalTrim", (0, 0, 0.13), 0.41, 0.035, P["metal"]))
    objects.append(cyl("PedestalUpper", (0, 0, 0.19), 0.40, 0.13, P["base"], vertices=64))
    objects.append(torus("PedestalUpperTrim", (0, 0, 0.255), 0.37, 0.024, P["metal"]))


def horse_leg(name, x, y, P, objects, rear=False):
    lean = math.radians(-8 if rear else 6)
    objects.append(sphere(
        name, (x, y, 0.66), (0.105, 0.11, 0.28), P["base"], 40, 20
    ))
    objects[-1].rotation_euler.x = lean
    objects.append(sphere(
        name + "_Knee", (x, y - (0.025 if rear else 0.04), 0.47),
        (0.12, 0.13, 0.12), P["base_hi"], 36, 18
    ))
    objects.append(sphere(
        name + "_Lower", (x, y - (0.045 if rear else 0.075), 0.37),
        (0.085, 0.09, 0.18), P["base"], 36, 18
    ))
    objects.append(rounded_box(
        name + "_Hoof", (x, y - (0.10 if rear else 0.13), 0.285),
        (0.13, 0.17, 0.07), P["dark"], bevel=0.035
    ))


def build_knight(side, output):
    P = make_palette(side)
    objects = []
    root = bpy.data.objects.new(
        "WhiteKnightProductionV1" if side == "white" else "BlackKnightProductionV1",
        None
    )
    bpy.context.collection.objects.link(root)

    pedestal(P, "WK" if side == "white" else "BK", objects)

    # Horse: broad readable chest, compact chess-square footprint.
    objects.append(sphere("HorseBody", (0, 0.04, 0.91), (0.39, 0.57, 0.35), P["base"], 56, 28))
    objects.append(sphere("HorseChest", (0, -0.30, 0.98), (0.33, 0.35, 0.40), P["base_hi"], 48, 24))
    objects.append(sphere("HorseRump", (0, 0.37, 0.91), (0.36, 0.35, 0.34), P["base"], 48, 24))
    objects.append(tube("HorseNeck", [(0,-0.28,1.02),(0,-0.45,1.25),(0,-0.53,1.47)], 0.20, P["base_hi"]))
    objects.append(sphere("HorseHead", (0, -0.61, 1.54), (0.24, 0.34, 0.25), P["base_hi"], 48, 24))
    objects.append(sphere("Muzzle", (0, -0.88, 1.48), (0.20, 0.25, 0.15), P["base"], 44, 22))
    objects.append(sphere("Nostril_L", (-0.075, -1.085, 1.50), (0.026, 0.020, 0.020), P["dark"], 24, 12))
    objects.append(sphere("Nostril_R", (0.075, -1.085, 1.50), (0.026, 0.020, 0.020), P["dark"], 24, 12))
    objects.append(sphere("HorseEye_L", (-0.16, -0.74, 1.62), (0.036, 0.026, 0.036), P["eye"], 28, 14))
    objects.append(sphere("HorseEye_R", (0.16, -0.74, 1.62), (0.036, 0.026, 0.036), P["eye"], 28, 14))
    objects.append(cone("Ear_L", (-0.13,-0.62,1.82), 0.075, 0.015, 0.28, P["base_hi"], rot=(math.radians(-8),0,math.radians(-8)), vertices=32))
    objects.append(cone("Ear_R", (0.13,-0.62,1.82), 0.075, 0.015, 0.28, P["base_hi"], rot=(math.radians(-8),0,math.radians(8)), vertices=32))

    # Mane is one named animated part plus layered strands for detail.
    objects.append(sphere("Mane", (0, -0.32, 1.43), (0.23, 0.15, 0.44), P["mane"], 44, 22))
    for i in range(6):
        z = 1.18 + i * 0.105
        objects.append(cone(
            f"ManeDetail_{i}", (0, -0.18 + i*0.012, z), 0.105, 0.015, 0.24,
            P["mane"], rot=(math.radians(90),0,0), vertices=24
        ))
    objects.append(tube("Tail", [(0,0.60,1.02),(0,0.82,0.82),(0.10,0.92,0.55)], 0.075, P["mane"]))

    horse_leg("Leg_FL", -0.24, -0.28, P, objects, False)
    horse_leg("Leg_FR",  0.24, -0.28, P, objects, False)
    horse_leg("Leg_RL", -0.24,  0.30, P, objects, True)
    horse_leg("Leg_RR",  0.24,  0.30, P, objects, True)

    # Tack / horse armor.
    objects.append(rounded_box("SaddleBlanket", (0,0.10,1.20), (0.36,0.40,0.055), P["cloth"], bevel=0.04))
    objects.append(torus("SaddleTrimFront", (0,-0.22,1.19), 0.31, 0.024, P["metal"], rot=(math.radians(90),0,0)))
    objects.append(rounded_box("ChestBarding", (0,-0.49,1.05), (0.30,0.045,0.26), P["cloth_hi"], bevel=0.045))
    objects.append(rounded_box("ChestEmblemV", (0,-0.545,1.05), (0.035,0.018,0.16), P["metal"], bevel=0.012))
    objects.append(rounded_box("ChestEmblemH", (0,-0.547,1.08), (0.13,0.018,0.035), P["metal"], bevel=0.012))

    # Rider.
    objects.append(sphere("RiderTorso", (0, 0.06, 1.55), (0.24, 0.18, 0.30), P["base_hi"], 48, 24))
    objects.append(rounded_box("RiderChestPlate", (0,-0.14,1.57), (0.23,0.045,0.22), P["steel"], bevel=0.045))
    objects.append(rounded_box("RiderBelt", (0,0.03,1.36), (0.25,0.20,0.045), P["leather"], bevel=0.025))
    objects.append(sphere("RiderHead", (0,-0.015,1.89), (0.155,0.145,0.17), P["skin"], 44, 22))
    objects.append(sphere("RiderNose", (0,-0.155,1.88), (0.040,0.034,0.048), P["skin"], 28, 14))
    objects.append(sphere("RiderEye_L", (-0.052,-0.155,1.93), (0.022,0.016,0.020), P["eye"], 24, 12))
    objects.append(sphere("RiderEye_R", (0.052,-0.155,1.93), (0.022,0.016,0.020), P["eye"], 24, 12))

    # Helmet / shoulders.
    objects.append(sphere("Helmet", (0,0.00,2.00), (0.20,0.18,0.17), P["steel"], 48, 24))
    objects.append(torus("HelmetRim", (0,-0.005,1.96), 0.18, 0.022, P["metal"]))
    objects.append(rounded_box("NoseGuard", (0,-0.186,1.91), (0.020,0.018,0.11), P["metal"], bevel=0.008))
    for side_sign, label in [(-1,"L"),(1,"R")]:
        objects.append(sphere(f"Pauldron_{label}", (0.26*side_sign,0.02,1.63), (0.14,0.15,0.12), P["steel"], 36, 18))
        objects.append(sphere(f"Arm_{label}", (0.30*side_sign,-0.02,1.48), (0.075,0.075,0.20), P["base_hi"], 36, 18))
        objects[-1].rotation_euler.y = math.radians(12*side_sign)
        objects.append(sphere(f"Gauntlet_{label}", (0.34*side_sign,-0.08,1.34), (0.085,0.075,0.085), P["steel"], 32, 16))

    # Plume: one animated root-like mesh plus detail feathers.
    objects.append(sphere("Plume", (0,0.02,2.19), (0.075,0.07,0.22), P["accent"], 36, 18))
    for i, x in enumerate((-0.09,-0.045,0.045,0.09)):
        objects.append(cone(
            f"Production_Plume_{i}", (x,0.02,2.25 + 0.025*(1-abs(x)/0.09)),
            0.045, 0.006, 0.30, P["accent"], rot=(0,math.radians(8*x/0.09),0), vertices=24
        ))

    # Shield and compact lance keep neighboring board pieces readable.
    shield_mat = P["cloth"] if side == "white" else P["cloth_hi"]
    objects.append(cyl("KnightShield", (-0.36,-0.18,1.48), 0.24, 0.065, shield_mat, rot=(math.radians(90),0,0), vertices=64))
    objects.append(torus("KnightShieldRim", (-0.36,-0.216,1.48), 0.22, 0.025, P["metal"], rot=(math.radians(90),0,0)))
    objects.append(rounded_box("ShieldMarkV", (-0.36,-0.255,1.48), (0.025,0.018,0.13), P["metal"], bevel=0.01))
    objects.append(rounded_box("ShieldMarkH", (-0.36,-0.257,1.50), (0.11,0.018,0.025), P["metal"], bevel=0.01))
    objects.append(cyl("LanceShaft", (0.38,-0.03,1.56), 0.025, 1.18, P["leather"], rot=(0,math.radians(-9),0), vertices=32))
    objects.append(cone("LanceTip", (0.38,-0.22,2.16), 0.085, 0.0, 0.26, P["steel"], rot=(0,math.radians(-9),0), vertices=32))

    if side == "black":
        # Menacing silhouette cues without increasing the board footprint.
        objects.append(cone("HelmetHorn_L", (-0.14,0.01,2.10), 0.055, 0.008, 0.26, P["metal"], rot=(0,math.radians(-24),math.radians(-18)), vertices=28))
        objects.append(cone("HelmetHorn_R", (0.14,0.01,2.10), 0.055, 0.008, 0.26, P["metal"], rot=(0,math.radians(24),math.radians(18)), vertices=28))
        objects.append(rounded_box("Cape", (0,0.20,1.52), (0.25,0.045,0.30), P["cloth"], rot=(math.radians(-8),0,0), bevel=0.035))
        for i, x in enumerate((-0.24,0.0,0.24)):
            objects.append(cone(f"BardingSpike_{i}", (x,-0.48,1.24), 0.040, 0.004, 0.20, P["steel"], rot=(math.radians(90),0,0), vertices=24))

    parent_all(root, objects)

    # Export just this character while preserving node names for PieceView.
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root

    out = Path(output).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(out),
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_cameras=False,
        export_lights=False,
        export_apply=True,
    )
    print("KNIGHT_PRODUCTION_EXPORT_PASS", side, out, "parts=", len(objects))

    for o in list(objects):
        if o.name in bpy.data.objects:
            bpy.data.objects.remove(o, do_unlink=True)
    if root.name in bpy.data.objects:
        bpy.data.objects.remove(root, do_unlink=True)


def main():
    args = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    build_knight("white", args.white_output)
    build_knight("black", args.black_output)
    print("KNIGHT_PRODUCTION_BUILD_PASS")


if __name__ == "__main__":
    main()
