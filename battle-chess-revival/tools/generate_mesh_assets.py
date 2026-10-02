#!/usr/bin/env python3
"""Build authored mesh source assets used by the Godot prototype.

This first pass replaces the White Pawn runtime primitive construction with
a real imported GLB scene. Geometry is intentionally kept in separate named
parts so the later Skeleton3D/rig pass can map limbs and props cleanly.
"""
from pathlib import Path
import math
import numpy as np
import trimesh
from trimesh.transformations import rotation_matrix

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "models"
OUT.mkdir(parents=True, exist_ok=True)

def pbr(name, color, metallic=0.0, roughness=0.5):
    rgba=np.array([int(color[i:i+2],16) for i in (1,3,5)] + [255],dtype=np.uint8)/255.0
    return trimesh.visual.material.PBRMaterial(
        name=name, baseColorFactor=rgba, metallicFactor=metallic, roughnessFactor=roughness
    )

M={
    "iv":pbr("Ivory","#e8e1d6",0.0,0.48),
    "ivs":pbr("IvoryShadow","#b8ad9b",0.0,0.58),
    "blue":pbr("Blue","#31577f",0.0,0.45),
    "gold":pbr("Gold","#c79a43",0.72,0.26),
    "bronze":pbr("Bronze","#7a532f",0.58,0.34),
    "leather":pbr("Leather","#4b3024",0.0,0.72),
    "skin":pbr("Skin","#d59f78",0.0,0.56),
    "dark":pbr("Dark","#211d20",0.0,0.48),
    "eye":pbr("Eyes","#25374d",0.0,0.22),
}

scene=trimesh.Scene()

def add(name, mesh, material, pos=(0,0,0), rot=(0,0,0), scale=(1,1,1)):
    mesh=mesh.copy()
    mesh.apply_scale(scale)
    transform=np.eye(4)
    for axis,deg in zip(((1,0,0),(0,1,0),(0,0,1)),rot):
        if deg:
            transform=rotation_matrix(math.radians(deg),axis) @ transform
    transform[:3,3]=pos
    mesh.apply_transform(transform)
    mesh.visual=trimesh.visual.TextureVisuals(material=material)
    scene.add_geometry(mesh,geom_name=name,node_name=name)

def cyl(radius,height):
    mesh=trimesh.creation.cylinder(radius=radius,height=height,sections=24)
    mesh.apply_transform(rotation_matrix(math.radians(90),(1,0,0)))
    return mesh

def capsule(radius,height):
    mesh=trimesh.creation.capsule(
        height=max(0.001,height-radius*2.0),radius=radius,count=(12,12)
    )
    mesh.apply_transform(rotation_matrix(math.radians(90),(1,0,0)))
    return mesh

def sphere(radius):
    return trimesh.creation.icosphere(subdivisions=2,radius=radius)

def box(extents):
    return trimesh.creation.box(extents=extents)

# Chess pedestal.
add("Pedestal_Lower",cyl(.43,.08),M["dark"],(0,.04,0))
add("Pedestal_Gold_Ring",cyl(.39,.05),M["gold"],(0,.105,0))
add("Pedestal_Upper",cyl(.35,.10),M["ivs"],(0,.18,0))

# Separated legs / oversized boots.
for i,x in enumerate((-.14,.14)):
    add(f"Boot_{i}",capsule(.12,.32),M["leather"],(x,.34,.04),(90,0,0),(1.05,1,1.2))
    add(f"Leg_{i}",capsule(.085,.36),M["blue"],(x,.50,0))

# Quilted torso.
add("Torso",capsule(.27,.66),M["iv"],(0,.80,0),scale=(1.05,1,.92))
add("Belt",box((.56,.10,.31)),M["leather"],(0,.67,0))
add("Buckle",box((.13,.12,.045)),M["gold"],(0,.67,-.175))
for y in (.77,.88,.99):
    add(f"TunicBand_{y}",box((.44,.025,.025)),M["ivs"],(0,y,-.245))
for x in (-.12,0,.12):
    add(f"TunicVert_{x}",box((.02,.35,.025)),M["ivs"],(x,.88,-.245))

# Arms, hands and shield.
for side in (-1,1):
    add(f"Shoulder_{side}",sphere(.165),M["ivs"],(.30*side,.96,0),scale=(1.1,.8,1))
    add(f"Arm_{side}",capsule(.085,.40),M["iv"],(.35*side,.79,0),(0,0,18*side))
    add(f"Hand_{side}",sphere(.10),M["skin"],(.40*side,.61,-.02))
add("Shield",cyl(.30,.075),M["blue"],(-.45,.75,-.01),(90,0,90))
add("Shield_Cross_V",box((.055,.36,.055)),M["gold"],(-.485,.75,-.02))
add("Shield_Cross_H",box((.055,.055,.36)),M["gold"],(-.485,.75,-.02),(90,0,0))

# Expressive face.
add("Head",sphere(.24),M["skin"],(0,1.18,-.01),scale=(1,.98,.93))
add("Nose",sphere(.06),M["skin"],(0,1.15,-.23),scale=(.90,.78,1.25))
for i,x in enumerate((-.078,.078)):
    add(f"Eye_{i}",sphere(.031),M["eye"],(x,1.22,-.225),scale=(1,.85,.55))
add("Brow_L",box((.10,.018,.018)),M["dark"],(-.08,1.275,-.225),(0,0,-8))
add("Brow_R",box((.10,.018,.018)),M["dark"],(.08,1.275,-.225),(0,0,8))

# Rounded helmet, cheek guards and crest.
add("Helmet_Dome",sphere(.27),M["ivs"],(0,1.34,0),scale=(1.07,.70,1.04))
add("Helmet_Rim",box((.56,.065,.36)),M["gold"],(0,1.28,-.01))
add("Helmet_Nose_Guard",box((.06,.23,.05)),M["gold"],(0,1.18,-.24))
add("Helmet_Crest",box((.11,.32,.18)),M["blue"],(0,1.55,-.02),(0,0,-8))
add("CheekGuard_L",box((.08,.24,.07)),M["ivs"],(-.205,1.22,-.04),(0,0,-10))
add("CheekGuard_R",box((.08,.24,.07)),M["ivs"],(.205,1.22,-.04),(0,0,10))

# Compact spear for the toe-stab signature.
add("Spear_Shaft",cyl(.028,.98),M["bronze"],(.42,.92,-.03),(0,0,-7))
tip=trimesh.creation.cone(radius=.075,height=.20,sections=24)
tip.apply_transform(rotation_matrix(math.radians(90),(1,0,0)))
add("Spear_Tip",tip,M["gold"],(.54,1.39,-.03),(0,0,-7))

target=OUT / "white_pawn_refined_v1.glb"
target.write_bytes(scene.export(file_type="glb"))
print(f"ASSET_BUILD_PASS {target} bytes={target.stat().st_size} parts={len(scene.geometry)}")
