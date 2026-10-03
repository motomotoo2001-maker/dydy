#!/usr/bin/env python3
"""Build production-v1 White/Black King GLBs for Battle Chess Revival.

The pair preserves Head / Beard / CrownBand / Scepter / Arm_* /
V3_CoatPanel hooks used by idle, presentation and trapdoor capture logic.
"""
import argparse, math, sys
from pathlib import Path
import bpy


def args():
    av=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    p=argparse.ArgumentParser()
    p.add_argument("--white-output",required=True)
    p.add_argument("--black-output",required=True)
    return p.parse_args(av)


def mat(name,c,metal=0.0,rough=.45):
    m=bpy.data.materials.new(name); m.use_nodes=True
    b=m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value=(*c,1)
    b.inputs["Metallic"].default_value=metal
    b.inputs["Roughness"].default_value=rough
    return m


def finish(o,m=None,smooth=True):
    if getattr(o,"data",None) is not None:o.data.name=o.name
    if m is not None:o.data.materials.append(m)
    if smooth and o.type=="MESH":
        for p in o.data.polygons:p.use_smooth=True
    return o


def sphere(n,p,s,m,seg=48,rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=p)
    o=bpy.context.object;o.name=n;o.scale=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,m)


def box(n,p,s,m,rot=(0,0,0),bevel=.04):
    bpy.ops.mesh.primitive_cube_add(location=p,rotation=rot)
    o=bpy.context.object;o.name=n;o.scale=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    mod=o.modifiers.new("SoftBevel","BEVEL");mod.width=bevel;mod.segments=3
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,m,False)


def cyl(n,p,r,d,m,rot=(0,0,0),verts=48):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=d,location=p,rotation=rot)
    o=bpy.context.object;o.name=n;return finish(o,m)


def cone(n,p,r1,r2,d,m,rot=(0,0,0),verts=48):
    bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=d,location=p,rotation=rot)
    o=bpy.context.object;o.name=n;return finish(o,m)


def torus(n,p,major,minor,m,rot=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=64,minor_segments=16,location=p,rotation=rot)
    o=bpy.context.object;o.name=n;return finish(o,m)


def tube(n,points,r,m):
    c=bpy.data.curves.new(n+"_Curve","CURVE");c.dimensions="3D";c.resolution_u=3;c.bevel_depth=r;c.bevel_resolution=3
    sp=c.splines.new("BEZIER");sp.bezier_points.add(len(points)-1)
    for bp,co in zip(sp.bezier_points,points):
        bp.co=co;bp.handle_left_type="AUTO";bp.handle_right_type="AUTO"
    o=bpy.data.objects.new(n,c);bpy.context.collection.objects.link(o);c.materials.append(m)
    bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target="MESH")
    o=bpy.context.object;o.name=n;o.data.name=n
    for p in o.data.polygons:p.use_smooth=True
    return o


def palette(side):
    if side=="white":
        return {
            "robe":mat("WK_Robe",(.72,.67,.58),0,.47),
            "robe2":mat("WK_RoyalBlue",(.07,.20,.38),.02,.44),
            "cloth":mat("WK_BlueHi",(.13,.36,.62),.02,.38),
            "gold":mat("WK_Gold",(.73,.47,.13),.80,.22),
            "skin":mat("WK_Skin",(.66,.45,.34),0,.55),
            "hair":mat("WK_Beard",(.68,.64,.56),0,.59),
            "eye":mat("WK_Eye",(.08,.22,.32),.06,.18),
            "gem":mat("WK_Gem",(.12,.55,.92),.20,.11),
            "dark":mat("WK_Dark",(.05,.045,.05),.16,.43),
        }
    return {
        "robe":mat("BK_Robe",(.08,.055,.08),.05,.49),
        "robe2":mat("BK_Red",(.30,.025,.045),.03,.44),
        "cloth":mat("BK_Violet",(.24,.07,.34),.04,.38),
        "gold":mat("BK_Bronze",(.42,.21,.07),.72,.27),
        "skin":mat("BK_Skin",(.36,.20,.18),0,.58),
        "hair":mat("BK_Beard",(.05,.035,.04),.02,.61),
        "eye":mat("BK_Eye",(.90,.08,.025),.08,.14),
        "gem":mat("BK_Gem",(.86,.05,.12),.22,.10),
        "dark":mat("BK_Dark",(.012,.010,.016),.18,.41),
    }


def build(side,outpath):
    P=palette(side);O=[]
    root=bpy.data.objects.new("WhiteKingProductionV1" if side=="white" else "BlackKingProductionV1",None);bpy.context.collection.objects.link(root)

    # Pedestal / regal base.
    O.append(cyl("PedestalLower",(0,0,.07),.49,.14,P["dark"],verts=64))
    O.append(torus("PedestalTrim",(0,0,.13),.42,.034,P["gold"]))
    O.append(cyl("PedestalUpper",(0,0,.21),.40,.14,P["robe"],verts=64))

    # Robe body and coat.
    O.append(cone("RobeCore",(0,0,.76),.42,.27,.98,P["robe2"],verts=64))
    O.append(cone("RobeOuter",(0,.01,.70),.44,.33,.70,P["robe"],verts=64))
    O.append(box("V3_CoatPanel",(0,-.38,.77),(.18,.025,.34),P["cloth"],bevel=.04))
    O.append(cone("CoatPoint",(0,-.40,.42),.17,.02,.30,P["cloth"],verts=5))
    O.append(box("CoatStripe",(0,-.425,.78),(.035,.012,.28),P["gold"],bevel=.008))
    for i,x in enumerate((-.27,-.13,.13,.27)):
        O.append(box(f"RobePleat_{i}",(x,-.30,.66),(.032,.014,.25),P["robe2"],bevel=.009))
    O.append(torus("WaistRing",(0,0,1.08),.28,.028,P["gold"]))

    # Torso, mantle and cape.
    O.append(sphere("Torso",(0,0,1.28),(.28,.20,.33),P["robe"],48,24))
    O.append(box("ChestPlate",(0,-.21,1.28),(.22,.040,.24),P["cloth"],bevel=.05))
    O.append(torus("FurCollar",(0,0,1.48),.31,.075,P["hair"]))
    O.append(box("Cape",(0,.20,1.20),(.31,.040,.42),P["robe2"],rot=(math.radians(-7),0,0),bevel=.065))
    O.append(box("Cape_L",(-.20,.22,.99),(.12,.025,.33),P["cloth"],rot=(math.radians(-9),0,math.radians(-5)),bevel=.04))
    O.append(box("Cape_R",(.20,.22,.99),(.12,.025,.33),P["cloth"],rot=(math.radians(-9),0,math.radians(5)),bevel=.04))

    # Arms.
    for sign,label in [(-1,"L"),(1,"R")]:
        O.append(sphere(f"Shoulder_{label}",(.31*sign,-.01,1.36),(.14,.14,.13),P["robe2"],36,18))
        O.append(sphere(f"Arm_{label}",(.36*sign,-.03,1.18),(.080,.085,.22),P["robe"],36,18))
        O.append(sphere(f"Hand_{label}",(.39*sign,-.08,1.00),(.078,.068,.080),P["skin"],30,15))
        O.append(box(f"Cuff_{label}",(.36*sign,-.04,1.08),(.09,.08,.045),P["gold"],bevel=.02))

    # Face.
    O.append(sphere("Head",(0,-.02,1.72),(.205,.18,.22),P["skin"],52,26))
    O.append(sphere("Nose",(0,-.195,1.70),(.042,.030,.048),P["skin"],28,14))
    O.append(sphere("Eye_L",(-.070,-.195,1.76),(.029,.017,.029),P["eye"],24,12))
    O.append(sphere("Eye_R",(.070,-.195,1.76),(.029,.017,.029),P["eye"],24,12))
    O.append(box("Brow_L",(-.070,-.208,1.81),(.062,.010,.012),P["hair"],rot=(0,0,math.radians(-7)),bevel=.004))
    O.append(box("Brow_R",(.070,-.208,1.81),(.062,.010,.012),P["hair"],rot=(0,0,math.radians(7)),bevel=.004))
    O.append(box("Mouth",(0,-.208,1.62),(.060,.010,.010),P["dark"],bevel=.004))

    # Beard / moustache as distinct animation-readable pieces.
    O.append(sphere("Beard",(0,-.10,1.51),(.17,.095,.24),P["hair"],44,22))
    O.append(tube("Moustache_L",[(-.02,-.215,1.64),(-.08,-.225,1.61),(-.13,-.205,1.60)],.025,P["hair"]))
    O.append(tube("Moustache_R",[(.02,-.215,1.64),(.08,-.225,1.61),(.13,-.205,1.60)],.025,P["hair"]))

    # Crown.
    O.append(torus("CrownBand",(0,0,1.91),.19,.027,P["gold"]))
    for i,(x,z) in enumerate(((-.15,2.02),(-.075,2.09),(0,2.13),(.075,2.09),(.15,2.02))):
        O.append(cone(f"CrownPoint_{i}",(x,0,z),.038,.004,.24 if i!=2 else .28,P["gold"],verts=28))
    O.append(sphere("CrownGem",(0,-.195,1.96),(.048,.025,.055),P["gem"],28,14))
    O.append(sphere("CrownGem_L",(-.105,-.175,1.94),(.030,.020,.034),P["gem"],24,12))
    O.append(sphere("CrownGem_R",(.105,-.175,1.94),(.030,.020,.034),P["gem"],24,12))

    # Scepter.
    sx=.44
    O.append(cyl("Scepter",(sx,-.01,1.20),.028,1.60,P["gold"],rot=(0,0,math.radians(-3)),verts=32))
    O.append(torus("ScepterRing",(sx,-.02,1.93),.15,.024,P["gold"],rot=(math.radians(90),0,0)))
    O.append(sphere("ScepterGem",(sx,-.03,1.93),(.085,.060,.085),P["gem"],36,18))
    O.append(cone("ScepterCrown",(sx,-.01,2.17),.050,.004,.22,P["gold"],verts=28))

    if side=="white":
        O.append(box("ChestCrossV",(0,-.252,1.28),(.028,.010,.12),P["gold"],bevel=.006))
        O.append(box("ChestCrossH",(0,-.254,1.31),(.090,.010,.028),P["gold"],bevel=.006))
        for i,x in enumerate((-.27,.27)):
            O.append(sphere(f"ShoulderGem_{i}",(x,-.14,1.40),(.042,.024,.042),P["gem"],24,12))
    else:
        # Dark-lord cues.
        O.append(cone("CrownHorn_L",(-.17,.01,2.07),.045,.004,.30,P["dark"],rot=(0,math.radians(-20),math.radians(-16)),verts=28))
        O.append(cone("CrownHorn_R",(.17,.01,2.07),.045,.004,.30,P["dark"],rot=(0,math.radians(20),math.radians(16)),verts=28))
        for sign,label in [(-1,"L"),(1,"R")]:
            O.append(cone(f"ShoulderSpike_{label}",(.30*sign,-.02,1.54),.045,.004,.26,P["gold"],rot=(0,math.radians(12*sign),0),verts=24))
        O.append(sphere("ChestSkull",(0,-.255,1.28),(.070,.035,.078),P["hair"],32,16))

    # Extra trim/detail.
    for i,z in enumerate((.44,.60,.78,.96)):
        O.append(torus(f"RobeTrim_{i}",(0,0,z),.35-i*.018,.010,P["gold"]))
    for i,(x,z) in enumerate(((-.18,1.18),(.18,1.18),(-.24,1.02),(.24,1.02))):
        O.append(sphere(f"RobeGem_{i}",(x,-.250,z),(.032,.018,.032),P["gem"],22,11))

    for o in O:o.parent=root
    bpy.ops.object.select_all(action="DESELECT");root.select_set(True)
    for o in O:o.select_set(True)
    bpy.context.view_layer.objects.active=root
    out=Path(outpath).resolve();out.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out),export_format="GLB",use_selection=True,export_animations=False,export_cameras=False,export_lights=False,export_apply=False)
    print("KING_PRODUCTION_EXPORT_PASS",side,out,"parts=",len(O))

    for o in list(O):
        if o.name in bpy.data.objects:bpy.data.objects.remove(o,do_unlink=True)
    if root.name in bpy.data.objects:bpy.data.objects.remove(root,do_unlink=True)
    for m in list(bpy.data.meshes):
        if m.users==0:bpy.data.meshes.remove(m)
    for c in list(bpy.data.curves):
        if c.users==0:bpy.data.curves.remove(c)


def main():
    a=args();bpy.ops.wm.read_factory_settings(use_empty=True)
    build("white",a.white_output);build("black",a.black_output)
    print("KING_PRODUCTION_BUILD_PASS")


if __name__=="__main__":main()
