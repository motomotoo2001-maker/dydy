#!/usr/bin/env python3
"""Build production-v1 White/Black Bishop GLBs for Battle Chess Revival.

The Bishop pair is authored as layered named parts rather than a single baked
mesh. Existing gameplay/capture animation can therefore keep driving Head,
Trunk, V3_TrunkTip, Staff and V3_CapeLayer until the later Skeleton3D pass.
"""
import argparse
import math
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
    if getattr(obj, "data", None) is not None:
        obj.data.name = obj.name
    if mat is not None:
        obj.data.materials.append(mat)
    if smooth and obj.type == "MESH":
        for p in obj.data.polygons:
            p.use_smooth = True
    return obj


def sphere(name, pos, scale, mat, segments=48, rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=pos)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(o, mat)


def rounded_box(name, pos, scale, mat, rot=(0, 0, 0), bevel=0.04):
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
    curve.bevel_resolution = 4
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


def palette(side):
    if side == "white":
        return {
            "ivory": material("WB_Ivory", (0.90, 0.86, 0.76), 0.00, 0.39),
            "skin": material("WB_ElephantSkin", (0.55, 0.54, 0.51), 0.00, 0.62),
            "skin_hi": material("WB_ElephantHighlight", (0.68, 0.67, 0.62), 0.00, 0.54),
            "blue": material("WB_ClothBlue", (0.07, 0.24, 0.43), 0.02, 0.48),
            "blue_hi": material("WB_ClothBlueHi", (0.13, 0.40, 0.66), 0.02, 0.40),
            "gold": material("WB_Gold", (0.72, 0.48, 0.15), 0.76, 0.24),
            "steel": material("WB_Steel", (0.42, 0.46, 0.50), 0.76, 0.25),
            "leather": material("WB_Leather", (0.20, 0.11, 0.065), 0.0, 0.69),
            "dark": material("WB_Dark", (0.055, 0.060, 0.070), 0.08, 0.47),
            "eye": material("WB_Eye", (0.045, 0.10, 0.16), 0.08, 0.20),
            "gem": material("WB_Gem", (0.08, 0.54, 0.88), 0.18, 0.13),
        }
    return {
        "ivory": material("BB_Bone", (0.46, 0.40, 0.34), 0.00, 0.55),
        "skin": material("BB_AshenSkin", (0.18, 0.16, 0.18), 0.00, 0.62),
        "skin_hi": material("BB_AshenHighlight", (0.28, 0.24, 0.28), 0.02, 0.50),
        "blue": material("BB_Robe", (0.18, 0.025, 0.08), 0.02, 0.52),
        "blue_hi": material("BB_RobeHi", (0.36, 0.045, 0.14), 0.02, 0.44),
        "gold": material("BB_Bronze", (0.43, 0.23, 0.08), 0.72, 0.29),
        "steel": material("BB_BlackSteel", (0.15, 0.15, 0.18), 0.78, 0.24),
        "leather": material("BB_Leather", (0.075, 0.035, 0.028), 0.0, 0.73),
        "dark": material("BB_Dark", (0.018, 0.016, 0.021), 0.16, 0.45),
        "eye": material("BB_Eye", (0.72, 0.055, 0.025), 0.10, 0.16),
        "gem": material("BB_Gem", (0.72, 0.035, 0.16), 0.25, 0.12),
    }


def pedestal(P, objects):
    objects.append(cyl("PedestalLower", (0,0,0.07), 0.47, 0.14, P["dark"], vertices=64))
    objects.append(torus("PedestalTrim", (0,0,0.13), 0.405, 0.034, P["gold"]))
    objects.append(cyl("PedestalUpper", (0,0,0.19), 0.395, 0.13, P["ivory"], vertices=64))
    objects.append(torus("PedestalUpperTrim", (0,0,0.255), 0.365, 0.022, P["gold"]))


def robe_layer(name, z, width, depth, height, P, objects, front=True):
    y = -0.045 if front else 0.055
    objects.append(cone(name, (0,y,z), width, width*0.74, height, P["blue"], vertices=64))


def build_bishop(side, output):
    P = palette(side)
    objects = []
    root = bpy.data.objects.new(
        "WhiteBishopProductionV1" if side == "white" else "BlackBishopProductionV1", None
    )
    bpy.context.collection.objects.link(root)

    pedestal(P, objects)

    # Layered clerical robe / chess-bishop body.
    objects.append(cone("RobeCore", (0,0,0.79), 0.38, 0.27, 0.95, P["blue"], vertices=64))
    objects.append(cone("RobeInner", (0,-0.025,0.84), 0.31, 0.23, 0.82, P["blue_hi"], vertices=64))
    objects.append(rounded_box("RobeFrontPanel", (0,-0.285,0.79), (0.16,0.035,0.34), P["ivory"], bevel=0.035))
    objects.append(rounded_box("RobeGoldStripe", (0,-0.326,0.80), (0.040,0.014,0.30), P["gold"], bevel=0.010))
    for i, x in enumerate((-0.20, 0.20)):
        objects.append(cone(f"RobeSideFold_{i}", (x,0.03,0.74), 0.12, 0.07, 0.72, P["blue"], vertices=40))
    objects.append(torus("WaistCord", (0,0,1.08), 0.27, 0.027, P["gold"]))

    # Cape has an exact capture-animation prefix plus layered tails.
    objects.append(rounded_box("V3_CapeLayer", (0,0.19,1.11), (0.31,0.045,0.43), P["blue_hi"], rot=(math.radians(-7),0,0), bevel=0.055))
    for i, x in enumerate((-0.20,0,0.20)):
        objects.append(rounded_box(
            f"V3_CapeLayerDetail_{i}", (x,0.225,0.86), (0.11,0.025,0.28),
            P["blue"], rot=(math.radians(-8),0,math.radians(x*12)), bevel=0.035
        ))

    # Broad collar and shoulders produce a readable cleric silhouette.
    objects.append(torus("CollarRing", (0,0,1.24), 0.29, 0.065, P["ivory"]))
    objects.append(rounded_box("ShoulderMantle_L", (-0.25,0,1.20), (0.18,0.17,0.10), P["ivory"], bevel=0.07))
    objects.append(rounded_box("ShoulderMantle_R", (0.25,0,1.20), (0.18,0.17,0.10), P["ivory"], bevel=0.07))
    objects.append(sphere("ChestGem", (0,-0.20,1.19), (0.07,0.045,0.08), P["gem"], 32, 16))

    # Elephant/demonic bishop face.
    objects.append(sphere("Head", (0,-0.02,1.48), (0.27,0.24,0.25), P["skin_hi"], 56, 28))
    objects.append(sphere("BrowMass", (0,-0.18,1.54), (0.23,0.07,0.10), P["skin"], 44, 22))
    objects.append(sphere("Cheek_L", (-0.17,-0.17,1.43), (0.10,0.075,0.13), P["skin_hi"], 36, 18))
    objects.append(sphere("Cheek_R", (0.17,-0.17,1.43), (0.10,0.075,0.13), P["skin_hi"], 36, 18))
    objects.append(sphere("Eye_L", (-0.095,-0.225,1.56), (0.036,0.022,0.035), P["eye"], 28, 14))
    objects.append(sphere("Eye_R", (0.095,-0.225,1.56), (0.036,0.022,0.035), P["eye"], 28, 14))
    objects.append(sphere("EyeRim_L", (-0.095,-0.207,1.56), (0.065,0.020,0.055), P["dark"], 28, 14))
    objects.append(sphere("EyeRim_R", (0.095,-0.207,1.56), (0.065,0.020,0.055), P["dark"], 28, 14))

    # Large ears with inner-ear layers.
    for sign, label in [(-1,"L"),(1,"R")]:
        objects.append(sphere(f"Ear_{label}", (0.255*sign,-0.005,1.48), (0.16,0.055,0.24), P["skin"], 44, 22))
        objects.append(sphere(f"InnerEar_{label}", (0.277*sign,-0.048,1.48), (0.105,0.025,0.17), P["blue_hi"] if side=="white" else P["blue"], 36, 18))
        objects.append(cone(f"Tusk_{label}", (0.12*sign,-0.35,1.38), 0.045, 0.006, 0.30, P["ivory"], rot=(math.radians(78),0,math.radians(-8*sign)), vertices=32))

    # Entire trunk is independently animatable; tip keeps the legacy V3 hook.
    trunk_points = [(0,-0.22,1.46),(0,-0.34,1.31),(0,-0.36,1.13),(0.035,-0.34,1.00)]
    objects.append(tube("Trunk", trunk_points, 0.082, P["skin"]))
    objects.append(sphere("V3_TrunkTip", (0.04,-0.34,0.98), (0.090,0.080,0.075), P["skin_hi"], 36, 18))
    objects.append(sphere("TrunkNostril", (0.055,-0.405,0.955), (0.024,0.016,0.018), P["dark"], 24, 12))

    # Bishop mitre/crown. Black becomes a horned ritual headdress.
    objects.append(cone("MitreTall", (0,0.00,1.83), 0.22, 0.045, 0.52, P["ivory"], vertices=64))
    objects.append(rounded_box("MitreFrontBand", (0,-0.155,1.78), (0.075,0.028,0.19), P["gold"], bevel=0.018))
    objects.append(sphere("MitreGem", (0,-0.193,1.83), (0.055,0.030,0.070), P["gem"], 32, 16))
    if side == "black":
        objects.append(cone("HornL", (-0.15,0.0,1.92), 0.060, 0.008, 0.34, P["ivory"], rot=(0,math.radians(-24),math.radians(-20)), vertices=32))
        objects.append(cone("HornR", (0.15,0.0,1.92), 0.060, 0.008, 0.34, P["ivory"], rot=(0,math.radians(24),math.radians(20)), vertices=32))
        objects.append(sphere("SkullCharm", (0,-0.21,1.22), (0.070,0.045,0.075), P["ivory"], 32, 16))

    # Arms / hands.
    for sign, label in [(-1,"L"),(1,"R")]:
        objects.append(sphere(f"Arm_{label}", (0.31*sign,-0.01,1.10), (0.095,0.10,0.24), P["blue_hi"], 40, 20))
        objects[-1].rotation_euler.y = math.radians(8*sign)
        objects.append(sphere(f"Hand_{label}", (0.34*sign,-0.07,0.92), (0.085,0.075,0.085), P["skin_hi"], 32, 16))

    # Ceremonial staff: exact Staff prefix for capture animation.
    sx = 0.42
    objects.append(cyl("Staff", (sx,-0.02,1.22), 0.028, 1.55, P["leather"], rot=(0,0,math.radians(-3)), vertices=32))
    objects.append(torus("StaffHalo", (sx,-0.02,1.95), 0.17, 0.028, P["gold"], rot=(math.radians(90),0,0)))
    objects.append(torus("StaffOuterHalo", (sx,-0.02,1.95), 0.225, 0.018, P["gold"], rot=(math.radians(90),0,0)))
    objects.append(sphere("StaffGem", (sx,-0.04,1.95), (0.075,0.050,0.075), P["gem"], 32, 16))
    for i, angle in enumerate((0,90,180,270)):
        a = math.radians(angle)
        objects.append(cone(
            f"StaffRay_{i}",
            (sx + math.cos(a)*0.24, -0.02, 1.95 + math.sin(a)*0.24),
            0.032, 0.005, 0.15, P["gold"],
            rot=(0, math.radians(90-angle), 0), vertices=24
        ))

    # Front ornament / readable faction motifs.
    if side == "white":
        objects.append(rounded_box("ChestCrossV", (0,-0.342,0.86), (0.035,0.014,0.15), P["gold"], bevel=0.010))
        objects.append(rounded_box("ChestCrossH", (0,-0.344,0.90), (0.105,0.014,0.035), P["gold"], bevel=0.010))
    else:
        objects.append(cone("ChestSpikeL", (-0.10,-0.345,0.91), 0.035,0.005,0.20, P["gold"], rot=(0,math.radians(-25),0), vertices=24))
        objects.append(cone("ChestSpikeR", (0.10,-0.345,0.91), 0.035,0.005,0.20, P["gold"], rot=(0,math.radians(25),0), vertices=24))

    # Extra trim/detail to lift the model above V3 blockout density.
    for i in range(5):
        z = 0.48 + i * 0.14
        objects.append(torus(f"RobeTrim_{i}", (0,0,z), 0.31 - i*0.012, 0.010, P["gold"]))
    for i, x in enumerate((-0.24,-0.12,0.12,0.24)):
        objects.append(rounded_box(f"FrontPleat_{i}", (x,-0.305,0.63), (0.035,0.016,0.24), P["blue_hi"], bevel=0.012))

    parent_all(root, objects)

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
        # Match the proven production Pawn export axis convention. Applying the\n        # glTF transform here flips the static Bishop front/back in Godot.\n        export_apply=False,
    )
    print("BISHOP_PRODUCTION_EXPORT_PASS", side, out, "parts=", len(objects))

    for o in list(objects):
        if o.name in bpy.data.objects:
            bpy.data.objects.remove(o, do_unlink=True)
    if root.name in bpy.data.objects:
        bpy.data.objects.remove(root, do_unlink=True)
    for mesh in list(bpy.data.meshes):
        if mesh.users == 0:
            bpy.data.meshes.remove(mesh)
    for curve in list(bpy.data.curves):
        if curve.users == 0:
            bpy.data.curves.remove(curve)


def main():
    args = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    build_bishop("white", args.white_output)
    build_bishop("black", args.black_output)
    print("BISHOP_PRODUCTION_BUILD_PASS")


if __name__ == "__main__":
    main()
