#!/usr/bin/env python3
"""Build the production-v1 cathedral shell for Battle Chess Revival.

Coordinates are authored to match ArenaBuilder's Godot space:
Godot (x, y, z) -> Blender (x, -z, y).
The chess board and gameplay pieces remain separate Godot scenes.
"""
import argparse
import math
import sys
from pathlib import Path

import bpy


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--output", required=True)
    return p.parse_args(argv)


def G(x, y, z):
    return (x, -z, y)


def GS(x, y, z):
    return (x, z, y)


def material(name, color, metallic=0.0, roughness=0.55, emission=None, emission_strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bs = m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1.0)
    bs.inputs["Metallic"].default_value = metallic
    bs.inputs["Roughness"].default_value = roughness
    if emission is not None:
        if "Emission Color" in bs.inputs:
            bs.inputs["Emission Color"].default_value = (*emission, 1.0)
            bs.inputs["Emission Strength"].default_value = emission_strength
        elif "Emission" in bs.inputs:
            bs.inputs["Emission"].default_value = (*emission, 1.0)
            bs.inputs["Emission Strength"].default_value = emission_strength
    return m


def finish(o, mat=None, smooth=False):
    if getattr(o, "data", None) is not None:
        o.data.name = o.name
    if mat is not None:
        o.data.materials.append(mat)
    if smooth and o.type == "MESH":
        for p in o.data.polygons:
            p.use_smooth = True
    return o


def box(name, pos_g, size_g, mat, bevel=0.0, rot_bl=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=G(*pos_g), rotation=rot_bl)
    o = bpy.context.object
    o.name = name
    sx, sy, sz = GS(*size_g)
    o.scale = (sx * 0.5, sy * 0.5, sz * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        mod = o.modifiers.new("ArchitecturalBevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o, mat)


def cylinder(name, pos_g, radius, height, mat, vertices=48):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=height, location=G(*pos_g)
    )
    o = bpy.context.object
    o.name = name
    return finish(o, mat, True)


def sphere(name, pos_g, radius, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=40, ring_count=20, radius=radius, location=G(*pos_g))
    o = bpy.context.object
    o.name = name
    return finish(o, mat, True)


def tube_poly(name, points_g, radius, mat):
    curve = bpy.data.curves.new(name + "_Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 2
    curve.bevel_depth = radius
    curve.bevel_resolution = 3
    spline = curve.splines.new("POLY")
    spline.points.add(len(points_g) - 1)
    for pt, co in zip(spline.points, points_g):
        bx, by, bz = G(*co)
        pt.co = (bx, by, bz, 1.0)
    o = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(o)
    curve.materials.append(mat)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.convert(target="MESH")
    o = bpy.context.object
    o.name = name
    o.data.name = name
    return finish(o, None, True)


def arch(name, center_g, width, spring_y, rise, depth, mat):
    cx, cy, cz = center_g
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    radius = width * 0.5
    parts = []
    # Pillars.
    parts.append(box(name + "_PillarL", (cx - radius, cy + spring_y * 0.5, cz), (0.48, spring_y, depth), mat, 0.06))
    parts.append(box(name + "_PillarR", (cx + radius, cy + spring_y * 0.5, cz), (0.48, spring_y, depth), mat, 0.06))
    # Curved voussoirs.
    segments = 17
    for i in range(segments):
        t = i / float(segments - 1)
        a = math.pi - t * math.pi
        x = cx + math.cos(a) * radius
        y = cy + spring_y + math.sin(a) * rise
        o = box(
            f"{name}_Voussoir_{i:02d}",
            (x, y, cz),
            (width / segments * 1.42, 0.44, depth),
            mat,
            0.04,
            rot_bl=(0, -a + math.pi * 0.5, 0),
        )
        parts.append(o)
    for o in parts:
        o.parent = root
    return root


def banner(name, pos_g, cloth, gold):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    x, y, z = pos_g
    parts = [
        box(name + "_Bar", (x, y + 1.55, z), (2.2, 0.10, 0.10), gold, 0.02),
        box(name + "_Cloth", (x, y, z), (1.75, 2.75, 0.07), cloth, 0.03),
        box(name + "_CrestV", (x, y + 0.22, z - 0.045), (0.13, 0.88, 0.04), gold, 0.01),
        box(name + "_CrestH", (x, y + 0.22, z - 0.047), (0.76, 0.13, 0.04), gold, 0.01),
    ]
    for o in parts:
        o.parent = root
    return root


def candle_cluster(name, pos_g, gold, wax, flame):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    x, y, z = pos_g
    for i in range(5):
        a = math.tau * i / 5.0
        px = x + math.cos(a) * 0.24
        pz = z + math.sin(a) * 0.24
        h = 0.46 + (i % 2) * 0.10
        c = cylinder(f"{name}_Candle_{i}", (px, y + h * 0.5 + 0.08, pz), 0.045, h, wax, 24)
        c.parent = root
        f = sphere(f"{name}_Flame_{i}", (px, y + h + 0.15, pz), 0.055, flame)
        f.scale = (0.72, 0.72, 1.35)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        f.parent = root
    h = cylinder(name + "_Holder", (x, y + 0.04, z), 0.34, 0.08, gold, 40)
    h.parent = root
    return root


def main():
    a = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)

    stone = material("Cathedral_Stone", (0.42, 0.38, 0.34), 0.0, 0.68)
    stone_hi = material("Cathedral_StoneHi", (0.58, 0.52, 0.45), 0.0, 0.58)
    stone_dark = material("Cathedral_StoneDark", (0.24, 0.21, 0.20), 0.0, 0.73)
    floor = material("Cathedral_Floor", (0.20, 0.17, 0.16), 0.0, 0.62)
    gold = material("Cathedral_Gold", (0.62, 0.38, 0.10), 0.78, 0.26)
    red = material("Cathedral_RedCloth", (0.34, 0.07, 0.07), 0.0, 0.64)
    blue = material("Cathedral_BlueCloth", (0.08, 0.16, 0.30), 0.0, 0.62)
    wax = material("Cathedral_Wax", (0.82, 0.74, 0.57), 0.0, 0.72)
    flame = material("Cathedral_Flame", (1.0, 0.40, 0.08), 0.0, 0.18, (1.0, 0.30, 0.04), 5.0)
    glass_red = material("Glass_Red", (0.32, 0.03, 0.08), 0.0, 0.22, (0.85, 0.10, 0.18), 2.5)
    glass_gold = material("Glass_Gold", (0.48, 0.26, 0.05), 0.0, 0.20, (1.0, 0.55, 0.08), 2.8)
    glass_blue = material("Glass_Blue", (0.05, 0.12, 0.32), 0.0, 0.22, (0.12, 0.36, 0.95), 2.4)

    root = bpy.data.objects.new("CathedralProductionV1", None)
    bpy.context.collection.objects.link(root)

    objs = []

    # Nave shell and layered floor/plinths.
    objs += [
        box("NaveFloor", (0, -0.12, 0), (22.0, 0.24, 28.0), floor, 0.08),
        box("BackWallLower", (0, 4.0, -13.75), (22.0, 8.0, 0.50), stone_dark, 0.05),
        box("BackWallUpper", (0, 11.0, -13.75), (22.0, 6.0, 0.46), stone, 0.05),
        box("LeftWallLower", (-10.85, 4.0, 0), (0.50, 8.0, 28.0), stone_dark, 0.05),
        box("RightWallLower", (10.85, 4.0, 0), (0.50, 8.0, 28.0), stone_dark, 0.05),
        box("LeftWallUpper", (-10.85, 11.0, 0), (0.46, 6.0, 28.0), stone, 0.05),
        box("RightWallUpper", (10.85, 11.0, 0), (0.46, 6.0, 28.0), stone, 0.05),
    ]

    # Side aisles: repeated compound columns with base/capital rings.
    for side in (-1.0, 1.0):
        x = 8.55 * side
        for idx, z in enumerate((-10.0, -5.0, 0.0, 5.0, 10.0)):
            objs.append(cylinder(f"Column_{'L' if side < 0 else 'R'}_{idx}_Shaft", (x, 5.25, z), 0.50, 9.8, stone_hi, 56))
            objs.append(cylinder(f"Column_{'L' if side < 0 else 'R'}_{idx}_Base", (x, 0.45, z), 0.72, 0.55, stone_dark, 56))
            objs.append(cylinder(f"Column_{'L' if side < 0 else 'R'}_{idx}_Base2", (x, 0.76, z), 0.61, 0.22, gold, 56))
            objs.append(cylinder(f"Column_{'L' if side < 0 else 'R'}_{idx}_Capital", (x, 10.10, z), 0.75, 0.42, stone_hi, 56))
            objs.append(cylinder(f"Column_{'L' if side < 0 else 'R'}_{idx}_CapitalGold", (x, 9.82, z), 0.59, 0.16, gold, 56))

    # Back altar architecture: three deep arches and stepped dais.
    arch("CenterArch", (0, 0, -13.35), 5.2, 5.0, 2.4, 0.70, stone_hi).parent = root
    arch("LeftArch", (-5.8, 0, -13.36), 3.1, 4.7, 1.55, 0.68, stone_hi).parent = root
    arch("RightArch", (5.8, 0, -13.36), 3.1, 4.7, 1.55, 0.68, stone_hi).parent = root

    for i in range(6):
        objs.append(box(
            f"AltarStep_{i}",
            (0, 0.12 + i * 0.22, -10.1 - i * 0.52),
            (8.4 - i * 0.55, 0.24, 1.10),
            stone_hi if i % 2 == 0 else stone,
            0.05,
        ))
    objs.append(box("AltarTable", (0, 1.72, -12.30), (6.2, 1.25, 2.15), stone_hi, 0.12))
    objs.append(box("AltarInset", (0, 1.70, -13.18), (4.5, 0.75, 0.22), stone_dark, 0.04))
    objs.append(box("AltarGoldBand", (0, 2.25, -11.30), (5.3, 0.12, 0.10), gold, 0.02))

    # Back stained glass, subdivided into panels with real stone/gold framing.
    back_specs = [
        (-5.8, 7.6, 2.25, 4.9, glass_red),
        (0.0, 8.1, 3.5, 6.0, glass_gold),
        (5.8, 7.6, 2.25, 4.9, glass_blue),
    ]
    for idx, (x, y, w, h, gm) in enumerate(back_specs):
        objs.append(box(f"BackGlass_{idx}", (x, y, -13.46), (w, h, 0.08), gm, 0.01))
        objs.append(box(f"BackGlass_{idx}_FrameL", (x - w * 0.5, y, -13.39), (0.13, h + 0.25, 0.16), gold, 0.02))
        objs.append(box(f"BackGlass_{idx}_FrameR", (x + w * 0.5, y, -13.39), (0.13, h + 0.25, 0.16), gold, 0.02))
        objs.append(box(f"BackGlass_{idx}_FrameTop", (x, y + h * 0.5, -13.39), (w + 0.22, 0.13, 0.16), gold, 0.02))
        objs.append(box(f"BackGlass_{idx}_FrameBottom", (x, y - h * 0.5, -13.39), (w + 0.22, 0.13, 0.16), gold, 0.02))
        objs.append(box(f"BackGlass_{idx}_Mullion", (x, y, -13.37), (0.10, h, 0.13), gold, 0.01))
        objs.append(box(f"BackGlass_{idx}_Cross", (x, y + 0.45, -13.37), (w, 0.10, 0.13), gold, 0.01))

    # Side stained-glass bays in both aisles.
    side_glass = (glass_gold, glass_red, glass_blue)
    for side in (-1.0, 1.0):
        x = 10.57 * side
        for idx, z in enumerate((5.2, 0.0, -5.2)):
            gm = side_glass[idx]
            objs.append(box(f"SideGlass_{'L' if side < 0 else 'R'}_{idx}", (x, 6.1, z), (0.08, 4.9, 2.4), gm, 0.01))
            objs.append(box(f"SideGlass_{'L' if side < 0 else 'R'}_{idx}_FrameV", (x - 0.02 * side, 6.1, z), (0.15, 5.05, 0.11), gold, 0.02))
            objs.append(box(f"SideGlass_{'L' if side < 0 else 'R'}_{idx}_FrameH", (x - 0.02 * side, 6.55, z), (0.15, 0.11, 2.55), gold, 0.02))

    # Visible ceiling structure: pointed vault ribs repeated along the nave.
    for ridx, z in enumerate((-9.2, -4.6, 0.0, 4.6, 9.2)):
        points = []
        for i in range(17):
            t = i / 16.0
            x = -8.4 + 16.8 * t
            # Gothic-ish pointed vault; high center, lower springing at columns.
            y = 10.25 + 3.7 * (1.0 - abs(2.0 * t - 1.0) ** 0.62)
            points.append((x, y, z))
        rib = tube_poly(f"VaultRib_{ridx}", points, 0.11, gold)
        rib.parent = root

    # Longitudinal ceiling ridge and secondary ribs.
    ridge = tube_poly("NaveRidge", [(0, 13.95, z) for z in (-13.2, -9.0, -4.5, 0.0, 4.5, 9.0, 13.2)], 0.13, stone_hi)
    ridge.parent = root
    for side in (-1.0, 1.0):
        beam = tube_poly(
            f"UpperArcade_{'L' if side < 0 else 'R'}",
            [(8.5 * side, 10.15, z) for z in (-13.0, -8.0, -3.0, 2.0, 7.0, 12.0)],
            0.10,
            stone_hi,
        )
        beam.parent = root

    # Heraldic banners and altar side details.
    banner("BannerWhiteA", (-9.65, 6.7, -5.0), red, gold).parent = root
    banner("BannerWhiteB", (-9.65, 6.7, 3.3), red, gold).parent = root
    banner("BannerBlackA", (9.65, 6.7, -5.0), blue, gold).parent = root
    banner("BannerBlackB", (9.65, 6.7, 3.3), blue, gold).parent = root

    # Statues as layered pedestal/body/head forms.
    for idx, x in enumerate((-3.8, 3.8)):
        objs.append(box(f"Statue_{idx}_Pedestal", (x, 0.48, -11.55), (1.2, 0.95, 1.2), stone_dark, 0.06))
        objs.append(cylinder(f"Statue_{idx}_Body", (x, 1.70, -11.55), 0.31, 1.65, stone_hi, 40))
        objs.append(sphere(f"Statue_{idx}_Head", (x, 2.80, -11.55), 0.33, stone_hi))
        objs.append(box(f"Statue_{idx}_Halo", (x, 2.82, -11.72), (0.78, 0.78, 0.08), gold, 0.08))

    # Candle groups around the action space.
    for idx, p in enumerate(((-6.2, 0.0, -8.0), (6.2, 0.0, -8.0), (-6.8, 0.0, 6.2), (6.8, 0.0, 6.2))):
        candle_cluster(f"CandleCluster_{idx}", p, gold, wax, flame).parent = root

    # Small decorative wall pilasters improve depth in the gameplay camera.
    for side in (-1.0, 1.0):
        for idx, z in enumerate((-7.6, -2.6, 2.6, 7.6)):
            objs.append(box(f"Pilaster_{'L' if side < 0 else 'R'}_{idx}", (10.30 * side, 6.2, z), (0.55, 7.8, 0.72), stone_hi, 0.06))
            objs.append(box(f"PilasterCap_{'L' if side < 0 else 'R'}_{idx}", (10.20 * side, 10.05, z), (0.80, 0.35, 0.95), gold, 0.04))

    for o in objs:
        o.parent = root

    # Select the complete hierarchy and export.
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for o in bpy.context.scene.objects:
        if o != root:
            o.select_set(True)
    bpy.context.view_layer.objects.active = root

    out = Path(a.output).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(out),
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_cameras=False,
        export_lights=False,
        export_apply=False,
    )
    mesh_count = len([o for o in bpy.context.scene.objects if o.type == "MESH"])
    print("CATHEDRAL_PRODUCTION_EXPORT_PASS", out, "meshes=", mesh_count)


if __name__ == "__main__":
    main()
