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
    mesh.visual=trimesh.visual.TextureVisuals(material=material)
    scene.add_geometry(mesh,geom_name=name,node_name=name,transform=transform)

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

target=OUT / "white_pawn_concept_v2.glb"
target.write_bytes(scene.export(file_type="glb"))
print(f"ASSET_BUILD_PASS {target} bytes={target.stat().st_size} parts={len(scene.geometry)}")


# ---------------------------------------------------------------------------
# Black Pawn — separate imported GLB, intentionally a different silhouette.
# ---------------------------------------------------------------------------
BM={
    "char":pbr("Charcoal","#302a31",0.12,0.54),
    "char2":pbr("CharcoalEdge","#4a414b",0.18,0.44),
    "leather":pbr("DarkLeather","#3b2926",0.0,0.72),
    "bronze":pbr("OldBronze","#79583b",0.46,0.36),
    "violet":pbr("EnemyViolet","#58306f",0.06,0.44),
    "green":pbr("GoblinSkin","#718250",0.0,0.58),
    "green2":pbr("GoblinShadow","#465330",0.0,0.64),
    "red":pbr("EnemyRed","#8d3943",0.0,0.43),
    "eye":pbr("GoblinEyes","#d7c55f",0.0,0.18),
    "steel":pbr("KnifeSteel","#8b8a86",0.68,0.28),
    "dark":pbr("NearBlack","#171419",0.0,0.50),
}
black_scene=trimesh.Scene()

def addb(name, mesh, material, pos=(0,0,0), rot=(0,0,0), scale=(1,1,1)):
    mesh=mesh.copy()
    mesh.apply_scale(scale)
    transform=np.eye(4)
    for axis,deg in zip(((1,0,0),(0,1,0),(0,0,1)),rot):
        if deg:
            transform=rotation_matrix(math.radians(deg),axis) @ transform
    transform[:3,3]=pos
    mesh.visual=trimesh.visual.TextureVisuals(material=material)
    black_scene.add_geometry(mesh,geom_name=name,node_name=name,transform=transform)

# Pedestal.
addb("Pedestal_Lower",cyl(.43,.08),BM["dark"],(0,.04,0))
addb("Pedestal_Bronze_Ring",cyl(.39,.05),BM["bronze"],(0,.105,0))
addb("Pedestal_Upper",cyl(.35,.10),BM["char"],(0,.18,0))

# Compact crouched goblin stance.
for i,x in enumerate((-.14,.14)):
    addb(f"Boot_{i}",capsule(.125,.31),BM["dark"],(x,.34,.04),(90,0,0),(1.08,1,1.22))
    addb(f"Shin_{i}",capsule(.08,.32),BM["char"],(x,.48,0),(0,0,5*(-1 if i==0 else 1)))
addb("Torso",capsule(.27,.62),BM["leather"],(0,.77,0),scale=(1.08,.98,.94))
addb("ChestPlate",box((.46,.30,.06)),BM["char2"],(0,.83,-.245))
addb("Belt",box((.55,.10,.31)),BM["dark"],(0,.65,0))
addb("Buckle",box((.12,.10,.04)),BM["bronze"],(0,.65,-.175))

# Ragged shoulder armor + long green arms.
for side in (-1,1):
    addb(f"Shoulder_{side}",sphere(.15),BM["char"],(.30*side,.94,0),scale=(1.10,.72,1.0))
    addb(f"Arm_{side}",capsule(.078,.42),BM["green2"],(.35*side,.76,0),(0,0,20*side))
    addb(f"Hand_{side}",sphere(.102),BM["green"],(.41*side,.58,-.025),scale=(1.08,.94,1))
addb("Shield",cyl(.28,.075),BM["char"],(-.45,.72,-.01),(90,0,90))
addb("ShieldSlashA",box((.055,.33,.05)),BM["red"],(-.486,.72,-.02),(0,0,20))
addb("ShieldSlashB",box((.055,.05,.31)),BM["red"],(-.486,.72,-.02),(90,0,0))

# Head: much wider ears and nose than the White Pawn.
addb("Head",sphere(.24),BM["green"],(0,1.16,-.01),scale=(1.05,.93,.92))
addb("Nose",sphere(.075),BM["green2"],(0,1.12,-.238),scale=(1.08,.72,1.35))
addb("Ear_L",sphere(.12),BM["green"],(-.26,1.18,-.01),rot=(0,0,-8),scale=(1.65,.50,.72))
addb("Ear_R",sphere(.12),BM["green"],(.26,1.18,-.01),rot=(0,0,8),scale=(1.65,.50,.72))
for i,x in enumerate((-.078,.078)):
    addb(f"Eye_{i}",sphere(.034),BM["eye"],(x,1.22,-.225),scale=(1.0,.76,.55))
addb("Brow_L",box((.11,.022,.018)),BM["dark"],(-.08,1.275,-.226),(0,0,-16))
addb("Brow_R",box((.11,.022,.018)),BM["dark"],(.08,1.275,-.226),(0,0,16))
addb("Tooth_L",box((.035,.075,.03)),BM["steel"],(-.045,1.04,-.222),(0,0,8))
addb("Tooth_R",box((.035,.075,.03)),BM["steel"],(.045,1.04,-.222),(0,0,-8))

# Asymmetric bucket helmet and violet patch.
addb("Helmet_Bucket",cyl(.265,.26),BM["bronze"],(0,1.38,0))
addb("Helmet_Band",box((.56,.065,.37)),BM["dark"],(0,1.28,-.01))
addb("Helmet_Patch",box((.17,.12,.028)),BM["violet"],(.105,1.43,-.265),(0,0,11))
addb("Helmet_Rivet_L",sphere(.025),BM["steel"],(-.13,1.43,-.278))
addb("Helmet_Rivet_R",sphere(.025),BM["steel"],(.20,1.40,-.278))

# Toe-stab knife.
addb("Knife_Grip",cyl(.038,.25),BM["dark"],(.42,.69,-.03),(0,0,-58))
addb("Knife_Guard",box((.18,.035,.045)),BM["bronze"],(.47,.61,-.03),(0,0,-58))
blade=trimesh.creation.cone(radius=.065,height=.30,sections=4)
blade.apply_transform(rotation_matrix(math.radians(90),(1,0,0)))
addb("Knife_Blade",blade,BM["steel"],(.54,.52,-.03),(0,0,-58))

black_target=OUT / "black_pawn_concept_v2.glb"
black_target.write_bytes(black_scene.export(file_type="glb"))
print(f"ASSET_BUILD_PASS {black_target} bytes={black_target.stat().st_size} parts={len(black_scene.geometry)}")


# ---------------------------------------------------------------------------
# White Knight — imported horse-and-rider GLB.
# ---------------------------------------------------------------------------
WK={
    "iv":pbr("KnightIvory","#e9e1d4",0.0,0.46),
    "ivs":pbr("KnightIvoryShadow","#c5b9aa",0.0,0.56),
    "blue":pbr("KnightBlue","#355d86",0.02,0.43),
    "gold":pbr("KnightGold","#c89b46",0.72,0.25),
    "leather":pbr("KnightLeather","#4b3328",0.0,0.70),
    "skin":pbr("KnightSkin","#d9a27b",0.0,0.56),
    "eye":pbr("HorseEyes","#26384f",0.0,0.18),
    "dark":pbr("KnightDark","#252127",0.0,0.45),
}
white_knight=trimesh.Scene()
def addwk(name,mesh,material,pos=(0,0,0),rot=(0,0,0),scale=(1,1,1)):
    mesh=mesh.copy(); mesh.apply_scale(scale)
    t=np.eye(4)
    for axis,deg in zip(((1,0,0),(0,1,0),(0,0,1)),rot):
        if deg: t=rotation_matrix(math.radians(deg),axis) @ t
    t[:3,3]=pos; mesh.apply_transform(t)
    mesh.visual=trimesh.visual.TextureVisuals(material=material)
    white_knight.add_geometry(mesh,geom_name=name,node_name=name)

addwk("PedestalLower",cyl(.45,.08),WK["dark"],(0,.04,0))
addwk("PedestalRing",cyl(.41,.05),WK["gold"],(0,.105,0))
addwk("PedestalUpper",cyl(.37,.10),WK["ivs"],(0,.18,0))
addwk("HorseBody",sphere(.35),WK["iv"],(0,.78,.04),scale=(1.08,.80,1.42))
for x in (-.20,.20):
    for z in (-.20,.21):
        addwk(f"Leg_{x}_{z}",capsule(.078,.55),WK["ivs"],(x,.47,z))
        addwk(f"Hoof_{x}_{z}",capsule(.10,.22),WK["leather"],(x,.25,z-.02),(90,0,0),(1.15,1,1.25))
addwk("Neck",capsule(.19,.66),WK["iv"],(0,1.10,-.25),(-28,0,0))
addwk("HorseHead",sphere(.25),WK["iv"],(0,1.36,-.50),scale=(.94,.80,1.34))
addwk("Muzzle",sphere(.17),WK["ivs"],(0,1.26,-.73),scale=(1,.72,1.18))
for i,x in enumerate((-.13,.13)):
    addwk(f"HorseEye_{i}",sphere(.035),WK["eye"],(x,1.42,-.65),scale=(1,.8,.55))
    addwk(f"Ear_{i}",sphere(.075),WK["iv"],(x,1.58,-.46),scale=(.62,1.5,.55))
addwk("Mane",box((.13,.60,.15)),WK["blue"],(0,1.30,-.23),(-18,0,0))
addwk("BridleBand",box((.39,.055,.055)),WK["gold"],(0,1.31,-.68))
addwk("Saddle",box((.48,.13,.56)),WK["leather"],(0,1.06,.14))
addwk("SaddleCloth",box((.54,.07,.65)),WK["blue"],(0,1.00,.15))

# Rider.
addwk("RiderTorso",capsule(.185,.50),WK["ivs"],(0,1.40,.14))
addwk("RiderHead",sphere(.155),WK["skin"],(0,1.72,.08))
addwk("RiderHelmet",sphere(.185),WK["ivs"],(0,1.80,.08),scale=(1,.66,1))
addwk("HelmetBand",box((.39,.055,.28)),WK["gold"],(0,1.75,.01))
addwk("Plume",box((.10,.32,.12)),WK["blue"],(0,2.01,.12),(0,0,-8))
for side in (-1,1):
    addwk(f"RiderArm_{side}",capsule(.058,.32),WK["ivs"],(.23*side,1.44,.08),(0,0,25*side))
    addwk(f"RiderHand_{side}",sphere(.065),WK["skin"],(.28*side,1.30,.02))
# Shield.
addwk("KnightShield",cyl(.21,.06),WK["blue"],(-.32,1.35,.03),(90,0,90))
addwk("ShieldStripe",box((.045,.27,.045)),WK["gold"],(-.355,1.35,.03))
# Lance.
addwk("Lance",cyl(.027,1.03),WK["leather"],(.33,1.45,-.25),(42,0,0))
ktip=trimesh.creation.cone(radius=.075,height=.20,sections=24)
ktip.apply_transform(rotation_matrix(math.radians(90),(1,0,0)))
addwk("LanceTip",ktip,WK["gold"],(.33,1.80,-.58),(42,0,0))

wk_target=OUT/"white_knight_concept_v2.glb"
wk_target.write_bytes(white_knight.export(file_type="glb"))
print(f"ASSET_BUILD_PASS {wk_target} bytes={wk_target.stat().st_size} parts={len(white_knight.geometry)}")

# ---------------------------------------------------------------------------
# Black Knight — nightmare horse + dark rider, distinct silhouette.
# ---------------------------------------------------------------------------
BK={
    "char":pbr("NightmareCharcoal","#2a2530",0.10,0.50),
    "black":pbr("NightmareBlack","#15151b",0.0,0.48),
    "bone":pbr("KnightBone","#9a948b",0.0,0.58),
    "violet":pbr("KnightViolet","#6d3f8c",0.08,0.40),
    "steel":pbr("KnightSteel","#57545e",0.60,0.30),
    "leather":pbr("KnightDarkLeather","#3a2927",0.0,0.72),
    "glow":pbr("KnightGlow","#b66bf0",0.0,0.16),
}
black_knight=trimesh.Scene()
def addbk(name,mesh,material,pos=(0,0,0),rot=(0,0,0),scale=(1,1,1)):
    mesh=mesh.copy(); mesh.apply_scale(scale)
    t=np.eye(4)
    for axis,deg in zip(((1,0,0),(0,1,0),(0,0,1)),rot):
        if deg: t=rotation_matrix(math.radians(deg),axis) @ t
    t[:3,3]=pos; mesh.apply_transform(t)
    mesh.visual=trimesh.visual.TextureVisuals(material=material)
    black_knight.add_geometry(mesh,geom_name=name,node_name=name)

addbk("PedestalLower",cyl(.45,.08),BK["black"],(0,.04,0))
addbk("PedestalRing",cyl(.41,.05),BK["violet"],(0,.105,0))
addbk("PedestalUpper",cyl(.37,.10),BK["char"],(0,.18,0))
addbk("HorseBody",sphere(.34),BK["char"],(0,.78,.04),scale=(1.04,.75,1.48))
for x in (-.20,.20):
    for z in (-.20,.21):
        addbk(f"Leg_{x}_{z}",capsule(.068,.57),BK["black"],(x,.47,z))
        addbk(f"Knee_{x}_{z}",sphere(.087),BK["bone"],(x,.53,z))
        addbk(f"Hoof_{x}_{z}",capsule(.108,.23),BK["black"],(x,.24,z-.03),(90,0,0),(1.2,1,1.3))
addbk("Neck",capsule(.18,.69),BK["char"],(0,1.10,-.26),(-30,0,0))
addbk("HorseHead",sphere(.24),BK["char"],(0,1.37,-.51),scale=(.90,.74,1.38))
addbk("Muzzle",sphere(.155),BK["black"],(0,1.27,-.75),scale=(1,.68,1.20))
for i,x in enumerate((-.13,.13)):
    addbk(f"Eye_{i}",sphere(.037),BK["glow"],(x,1.43,-.66),scale=(1,.76,.55))
addbk("Mane",box((.12,.64,.15)),BK["violet"],(0,1.30,-.22),(-20,0,0))
addbk("HorseHorn_L",cyl(.037,.27),BK["bone"],(-.13,1.60,-.47),(-30,0,-28))
addbk("HorseHorn_R",cyl(.037,.27),BK["bone"],(.13,1.60,-.47),(-30,0,28))
addbk("Saddle",box((.48,.13,.56)),BK["leather"],(0,1.06,.14))
addbk("SaddleCloth",box((.54,.07,.65)),BK["violet"],(0,1.00,.15))
# Rider.
addbk("RiderTorso",capsule(.185,.52),BK["steel"],(0,1.40,.14))
addbk("RiderHead",sphere(.15),BK["black"],(0,1.72,.08))
addbk("RiderHelmet",sphere(.185),BK["char"],(0,1.80,.08),scale=(1,.67,1))
addbk("HelmetHorn_L",cyl(.03,.28),BK["bone"],(-.14,1.94,.05),(0,0,-38))
addbk("HelmetHorn_R",cyl(.03,.28),BK["bone"],(.14,1.94,.05),(0,0,38))
for i,x in enumerate((-.055,.055)):
    addbk(f"VisorEye_{i}",sphere(.027),BK["glow"],(x,1.79,-.105),scale=(1,.75,.5))
for side in (-1,1):
    addbk(f"RiderArm_{side}",capsule(.058,.33),BK["steel"],(.23*side,1.44,.08),(0,0,27*side))
addbk("KnightShield",cyl(.21,.06),BK["char"],(-.32,1.35,.03),(90,0,90))
addbk("ShieldRune",box((.05,.27,.045)),BK["violet"],(-.355,1.35,.03),(0,0,18))
addbk("Lance",cyl(.027,1.03),BK["black"],(.33,1.45,-.25),(42,0,0))
btip=trimesh.creation.cone(radius=.078,height=.21,sections=4)
btip.apply_transform(rotation_matrix(math.radians(90),(1,0,0)))
addbk("LanceTip",btip,BK["violet"],(.33,1.80,-.58),(42,0,0))

bk_target=OUT/"black_knight_concept_v2.glb"
bk_target.write_bytes(black_knight.export(file_type="glb"))
print(f"ASSET_BUILD_PASS {bk_target} bytes={bk_target.stat().st_size} parts={len(black_knight.geometry)}")


# ---------------------------------------------------------------------------
# Remaining production GLBs. These are authored as named-part scenes so Godot
# imports actual assets now and Skeleton3D can replace part transforms later.
# ---------------------------------------------------------------------------
def emit(sc,name,mesh,mat,pos=(0,0,0),rot=(0,0,0),scale=(1,1,1)):
    mesh=mesh.copy(); mesh.apply_scale(scale)
    t=np.eye(4)
    for axis,deg in zip(((1,0,0),(0,1,0),(0,0,1)),rot):
        if deg: t=rotation_matrix(math.radians(deg),axis) @ t
    t[:3,3]=pos
    mesh.visual=trimesh.visual.TextureVisuals(material=mat)
    sc.add_geometry(mesh,geom_name=name,node_name=name,transform=t)

def export_scene(sc, filename):
    target=OUT/filename
    target.write_bytes(sc.export(file_type="glb"))
    print(f"ASSET_BUILD_PASS {target} bytes={target.stat().st_size} parts={len(sc.geometry)}")

# ---- Bishops ---------------------------------------------------------------
BIW={
 "iv":pbr("BishopIvory","#e7ddd0",0,0.52),"ivs":pbr("BishopShadow","#c8bbad",0,0.58),
 "gold":pbr("BishopGold","#c69a48",.68,.25),"blue":pbr("BishopBlue","#3f668a",0,.46),
 "skin":pbr("ElephantSkin","#b9a68f",0,.62),"dark":pbr("BishopDark","#252126",0,.48),
 "eye":pbr("BishopEye","#334559",0,.18),"wood":pbr("StaffWood","#5a3b2b",0,.70),
 "cyan":pbr("BishopGem","#5fc5d4",0,.14)
}
sc=trimesh.Scene()
emit(sc,"PedestalLower",cyl(.44,.08),BIW["dark"],(0,.04,0)); emit(sc,"PedestalRing",cyl(.40,.05),BIW["gold"],(0,.105,0)); emit(sc,"PedestalUpper",cyl(.36,.10),BIW["ivs"],(0,.18,0))
emit(sc,"Robe",cyl(.30,.78),BIW["iv"],(0,.58,0)); emit(sc,"Torso",capsule(.22,.58),BIW["ivs"],(0,1.00,0)); emit(sc,"Sash",box((.09,.74,.35)),BIW["blue"],(0,.78,-.18),(0,0,6)); emit(sc,"Collar",box((.50,.10,.36)),BIW["gold"],(0,1.23,0))
emit(sc,"Head",sphere(.235),BIW["skin"],(0,1.43,-.02),scale=(.96,1,.92))
emit(sc,"EarL",sphere(.205),BIW["ivs"],(-.24,1.44,-.01),scale=(.64,1.18,.52)); emit(sc,"EarR",sphere(.205),BIW["ivs"],(.24,1.44,-.01),scale=(.64,1.18,.52))
emit(sc,"Trunk",capsule(.067,.44),BIW["skin"],(0,1.25,-.25),(25,0,0))
emit(sc,"EyeL",sphere(.029),BIW["eye"],(-.08,1.48,-.225),scale=(1,.8,.55)); emit(sc,"EyeR",sphere(.029),BIW["eye"],(.08,1.48,-.225),scale=(1,.8,.55))
emit(sc,"MitreBase",box((.39,.20,.31)),BIW["ivs"],(0,1.66,0)); emit(sc,"MitreTall",box((.29,.48,.23)),BIW["iv"],(0,1.92,0),(0,0,8)); emit(sc,"MitreStripe",box((.058,.49,.028)),BIW["gold"],(0,1.92,-.135),(0,0,8))
for side in (-1,1):
    emit(sc,f"Arm_{side}",capsule(.076,.40),BIW["ivs"],(.29*side,1.08,0),(0,0,15*side)); emit(sc,f"Hand_{side}",sphere(.087),BIW["skin"],(.34*side,.90,-.02))
emit(sc,"Staff",cyl(.03,1.42),BIW["wood"],(.42,1.10,-.02),(0,0,-4)); emit(sc,"StaffGem",sphere(.11),BIW["cyan"],(.46,1.82,-.02)); emit(sc,"StaffCross",box((.30,.045,.045)),BIW["gold"],(.46,1.72,-.02))
export_scene(sc,"white_bishop_concept_v2.glb")

BIB={
 "char":pbr("NecroCharcoal","#26232c",.10,.52),"violet":pbr("NecroViolet","#654080",.05,.43),
 "bone":pbr("NecroBone","#9d9688",0,.58),"leather":pbr("NecroLeather","#3c2b2b",0,.70),
 "steel":pbr("NecroSteel","#56515b",.55,.30),"glow":pbr("NecroGlow","#b959ef",0,.14),
 "red":pbr("NecroRed","#7d3444",0,.46),"dark":pbr("NecroDark","#141218",0,.5)
}
sc=trimesh.Scene()
emit(sc,"PedestalLower",cyl(.44,.08),BIB["dark"],(0,.04,0)); emit(sc,"PedestalRing",cyl(.40,.05),BIB["violet"],(0,.105,0)); emit(sc,"PedestalUpper",cyl(.36,.10),BIB["steel"],(0,.18,0))
emit(sc,"Robe",cyl(.31,.80),BIB["char"],(0,.59,0)); emit(sc,"Torso",capsule(.22,.58),BIB["leather"],(0,1.01,0)); emit(sc,"RobePanel",box((.16,.76,.35)),BIB["violet"],(0,.78,-.18),(0,0,-5))
emit(sc,"Head",sphere(.225),BIB["bone"],(0,1.45,-.02),scale=(.91,1.05,.91)); emit(sc,"Snout",capsule(.07,.35),BIB["bone"],(0,1.31,-.24),(30,0,0))
emit(sc,"EyeL",sphere(.032),BIB["glow"],(-.078,1.50,-.22),scale=(1,.8,.55)); emit(sc,"EyeR",sphere(.032),BIB["glow"],(.078,1.50,-.22),scale=(1,.8,.55))
emit(sc,"HornL",cyl(.038,.43),BIB["bone"],(-.16,1.69,-.02),(0,0,-35)); emit(sc,"HornR",cyl(.038,.43),BIB["bone"],(.16,1.69,-.02),(0,0,35))
emit(sc,"Mask",box((.37,.25,.26)),BIB["char"],(0,1.67,0)); emit(sc,"MaskRune",box((.055,.27,.03)),BIB["red"],(0,1.67,-.15))
for side in (-1,1): emit(sc,f"Arm_{side}",capsule(.076,.42),BIB["leather"],(.29*side,1.07,0),(0,0,17*side))
emit(sc,"Staff",cyl(.031,1.44),BIB["steel"],(.42,1.10,-.02),(0,0,-4)); emit(sc,"StaffOrb",sphere(.115),BIB["glow"],(.46,1.84,-.02))
emit(sc,"ProngL",box((.045,.30,.05)),BIB["bone"],(.37,1.86,-.02),(0,0,-28)); emit(sc,"ProngR",box((.045,.30,.05)),BIB["bone"],(.55,1.86,-.02),(0,0,28))
export_scene(sc,"black_bishop_concept_v2.glb")

# ---- Rooks -----------------------------------------------------------------
RW={
 "stone":pbr("RookStone","#b9b1a6",0,.78),"light":pbr("RookStoneLight","#d6cec2",0,.72),
 "shadow":pbr("RookStoneShadow","#817a73",0,.82),"gold":pbr("RookGold","#bd9141",.66,.27),
 "blue":pbr("RookBlue","#42698c",0,.50),"eye":pbr("RookEye","#6fd0df",0,.14),"dark":pbr("RookDark","#2a2728",0,.52)
}
sc=trimesh.Scene()
emit(sc,"PedestalLower",cyl(.48,.09),RW["dark"],(0,.045,0)); emit(sc,"PedestalRing",cyl(.44,.05),RW["gold"],(0,.115,0)); emit(sc,"PedestalUpper",cyl(.40,.10),RW["shadow"],(0,.19,0))
emit(sc,"TowerCore",box((.64,.96,.64)),RW["stone"],(0,.76,0)); emit(sc,"Chest",box((.70,.29,.70)),RW["light"],(0,.98,-.03)); emit(sc,"Belt",box((.70,.10,.70)),RW["gold"],(0,.53,0))
for side in (-1,1):
    emit(sc,f"Shoulder_{side}",box((.30,.26,.36)),RW["shadow"],(.45*side,.99,0),(0,0,11*side)); emit(sc,f"Arm_{side}",box((.21,.50,.23)),RW["stone"],(.50*side,.72,0),(0,0,9*side)); emit(sc,f"Fist_{side}",box((.30,.26,.30)),RW["shadow"],(.55*side,.45,-.02))
emit(sc,"EyeL",sphere(.058),RW["eye"],(-.15,1.05,-.36),scale=(1.25,.72,.55)); emit(sc,"EyeR",sphere(.058),RW["eye"],(.15,1.05,-.36),scale=(1.25,.72,.55)); emit(sc,"Mouth",box((.31,.065,.06)),RW["dark"],(0,.88,-.36))
emit(sc,"CrownBase",box((.82,.18,.82)),RW["light"],(0,1.34,0))
for x in (-.30,0,.30):
    emit(sc,f"CrenelF{x}",box((.18,.25,.21)),RW["stone"],(x,1.54,-.30)); emit(sc,f"CrenelB{x}",box((.18,.25,.21)),RW["stone"],(x,1.54,.30))
emit(sc,"Heraldry",box((.27,.31,.04)),RW["blue"],(0,.73,-.34)); emit(sc,"HeraldryV",box((.05,.25,.045)),RW["gold"],(0,.73,-.37)); emit(sc,"HeraldryH",box((.21,.05,.045)),RW["gold"],(0,.73,-.37))
export_scene(sc,"white_rook_concept_v2.glb")

RB={
 "obs":pbr("Obsidian","#242127",.15,.40),"obsl":pbr("ObsidianEdge","#3a343c",.18,.46),
 "lava":pbr("Lava","#e56a28",0,.18),"ember":pbr("Ember","#f0a13a",0,.12),
 "steel":pbr("RookSteel","#5a4d52",.48,.32),"violet":pbr("RookViolet","#5c3c74",0,.45),"dark":pbr("RookBlack","#121216",0,.50)
}
sc=trimesh.Scene()
emit(sc,"PedestalLower",cyl(.48,.09),RB["dark"],(0,.045,0)); emit(sc,"PedestalRing",cyl(.44,.05),RB["lava"],(0,.115,0)); emit(sc,"PedestalUpper",cyl(.40,.10),RB["obs"],(0,.19,0))
emit(sc,"TowerCore",box((.65,.97,.65)),RB["obs"],(0,.76,0)); emit(sc,"Chest",box((.71,.29,.71)),RB["obsl"],(0,.98,-.03)); emit(sc,"CrackV",box((.06,.66,.04)),RB["lava"],(-.10,.78,-.34),(0,0,12)); emit(sc,"CrackH",box((.35,.05,.04)),RB["ember"],(.03,.75,-.342),(0,0,-16))
for side in (-1,1):
    emit(sc,f"Shoulder_{side}",box((.31,.27,.37)),RB["steel"],(.46*side,1.0,0),(0,0,12*side)); emit(sc,f"Arm_{side}",box((.21,.51,.23)),RB["obsl"],(.51*side,.72,0),(0,0,10*side)); emit(sc,f"Fist_{side}",box((.31,.27,.31)),RB["obs"],(.56*side,.44,-.02))
emit(sc,"EyeL",sphere(.06),RB["ember"],(-.15,1.05,-.37),scale=(1.25,.70,.55)); emit(sc,"EyeR",sphere(.06),RB["ember"],(.15,1.05,-.37),scale=(1.25,.70,.55)); emit(sc,"Mouth",box((.32,.07,.06)),RB["lava"],(0,.88,-.37))
emit(sc,"CrownBase",box((.83,.18,.83)),RB["obsl"],(0,1.35,0))
for x in (-.30,0,.30):
    emit(sc,f"CrenelF{x}",box((.18,.26,.21)),RB["obs"],(x,1.55,-.30)); emit(sc,f"CrenelB{x}",box((.18,.26,.21)),RB["obs"],(x,1.55,.30))
emit(sc,"RunePlate",box((.28,.32,.04)),RB["violet"],(0,.73,-.35)); emit(sc,"RuneV",box((.05,.26,.045)),RB["lava"],(0,.73,-.38),(0,0,20))
export_scene(sc,"black_rook_concept_v2.glb")

# ---- Queens ----------------------------------------------------------------
QW={
 "iv":pbr("QueenIvory","#eee5d7",0,.48),"ivs":pbr("QueenShadow","#cbbdad",0,.56),
 "gold":pbr("QueenGold","#c89c49",.72,.24),"blue":pbr("QueenBlue","#416b91",0,.44),
 "skin":pbr("QueenSkin","#d8a07d",0,.55),"hair":pbr("QueenHair","#a4774f",0,.58),
 "dark":pbr("QueenDark","#262228",0,.46),"cyan":pbr("QueenMagic","#70ddf2",0,.12)
}
sc=trimesh.Scene()
emit(sc,"PedestalLower",cyl(.45,.08),QW["dark"],(0,.04,0)); emit(sc,"PedestalRing",cyl(.41,.05),QW["gold"],(0,.105,0)); emit(sc,"PedestalUpper",cyl(.37,.10),QW["ivs"],(0,.18,0))
emit(sc,"Skirt",cyl(.35,.86),QW["iv"],(0,.61,0)); emit(sc,"SkirtBand",cyl(.36,.06),QW["gold"],(0,.31,0)); emit(sc,"Torso",capsule(.215,.60),QW["ivs"],(0,1.10,0)); emit(sc,"Corset",box((.27,.44,.06)),QW["blue"],(0,1.08,-.23))
emit(sc,"Head",sphere(.195),QW["skin"],(0,1.57,-.01),scale=(.95,1.06,.92)); emit(sc,"Hair",sphere(.225),QW["hair"],(0,1.58,.11),scale=(1.06,1.15,.90))
for i,x in enumerate((-.067,.067)): emit(sc,f"Eye_{i}",sphere(.026),QW["blue"],(x,1.61,-.195),scale=(1,.8,.55))
emit(sc,"CrownBand",cyl(.205,.10),QW["gold"],(0,1.79,0))
for x in (-.13,0,.13): emit(sc,f"CrownPoint{x}",box((.08,.31 if x==0 else .24,.08)),QW["gold"],(x,1.96 if x==0 else 1.91,0),(0,0,x*45))
for side in (-1,1): emit(sc,f"Arm_{side}",capsule(.07,.44),QW["ivs"],(.29*side,1.14,0),(0,0,23*side)); emit(sc,f"Hand_{side}",sphere(.08),QW["skin"],(.35*side,.94,-.03))
emit(sc,"Staff",cyl(.028,1.35),QW["gold"],(.44,1.14,-.03),(0,0,-3)); emit(sc,"MagicOrb",sphere(.135),QW["cyan"],(.47,1.84,-.03)); emit(sc,"OrbHaloV",box((.038,.36,.038)),QW["gold"],(.47,1.84,-.03)); emit(sc,"OrbHaloH",box((.36,.038,.038)),QW["gold"],(.47,1.84,-.03))
export_scene(sc,"white_queen_concept_v2.glb")

QB={
 "char":pbr("DarkQueenCharcoal","#24212b",0,.50),"violet":pbr("DarkQueenViolet","#68407f",0,.42),
 "vd":pbr("DarkQueenDeep","#402a50",0,.50),"steel":pbr("DarkQueenSteel","#5b5361",.52,.30),
 "skin":pbr("DarkQueenSkin","#9b839c",0,.55),"hair":pbr("DarkQueenHair","#211a28",0,.52),
 "magic":pbr("DarkQueenMagic","#d05bea",0,.12),"red":pbr("DarkQueenRed","#7c334d",0,.45),"dark":pbr("DarkQueenBlack","#111116",0,.48)
}
sc=trimesh.Scene()
emit(sc,"PedestalLower",cyl(.45,.08),QB["dark"],(0,.04,0)); emit(sc,"PedestalRing",cyl(.41,.05),QB["magic"],(0,.105,0)); emit(sc,"PedestalUpper",cyl(.37,.10),QB["char"],(0,.18,0))
emit(sc,"Skirt",cyl(.36,.87),QB["char"],(0,.62,0)); emit(sc,"SkirtPanel",box((.29,.74,.06)),QB["violet"],(0,.65,-.32),(0,0,-5)); emit(sc,"Torso",capsule(.215,.60),QB["vd"],(0,1.11,0)); emit(sc,"Chest",box((.39,.31,.065)),QB["steel"],(0,1.14,-.23))
emit(sc,"Head",sphere(.195),QB["skin"],(0,1.58,-.01),scale=(.93,1.08,.90)); emit(sc,"Hair",sphere(.235),QB["hair"],(0,1.58,.12),scale=(1.08,1.22,.92))
for i,x in enumerate((-.067,.067)): emit(sc,f"Eye_{i}",sphere(.027),QB["magic"],(x,1.62,-.195),scale=(1,.8,.55))
emit(sc,"CrownBand",cyl(.205,.10),QB["steel"],(0,1.80,0)); emit(sc,"CrownHornL",cyl(.034,.36),QB["char"],(-.14,1.98,0),(0,0,-30)); emit(sc,"CrownHornR",cyl(.034,.36),QB["char"],(.14,1.98,0),(0,0,30)); emit(sc,"CrownGem",sphere(.058),QB["magic"],(0,1.86,-.20))
for side in (-1,1): emit(sc,f"Arm_{side}",capsule(.07,.44),QB["vd"],(.29*side,1.14,0),(0,0,24*side))
emit(sc,"Staff",cyl(.03,1.36),QB["steel"],(.44,1.14,-.03),(0,0,-4)); emit(sc,"MagicOrb",sphere(.14),QB["magic"],(.48,1.85,-.03)); emit(sc,"ProngL",box((.04,.36,.04)),QB["char"],(.37,1.85,-.03),(0,0,-30)); emit(sc,"ProngR",box((.04,.36,.04)),QB["char"],(.59,1.85,-.03),(0,0,30))
export_scene(sc,"black_queen_concept_v2.glb")

# ---- Kings -----------------------------------------------------------------
KW={
 "iv":pbr("KingIvory","#eee4d6",0,.50),"ivs":pbr("KingShadow","#c9baaa",0,.58),
 "gold":pbr("KingGold","#c99b45",.74,.23),"blue":pbr("KingBlue","#3b6288",0,.45),
 "red":pbr("KingRed","#8a3d43",0,.48),"skin":pbr("KingSkin","#d49b75",0,.56),
 "beard":pbr("KingBeard","#e6dfd2",0,.68),"dark":pbr("KingDark","#2b2526",0,.50),
 "eye":pbr("KingEye","#33465a",0,.18),"gem":pbr("KingGem","#58c5d8",0,.12)
}
sc=trimesh.Scene()
emit(sc,"PedestalLower",cyl(.47,.08),KW["dark"],(0,.04,0)); emit(sc,"PedestalRing",cyl(.43,.05),KW["gold"],(0,.115,0)); emit(sc,"PedestalUpper",cyl(.39,.10),KW["ivs"],(0,.19,0))
emit(sc,"Robe",cyl(.37,.82),KW["iv"],(0,.61,0)); emit(sc,"Belly",sphere(.31),KW["red"],(0,.98,-.02),scale=(1.08,.92,.92)); emit(sc,"Torso",capsule(.245,.58),KW["ivs"],(0,1.18,0)); emit(sc,"Sash",box((.12,.78,.36)),KW["blue"],(.06,.96,-.19),(0,0,-12)); emit(sc,"Belt",box((.66,.10,.35)),KW["gold"],(0,.82,0))
emit(sc,"Head",sphere(.225),KW["skin"],(0,1.57,-.02)); emit(sc,"Nose",sphere(.062),KW["skin"],(0,1.54,-.24),scale=(.95,.78,1.25)); emit(sc,"Beard",sphere(.225),KW["beard"],(0,1.37,-.17),scale=(.96,1.20,.72))
emit(sc,"MoustacheL",sphere(.078),KW["beard"],(-.07,1.50,-.24),scale=(1.35,.52,.65)); emit(sc,"MoustacheR",sphere(.078),KW["beard"],(.07,1.50,-.24),scale=(1.35,.52,.65))
for i,x in enumerate((-.078,.078)): emit(sc,f"Eye_{i}",sphere(.027),KW["eye"],(x,1.62,-.23),scale=(1,.8,.55))
emit(sc,"CrownBand",cyl(.235,.12),KW["gold"],(0,1.79,0))
for x in (-.16,-.05,.05,.16): emit(sc,f"Crown{x}",box((.072,.32 if abs(x)<.1 else .25,.072)),KW["gold"],(x,1.98 if abs(x)<.1 else 1.93,0),(0,0,x*50))
emit(sc,"CrownGem",sphere(.062),KW["gem"],(0,1.86,-.22))
for side in (-1,1): emit(sc,f"Cape_{side}",box((.19,.72,.11)),KW["red"],(.28*side,1.13,.19),(0,0,-8*side)); emit(sc,f"Arm_{side}",capsule(.078,.44),KW["ivs"],(.33*side,1.17,0),(0,0,17*side))
emit(sc,"Scepter",cyl(.028,1.00),KW["gold"],(-.44,1.17,-.02),(0,0,5)); emit(sc,"ScepterGem",sphere(.10),KW["gem"],(-.48,1.68,-.02))
export_scene(sc,"white_king_concept_v2.glb")

KB={
 "char":pbr("DemonCharcoal","#242029",0,.50),"armor":pbr("DemonArmor","#514a55",.52,.31),
 "red":pbr("DemonRed","#87363d",0,.43),"crimson":pbr("DemonCrimson","#b63c35",0,.40),
 "skin":pbr("DemonSkin","#9a493e",0,.55),"horn":pbr("DemonHorn","#8d8173",0,.58),
 "violet":pbr("DemonViolet","#694080",0,.42),"glow":pbr("DemonGlow","#e16a45",0,.12),
 "dark":pbr("DemonBlack","#111116",0,.48)
}
sc=trimesh.Scene()
emit(sc,"PedestalLower",cyl(.47,.08),KB["dark"],(0,.04,0)); emit(sc,"PedestalRing",cyl(.43,.05),KB["crimson"],(0,.115,0)); emit(sc,"PedestalUpper",cyl(.39,.10),KB["char"],(0,.19,0))
emit(sc,"Robe",cyl(.38,.83),KB["char"],(0,.62,0)); emit(sc,"BellyArmor",sphere(.32),KB["armor"],(0,.98,-.02),scale=(1.10,.90,.90)); emit(sc,"Torso",capsule(.255,.60),KB["red"],(0,1.19,0)); emit(sc,"Chest",box((.50,.33,.07)),KB["armor"],(0,1.19,-.26))
for side in (-1,1): emit(sc,f"Cape_{side}",box((.21,.78,.12)),KB["violet"],(.30*side,1.15,.20),(0,0,-10*side)); emit(sc,f"Arm_{side}",capsule(.08,.45),KB["red"],(.34*side,1.18,0),(0,0,18*side))
emit(sc,"Head",sphere(.225),KB["skin"],(0,1.59,-.02)); emit(sc,"Nose",sphere(.058),KB["skin"],(0,1.56,-.235),scale=(.9,.75,1.2))
for i,x in enumerate((-.08,.08)): emit(sc,f"Eye_{i}",sphere(.032),KB["glow"],(x,1.64,-.23),scale=(1,.8,.55))
emit(sc,"FangL",box((.038,.13,.038)),KB["horn"],(-.06,1.45,-.23),(0,0,8)); emit(sc,"FangR",box((.038,.13,.038)),KB["horn"],(.06,1.45,-.23),(0,0,-8))
emit(sc,"CrownBand",cyl(.235,.12),KB["armor"],(0,1.81,0)); emit(sc,"CrownHornL",cyl(.04,.47),KB["horn"],(-.18,2.01,0),(0,0,-34)); emit(sc,"CrownHornR",cyl(.04,.47),KB["horn"],(.18,2.01,0),(0,0,34)); emit(sc,"CrownCenter",box((.095,.36,.095)),KB["crimson"],(0,2.01,0)); emit(sc,"CrownGem",sphere(.062),KB["glow"],(0,1.88,-.22))
emit(sc,"Scepter",cyl(.03,1.02),KB["armor"],(-.45,1.18,-.02),(0,0,5)); emit(sc,"ScepterCore",sphere(.105),KB["glow"],(-.49,1.70,-.02)); emit(sc,"ScepterRune",box((.19,.19,.04)),KB["violet"],(-.49,1.70,-.02),(0,0,45))
export_scene(sc,"black_king_concept_v2.glb")


# ---------------------------------------------------------------------------
# Concept-sheet integration pass v2
# Adds the strong silhouette, cloth, heraldry, hair/plume, fur and ornament
# layers visible in the approved Battle Chess Revival character sheets.
# This runs after the base modular GLBs are authored and overwrites the same
# concept_v2 files with additional named, animation-friendly parts.
# ---------------------------------------------------------------------------
def _polish_scene(filename, callback):
    path = OUT / filename
    sc = trimesh.load(path, force="scene", process=False)
    callback(sc)
    path.write_bytes(sc.export(file_type="glb"))
    print(f"CONCEPT_POLISH_PASS {path} parts={len(sc.geometry)}")

def _addp(sc,name,mesh,mat,pos=(0,0,0),rot=(0,0,0),scale=(1,1,1)):
    mesh=mesh.copy()
    mesh.apply_scale(scale)
    t=np.eye(4)
    for axis,deg in zip(((1,0,0),(0,1,0),(0,0,1)),rot):
        if deg:
            t=rotation_matrix(math.radians(deg),axis) @ t
    t[:3,3]=pos
    mesh.visual=trimesh.visual.TextureVisuals(material=mat)
    sc.add_geometry(mesh,geom_name=name,node_name=name,transform=t)

CIV=pbr("ConceptIvory","#f0e6d7",0.0,0.42)
CGOLD=pbr("ConceptPolishedGold","#d4a84f",0.76,0.20)
CBLUE=pbr("ConceptRoyalBlue","#244f92",0.02,0.40)
CRED=pbr("ConceptCrimson","#8d243d",0.03,0.40)
CCHAR=pbr("ConceptCharcoal","#232129",0.15,0.40)
CBRONZE=pbr("ConceptBronze","#8d6237",0.55,0.30)
CGREEN=pbr("ConceptGoblinSkin","#7e914f",0.0,0.54)
CPINK=pbr("ConceptInnerEar","#d58e92",0.0,0.58)
CPURPLE=pbr("ConceptPurple","#6e2f83",0.02,0.38)
CLAVA=pbr("ConceptLava","#ef6227",0.0,0.16)
CFUR=pbr("ConceptFur","#e9e0d4",0.0,0.82)
CBLACKFUR=pbr("ConceptBlackFur","#201d24",0.0,0.82)
CHAIR=pbr("ConceptHair","#6f4a31",0.0,0.58)
CDARKHAIR=pbr("ConceptDarkHair","#241b28",0.0,0.52)
CMAGENTA=pbr("ConceptMagicMagenta","#d847df",0.0,0.14)
CCYAN=pbr("ConceptMagicCyan","#63dff2",0.0,0.14)

def polish_white_pawn(sc):
    _addp(sc,"Concept_Tabard",box((.28,.42,.045)),CBLUE,(0,.79,-.29))
    _addp(sc,"Concept_TabardGoldV",box((.045,.38,.052)),CGOLD,(0,.79,-.318))
    _addp(sc,"Concept_TabardGoldH",box((.22,.045,.052)),CGOLD,(0,.67,-.318))
    _addp(sc,"Concept_ShoulderTrim_L",box((.26,.07,.18)),CGOLD,(-.30,.97,-.02),(0,0,-12))
    _addp(sc,"Concept_ShoulderTrim_R",box((.26,.07,.18)),CGOLD,(.30,.97,-.02),(0,0,12))
    for i,(y,s) in enumerate(((1.59,(1.00,.75,1.00)),(1.70,(.88,.70,.92)),(1.80,(.68,.58,.78)))):
        _addp(sc,f"Concept_Plume_{i}",sphere(.115),CBLUE,(0,y,.04),scale=s)
    _addp(sc,"Concept_Cheek_L",sphere(.045),M["skin"],(-.11,1.15,-.23),scale=(1.15,.75,.55))
    _addp(sc,"Concept_Cheek_R",sphere(.045),M["skin"],(.11,1.15,-.23),scale=(1.15,.75,.55))
    _addp(sc,"Concept_BootGold_L",box((.23,.055,.22)),CGOLD,(-.14,.27,-.02))
    _addp(sc,"Concept_BootGold_R",box((.23,.055,.22)),CGOLD,(.14,.27,-.02))

def polish_black_pawn(sc):
    _addp(sc,"Concept_Tabard",box((.29,.43,.045)),CRED,(0,.78,-.29),(0,0,-3))
    _addp(sc,"Concept_TabardGold",box((.05,.39,.052)),CBRONZE,(0,.78,-.318),(0,0,-3))
    for i,(y,x,s) in enumerate(((1.57,-.02,(1.05,.76,1.0)),(1.69,-.05,(.92,.70,.95)),(1.80,-.08,(.72,.58,.82)))):
        _addp(sc,f"Concept_Plume_{i}",sphere(.12),CRED,(x,y,.04),scale=s)
    _addp(sc,"Concept_Cape",box((.42,.45,.055)),CRED,(0,.78,.19),(10,0,0))
    _addp(sc,"Concept_ShoulderSpike_L",trimesh.creation.cone(radius=.06,height=.20,sections=8),CBRONZE,(-.34,1.02,-.02),(0,0,-35))
    _addp(sc,"Concept_ShoulderSpike_R",trimesh.creation.cone(radius=.06,height=.20,sections=8),CBRONZE,(.34,1.02,-.02),(0,0,35))
    _addp(sc,"Concept_EarInner_L",sphere(.085),CPINK,(-.29,1.18,-.03),scale=(1.35,.32,.48))
    _addp(sc,"Concept_EarInner_R",sphere(.085),CPINK,(.29,1.18,-.03),scale=(1.35,.32,.48))
    _addp(sc,"Concept_BackSpear",cyl(.024,.88),CBRONZE,(-.29,.96,.18),(-12,0,8))

def polish_white_knight(sc):
    _addp(sc,"Concept_HorseFace",sphere(.19),CIV,(0,1.33,-.69),scale=(.82,.62,.55))
    _addp(sc,"Concept_HorseNostril_L",sphere(.025),WK["dark"],(-.06,1.28,-.84),scale=(1,.7,.45))
    _addp(sc,"Concept_HorseNostril_R",sphere(.025),WK["dark"],(.06,1.28,-.84),scale=(1,.7,.45))
    _addp(sc,"Concept_HorseBardingFront",box((.38,.34,.07)),CBLUE,(0,.87,-.46),(10,0,0))
    _addp(sc,"Concept_HorseBardingGold",box((.07,.30,.075)),CGOLD,(0,.87,-.50),(10,0,0))
    _addp(sc,"Concept_RiderTabard",box((.22,.33,.04)),CBLUE,(0,1.42,-.07))
    _addp(sc,"Concept_RiderTabardGold",box((.045,.29,.046)),CGOLD,(0,1.42,-.095))
    _addp(sc,"Concept_RiderFace",sphere(.12),WK["skin"],(0,1.72,-.07),scale=(1,.92,.70))
    for i,(y,s) in enumerate(((2.03,(1.0,.65,1.0)),(2.13,(.85,.60,.90)),(2.22,(.68,.52,.78)))):
        _addp(sc,f"Concept_Plume_{i}",sphere(.10),CBLUE,(0,y,.12),scale=s)

def polish_black_knight(sc):
    _addp(sc,"Concept_HorseArmorFront",box((.40,.36,.075)),CCHAR,(0,.88,-.47),(10,0,0))
    _addp(sc,"Concept_HorseArmorRune",box((.07,.31,.08)),CRED,(0,.88,-.515),(10,0,0))
    _addp(sc,"Concept_RiderFace",sphere(.12),CGREEN,(0,1.72,-.07),scale=(1,.92,.70))
    _addp(sc,"Concept_RiderTabard",box((.23,.34,.04)),CRED,(0,1.42,-.07))
    for i,(y,s) in enumerate(((2.03,(1.05,.66,1.0)),(2.14,(.90,.60,.92)),(2.24,(.70,.52,.80)))):
        _addp(sc,f"Concept_RedPlume_{i}",sphere(.105),CRED,(0,y,.12),scale=s)
    _addp(sc,"Concept_Cape",box((.43,.46,.05)),CRED,(0,1.31,.26),(12,0,0))
    _addp(sc,"Concept_EyeGlow_L",sphere(.032),CMAGENTA,(-.06,1.75,-.18),scale=(1,.75,.5))
    _addp(sc,"Concept_EyeGlow_R",sphere(.032),CMAGENTA,(.06,1.75,-.18),scale=(1,.75,.5))

def polish_white_bishop(sc):
    _addp(sc,"Concept_RobeFront",box((.32,.68,.045)),CIV,(0,.78,-.31))
    _addp(sc,"Concept_RobeBlue",box((.13,.62,.052)),CBLUE,(0,.78,-.34))
    _addp(sc,"Concept_RobeGold",box((.045,.58,.058)),CGOLD,(0,.78,-.37))
    _addp(sc,"Concept_InnerEar_L",sphere(.16),CPINK,(-.25,1.44,-.02),scale=(.56,1.08,.30))
    _addp(sc,"Concept_InnerEar_R",sphere(.16),CPINK,(.25,1.44,-.02),scale=(.56,1.08,.30))
    _addp(sc,"Concept_Cape",box((.48,.66,.045)),CBLUE,(0,1.00,.24),(8,0,0))
    _addp(sc,"Concept_ChestGem",sphere(.065),CCYAN,(0,1.20,-.34))
    _addp(sc,"Concept_StaffHalo",cyl(.12,.025),CGOLD,(.46,1.82,-.02),(90,0,0))

def polish_black_bishop(sc):
    _addp(sc,"Concept_RobeFront",box((.34,.70,.045)),CCHAR,(0,.78,-.32))
    _addp(sc,"Concept_RobePurple",box((.14,.65,.052)),CPURPLE,(0,.78,-.35))
    _addp(sc,"Concept_Cape",box((.52,.70,.05)),CRED,(0,1.00,.25),(10,0,0))
    _addp(sc,"Concept_Skull",sphere(.085),BIB["bone"],(0,1.08,-.36),scale=(1,.86,.72))
    _addp(sc,"Concept_SkullEye_L",sphere(.018),CCHAR,(-.025,1.09,-.43))
    _addp(sc,"Concept_SkullEye_R",sphere(.018),CCHAR,(.025,1.09,-.43))
    _addp(sc,"Concept_OrbHalo",cyl(.14,.025),CMAGENTA,(.46,1.84,-.02),(90,0,0))
    _addp(sc,"Concept_InnerEar_L",sphere(.15),CPINK,(-.24,1.45,-.02),scale=(.55,1.0,.30))
    _addp(sc,"Concept_InnerEar_R",sphere(.15),CPINK,(.24,1.45,-.02),scale=(.55,1.0,.30))

def polish_white_rook(sc):
    _addp(sc,"Concept_Tabard",box((.29,.50,.05)),CBLUE,(0,.77,-.37))
    _addp(sc,"Concept_TabardGoldV",box((.05,.45,.055)),CGOLD,(0,.77,-.40))
    _addp(sc,"Concept_TabardGoldH",box((.22,.05,.055)),CGOLD,(0,.60,-.40))
    _addp(sc,"Concept_ShoulderGold_L",box((.31,.075,.37)),CGOLD,(-.45,1.04,0),(0,0,-11))
    _addp(sc,"Concept_ShoulderGold_R",box((.31,.075,.37)),CGOLD,(.45,1.04,0),(0,0,11))
    _addp(sc,"Concept_Brow_L",box((.19,.06,.05)),RW["shadow"],(-.15,1.10,-.39),(0,0,-14))
    _addp(sc,"Concept_Brow_R",box((.19,.06,.05)),RW["shadow"],(.15,1.10,-.39),(0,0,14))

def polish_black_rook(sc):
    _addp(sc,"Concept_Tabard",box((.30,.51,.05)),CRED,(0,.77,-.38))
    _addp(sc,"Concept_TabardGold",box((.05,.46,.055)),CBRONZE,(0,.77,-.41))
    for x,y,ang in ((-.18,.74,14),(.11,.87,-18),(.22,.61,9)):
        _addp(sc,f"Concept_LavaCrack_{x}_{y}",box((.035,.30,.035)),CLAVA,(x,y,-.382),(0,0,ang))
    _addp(sc,"Concept_ShoulderSpike_L",trimesh.creation.cone(radius=.07,height=.22,sections=8),CCHAR,(-.50,1.12,-.02),(0,0,-35))
    _addp(sc,"Concept_ShoulderSpike_R",trimesh.creation.cone(radius=.07,height=.22,sections=8),CCHAR,(.50,1.12,-.02),(0,0,35))

def polish_white_queen(sc):
    _addp(sc,"Concept_SkirtBlue",box((.29,.70,.045)),CBLUE,(0,.67,-.34))
    _addp(sc,"Concept_SkirtGoldV",box((.05,.64,.052)),CGOLD,(0,.67,-.37))
    _addp(sc,"Concept_Cape_L",box((.24,.68,.04)),CIV,(-.30,1.02,.24),(0,0,-9))
    _addp(sc,"Concept_Cape_R",box((.24,.68,.04)),CIV,(.30,1.02,.24),(0,0,9))
    for side in (-1,1):
        _addp(sc,f"Concept_HairCurl_{side}",sphere(.13),CHAIR,(.20*side,1.48,.12),scale=(.75,1.55,.75))
        _addp(sc,f"Concept_Earring_{side}",sphere(.035),CCYAN,(.16*side,1.48,-.04))
    _addp(sc,"Concept_CrownGem",sphere(.07),CCYAN,(0,1.91,-.13))
    _addp(sc,"Concept_StaffRing",cyl(.16,.022),CGOLD,(.47,1.84,-.03),(90,0,0))

def polish_black_queen(sc):
    _addp(sc,"Concept_SkirtMagenta",box((.30,.72,.045)),CMAGENTA,(0,.68,-.35))
    _addp(sc,"Concept_SkirtGold",box((.05,.66,.052)),CBRONZE,(0,.68,-.38))
    _addp(sc,"Concept_Cape_L",box((.25,.70,.04)),CPURPLE,(-.31,1.03,.25),(0,0,-10))
    _addp(sc,"Concept_Cape_R",box((.25,.70,.04)),CPURPLE,(.31,1.03,.25),(0,0,10))
    for side in (-1,1):
        _addp(sc,f"Concept_HairCurl_{side}",sphere(.14),CDARKHAIR,(.20*side,1.49,.13),scale=(.78,1.58,.78))
    _addp(sc,"Concept_CrownGem",sphere(.072),CMAGENTA,(0,1.92,-.13))
    _addp(sc,"Concept_StaffRing",cyl(.17,.022),CMAGENTA,(.48,1.85,-.03),(90,0,0))

def polish_white_king(sc):
    for side in (-1,1):
        _addp(sc,f"Concept_FurShoulder_{side}",sphere(.22),CFUR,(.26*side,1.31,.09),scale=(1.10,.72,.88))
    _addp(sc,"Concept_FurCollar",box((.58,.15,.32)),CFUR,(0,1.34,.04))
    _addp(sc,"Concept_Cape",box((.58,.78,.05)),CBLUE,(0,1.03,.28),(9,0,0))
    _addp(sc,"Concept_CapeGold",box((.08,.70,.055)),CGOLD,(0,1.03,.31),(9,0,0))
    _addp(sc,"Concept_CrownBlueGem",sphere(.075),CBLUE,(0,1.90,-.20))
    _addp(sc,"Concept_ScepterOrb",sphere(.12),CBLUE,(-.48,1.70,-.02))

def polish_black_king(sc):
    for side in (-1,1):
        _addp(sc,f"Concept_FurShoulder_{side}",sphere(.23),CBLACKFUR,(.27*side,1.32,.10),scale=(1.12,.74,.90))
    _addp(sc,"Concept_FurCollar",box((.61,.16,.34)),CBLACKFUR,(0,1.35,.05))
    _addp(sc,"Concept_Cape",box((.60,.80,.05)),CRED,(0,1.04,.29),(10,0,0))
    _addp(sc,"Concept_CapeGold",box((.08,.72,.055)),CBRONZE,(0,1.04,.32),(10,0,0))
    _addp(sc,"Concept_CrownRedGem",sphere(.078),CRED,(0,1.92,-.21))
    _addp(sc,"Concept_ScepterCrystal",sphere(.125),CRED,(-.49,1.71,-.02))

_POLISHERS = {
    "white_pawn_concept_v2.glb": polish_white_pawn,
    "black_pawn_concept_v2.glb": polish_black_pawn,
    "white_knight_concept_v2.glb": polish_white_knight,
    "black_knight_concept_v2.glb": polish_black_knight,
    "white_bishop_concept_v2.glb": polish_white_bishop,
    "black_bishop_concept_v2.glb": polish_black_bishop,
    "white_rook_concept_v2.glb": polish_white_rook,
    "black_rook_concept_v2.glb": polish_black_rook,
    "white_queen_concept_v2.glb": polish_white_queen,
    "black_queen_concept_v2.glb": polish_black_queen,
    "white_king_concept_v2.glb": polish_white_king,
    "black_king_concept_v2.glb": polish_black_king,
}
for _filename,_callback in _POLISHERS.items():
    _polish_scene(_filename,_callback)


# ---------------------------------------------------------------------------
# Concept v3 — silhouette + face + costume fidelity pass from the latest sheets.
# v2 remains as a safe source. v3 adds higher-readability hero details without
# destroying named-part animation structure.
# ---------------------------------------------------------------------------
def _upgrade_v3(src_name, dst_name, callback):
    src = OUT / src_name
    sc = trimesh.load(src, force="scene", process=False)
    callback(sc)
    dst = OUT / dst_name
    dst.write_bytes(sc.export(file_type="glb"))
    print(f"CONCEPT_V3_PASS {dst} parts={len(sc.geometry)} bytes={dst.stat().st_size}")

def _eye_pair(sc, prefix, mat_white, mat_iris, y, z, spread=.072, scale=.040):
    for side,x in (("L",-spread),("R",spread)):
        _addp(sc,f"{prefix}_EyeWhite_{side}",sphere(scale),mat_white,(x,y,z),scale=(1.22,.92,.55))
        _addp(sc,f"{prefix}_Iris_{side}",sphere(scale*.48),mat_iris,(x,y+.001,z-.030),scale=(1,.92,.45))

EYEWHITE=pbr("EyeWhite","#fff8ed",0,.30)
BLUEIRIS=pbr("BlueIris","#2c79b8",0,.18)
GREENIRIS=pbr("GreenIris","#9bbf45",0,.18)
REDIRIS=pbr("RedIris","#e34d3e",0,.16)
LIP=pbr("WarmLip","#a8544a",0,.46)
TEETH=pbr("Teeth","#f4ead9",0,.42)
SOFTGOLD=pbr("SoftGold","#e0b75a",.68,.24)
ROYALBLUE=pbr("RoyalBlueV3","#2454a1",.02,.38)
CRIMSON=pbr("CrimsonV3","#b22c38",.03,.36)
DEEPBLACK=pbr("DeepBlackV3","#18171c",.12,.38)
PALEIVORY=pbr("PaleIvoryV3","#f4eadc",0,.40)

def v3_white_pawn(sc):
    _eye_pair(sc,"V3",EYEWHITE,BLUEIRIS,1.225,-.252,.074,.043)
    _addp(sc,"V3_Smile",box((.12,.018,.018)),LIP,(0,1.105,-.258))
    _addp(sc,"V3_ChestCrossV",box((.052,.25,.038)),SOFTGOLD,(0,.87,-.348))
    _addp(sc,"V3_ChestCrossH",box((.19,.052,.038)),SOFTGOLD,(0,.87,-.348))
    _addp(sc,"V3_Pauldron_L",sphere(.115),SOFTGOLD,(-.30,.985,-.015),scale=(1.25,.52,.95))
    _addp(sc,"V3_Pauldron_R",sphere(.115),SOFTGOLD,(.30,.985,-.015),scale=(1.25,.52,.95))
    for i,(x,y,s) in enumerate(((0,1.64,(1.0,.75,1.0)),(.015,1.75,(.88,.70,.92)),(.035,1.86,(.70,.58,.80)))):
        _addp(sc,f"V3_Plume_{i}",sphere(.125),ROYALBLUE,(x,y,.035),scale=s)
    _addp(sc,"V3_ShieldRim",cyl(.315,.030),SOFTGOLD,(-.486,.75,-.020),(90,0,90))
    _addp(sc,"V3_SpearGem",sphere(.040),ROYALBLUE,(.55,1.45,-.03))

def v3_black_pawn(sc):
    _eye_pair(sc,"V3",EYEWHITE,GREENIRIS,1.225,-.252,.078,.044)
    _addp(sc,"V3_Grin",box((.15,.020,.020)),TEETH,(0,1.045,-.260))
    _addp(sc,"V3_LowerLip",box((.13,.018,.018)),LIP,(0,1.020,-.262))
    _addp(sc,"V3_ShoulderPlate_L",sphere(.125),CBRONZE,(-.31,.985,-.015),scale=(1.30,.52,.98))
    _addp(sc,"V3_ShoulderPlate_R",sphere(.125),CBRONZE,(.31,.985,-.015),scale=(1.30,.52,.98))
    for i,(x,y,s) in enumerate(((0,1.62,(1.05,.76,1.0)),(-.02,1.74,(.92,.68,.92)),(-.05,1.86,(.72,.56,.80)))):
        _addp(sc,f"V3_Plume_{i}",sphere(.128),CRIMSON,(x,y,.035),scale=s)
    _addp(sc,"V3_ShieldRim",cyl(.295,.032),CBRONZE,(-.486,.72,-.020),(90,0,90))
    _addp(sc,"V3_ShieldSlash",box((.11,.33,.034)),CRIMSON,(-.515,.72,-.035),(0,0,18))
    _addp(sc,"V3_CapeTear_L",box((.11,.24,.035)),CRIMSON,(-.13,.60,.225),(0,0,-10))
    _addp(sc,"V3_CapeTear_R",box((.11,.28,.035)),CRIMSON,(.12,.58,.225),(0,0,12))

def v3_white_knight(sc):
    _eye_pair(sc,"V3Horse",EYEWHITE,BLUEIRIS,1.425,-.690,.130,.042)
    _addp(sc,"V3Horse_Smile",box((.18,.022,.020)),LIP,(0,1.235,-.835))
    _eye_pair(sc,"V3Rider",EYEWHITE,BLUEIRIS,1.735,-.082,.055,.029)
    _addp(sc,"V3Rider_Moustache_L",sphere(.050),CHAIR,(-.045,1.675,-.105),scale=(1.28,.42,.52))
    _addp(sc,"V3Rider_Moustache_R",sphere(.050),CHAIR,(.045,1.675,-.105),scale=(1.28,.42,.52))
    _addp(sc,"V3_HorseChestGold",box((.32,.075,.075)),SOFTGOLD,(0,.93,-.515))
    _addp(sc,"V3_SaddleFleur",box((.055,.25,.045)),SOFTGOLD,(0,1.00,-.215))
    for side in (-1,1):
        _addp(sc,f"V3_HorseKneeGold_{side}",cyl(.060,.035),SOFTGOLD,(.20*side,.42,-.20),(0,0,90))
    _addp(sc,"V3_RiderCape",box((.38,.46,.042)),ROYALBLUE,(0,1.38,.28),(12,0,0))

def v3_black_knight(sc):
    _eye_pair(sc,"V3Horse",EYEWHITE,REDIRIS,1.435,-.695,.130,.042)
    _eye_pair(sc,"V3Rider",EYEWHITE,REDIRIS,1.742,-.092,.055,.029)
    _addp(sc,"V3_RiderGrin",box((.13,.020,.020)),TEETH,(0,1.655,-.112))
    _addp(sc,"V3_HorseChestArmor",box((.34,.18,.075)),DEEPBLACK,(0,.93,-.52))
    _addp(sc,"V3_HorseChestSlash",box((.055,.15,.083)),CRIMSON,(0,.93,-.565),(0,0,-15))
    for side in (-1,1):
        _addp(sc,f"V3_HorseShoulderSpike_{side}",trimesh.creation.cone(radius=.052,height=.18,sections=8),CBRONZE,(.22*side,.95,-.31),(0,0,38*side))
    _addp(sc,"V3_RiderCape",box((.40,.50,.045)),CRIMSON,(0,1.39,.29),(12,0,0))

def v3_white_bishop(sc):
    _eye_pair(sc,"V3",EYEWHITE,BLUEIRIS,1.49,-.250,.080,.035)
    _addp(sc,"V3_TrunkTip",sphere(.075),BIW["skin"],(0,1.15,-.35),scale=(.85,.65,1.10))
    _addp(sc,"V3_MitreGem",sphere(.055),BLUEIRIS,(0,1.95,-.145))
    _addp(sc,"V3_RobeGoldL",box((.035,.56,.035)),SOFTGOLD,(-.105,.78,-.375),(0,0,-4))
    _addp(sc,"V3_RobeGoldR",box((.035,.56,.035)),SOFTGOLD,(.105,.78,-.375),(0,0,4))
    _addp(sc,"V3_CapeLayer_L",box((.18,.62,.035)),ROYALBLUE,(-.23,1.00,.27),(0,0,-10))
    _addp(sc,"V3_CapeLayer_R",box((.18,.62,.035)),ROYALBLUE,(.23,1.00,.27),(0,0,10))
    _addp(sc,"V3_StaffOuterHalo",cyl(.170,.020),SOFTGOLD,(.46,1.82,-.02),(90,0,0))

def v3_black_bishop(sc):
    _eye_pair(sc,"V3",EYEWHITE,REDIRIS,1.50,-.250,.080,.035)
    _addp(sc,"V3_TrunkTip",sphere(.073),BIB["bone"],(0,1.18,-.35),scale=(.85,.65,1.10))
    _addp(sc,"V3_MitreGem",sphere(.055),CMAGENTA,(0,1.95,-.145))
    _addp(sc,"V3_RobeGoldL",box((.035,.57,.035)),CBRONZE,(-.105,.78,-.385),(0,0,-4))
    _addp(sc,"V3_RobeGoldR",box((.035,.57,.035)),CBRONZE,(.105,.78,-.385),(0,0,4))
    _addp(sc,"V3_CapeLayer_L",box((.18,.64,.035)),CRIMSON,(-.24,1.00,.28),(0,0,-11))
    _addp(sc,"V3_CapeLayer_R",box((.18,.64,.035)),CRIMSON,(.24,1.00,.28),(0,0,11))
    _addp(sc,"V3_StaffOuterHalo",cyl(.175,.020),CBRONZE,(.46,1.84,-.02),(90,0,0))

def v3_white_rook(sc):
    _eye_pair(sc,"V3",EYEWHITE,BLUEIRIS,1.055,-.405,.150,.044)
    _addp(sc,"V3_MouthWhite",box((.18,.035,.025)),TEETH,(0,.875,-.395))
    for side in (-1,1):
        _addp(sc,f"V3_FistKnuckleA_{side}",sphere(.105),RW["stone"],(.55*side,.49,-.11))
        _addp(sc,f"V3_FistKnuckleB_{side}",sphere(.105),RW["stone"],(.55*side,.49,.01))
        _addp(sc,f"V3_FistKnuckleC_{side}",sphere(.105),RW["stone"],(.55*side,.49,.13))
    _addp(sc,"V3_TabardPoint",trimesh.creation.cone(radius=.17,height=.28,sections=4),ROYALBLUE,(0,.50,-.38),(90,0,45))
    _addp(sc,"V3_CrownGoldBand",box((.84,.075,.84)),SOFTGOLD,(0,1.34,0))

def v3_black_rook(sc):
    _eye_pair(sc,"V3",EYEWHITE,REDIRIS,1.055,-.415,.150,.044)
    _addp(sc,"V3_MouthGlow",box((.18,.038,.025)),CLAVA,(0,.875,-.405))
    for side in (-1,1):
        _addp(sc,f"V3_FistKnuckleA_{side}",sphere(.108),RB["obs"],(.56*side,.48,-.11))
        _addp(sc,f"V3_FistKnuckleB_{side}",sphere(.108),RB["obs"],(.56*side,.48,.01))
        _addp(sc,f"V3_FistKnuckleC_{side}",sphere(.108),RB["obs"],(.56*side,.48,.13))
    _addp(sc,"V3_TabardPoint",trimesh.creation.cone(radius=.17,height=.28,sections=4),CRIMSON,(0,.50,-.39),(90,0,45))
    _addp(sc,"V3_CrownBronzeBand",box((.85,.075,.85)),CBRONZE,(0,1.35,0))

def v3_white_queen(sc):
    _eye_pair(sc,"V3",EYEWHITE,BLUEIRIS,1.615,-.220,.067,.031)
    _addp(sc,"V3_Lip",box((.09,.018,.016)),LIP,(0,1.505,-.225))
    for side in (-1,1):
        for j,(yy,zz,ss) in enumerate(((1.56,.12,(.85,1.20,.70)),(1.43,.16,(.78,1.28,.72)),(1.30,.18,(.70,1.20,.70)))):
            _addp(sc,f"V3_HairCurl_{side}_{j}",sphere(.105),CHAIR,(.20*side,yy,zz),scale=ss)
    _addp(sc,"V3_BodiceGoldV",box((.045,.32,.032)),SOFTGOLD,(0,1.11,-.252))
    _addp(sc,"V3_BodiceGoldH",box((.20,.045,.032)),SOFTGOLD,(0,1.11,-.252))
    _addp(sc,"V3_SkirtLayerFront",trimesh.creation.cone(radius=.34,height=.58,sections=24),PALEIVORY,(0,.57,-.01),(180,0,0),scale=(1,.7,1))
    _addp(sc,"V3_CapeBlue_L",box((.21,.58,.035)),ROYALBLUE,(-.29,1.02,.25),(0,0,-11))
    _addp(sc,"V3_CapeBlue_R",box((.21,.58,.035)),ROYALBLUE,(.29,1.02,.25),(0,0,11))

def v3_black_queen(sc):
    _eye_pair(sc,"V3",EYEWHITE,REDIRIS,1.625,-.220,.067,.031)
    _addp(sc,"V3_Lip",box((.095,.018,.016)),CRIMSON,(0,1.515,-.225))
    for side in (-1,1):
        for j,(yy,zz,ss) in enumerate(((1.57,.12,(.88,1.22,.72)),(1.44,.16,(.80,1.30,.74)),(1.31,.18,(.72,1.22,.72)))):
            _addp(sc,f"V3_HairCurl_{side}_{j}",sphere(.108),CDARKHAIR,(.20*side,yy,zz),scale=ss)
    _addp(sc,"V3_BodiceGoldV",box((.045,.33,.032)),CBRONZE,(0,1.12,-.252))
    _addp(sc,"V3_BodiceGoldH",box((.20,.045,.032)),CBRONZE,(0,1.12,-.252))
    _addp(sc,"V3_SkirtLayerFront",trimesh.creation.cone(radius=.35,height=.59,sections=24),CCHAR,(0,.58,-.01),(180,0,0),scale=(1,.7,1))
    _addp(sc,"V3_CapeRed_L",box((.22,.60,.035)),CRIMSON,(-.30,1.03,.26),(0,0,-12))
    _addp(sc,"V3_CapeRed_R",box((.22,.60,.035)),CRIMSON,(.30,1.03,.26),(0,0,12))

def v3_white_king(sc):
    _eye_pair(sc,"V3",EYEWHITE,BLUEIRIS,1.625,-.250,.078,.031)
    _addp(sc,"V3_Nose",sphere(.065),KW["skin"],(0,1.56,-.27),scale=(1,.80,1.20))
    _addp(sc,"V3_Moustache_L",sphere(.085),KW["beard"],(-.075,1.49,-.265),scale=(1.40,.46,.60))
    _addp(sc,"V3_Moustache_R",sphere(.085),KW["beard"],(.075,1.49,-.265),scale=(1.40,.46,.60))
    for side in (-1,1):
        _addp(sc,f"V3_FurSpotA_{side}",sphere(.028),KW["dark"],(.18*side,1.42,.00))
        _addp(sc,f"V3_FurSpotB_{side}",sphere(.024),KW["dark"],(.28*side,1.36,.03))
    _addp(sc,"V3_CoatPanel",box((.28,.50,.045)),PALEIVORY,(0,1.00,-.32))
    _addp(sc,"V3_CoatGoldV",box((.05,.46,.050)),SOFTGOLD,(0,1.00,-.35))
    _addp(sc,"V3_RemoteHolster",box((.18,.13,.09)),KW["dark"],(.27,.82,.15))

def v3_black_king(sc):
    _eye_pair(sc,"V3",EYEWHITE,REDIRIS,1.635,-.250,.078,.031)
    _addp(sc,"V3_Nose",sphere(.065),KB["skin"],(0,1.57,-.27),scale=(1,.80,1.20))
    _addp(sc,"V3_Moustache_L",sphere(.086),CBLACKFUR,(-.075,1.50,-.265),scale=(1.42,.46,.60))
    _addp(sc,"V3_Moustache_R",sphere(.086),CBLACKFUR,(.075,1.50,-.265),scale=(1.42,.46,.60))
    _addp(sc,"V3_CoatPanel",box((.29,.52,.045)),CRED,(0,1.01,-.33))
    _addp(sc,"V3_CoatGoldV",box((.05,.48,.050)),CBRONZE,(0,1.01,-.36))
    _addp(sc,"V3_LionEmblem",trimesh.creation.cone(radius=.11,height=.05,sections=6),CBLACKFUR,(0,.98,-.385),(90,0,0))
    _addp(sc,"V3_RemoteHolster",box((.18,.13,.09)),KB["dark"],(.28,.83,.15))

_V3 = {
 "white_pawn":v3_white_pawn, "black_pawn":v3_black_pawn,
 "white_knight":v3_white_knight, "black_knight":v3_black_knight,
 "white_bishop":v3_white_bishop, "black_bishop":v3_black_bishop,
 "white_rook":v3_white_rook, "black_rook":v3_black_rook,
 "white_queen":v3_white_queen, "black_queen":v3_black_queen,
 "white_king":v3_white_king, "black_king":v3_black_king,
}
for stem,cb in _V3.items():
    _upgrade_v3(f"{stem}_concept_v2.glb", f"{stem}_concept_v3.glb", cb)
