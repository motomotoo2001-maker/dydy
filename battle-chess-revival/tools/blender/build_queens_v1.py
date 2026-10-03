#!/usr/bin/env python3
"""Build production-v1 White/Black Queen GLBs for Battle Chess Revival.

Queen parts intentionally preserve Head/Hair/CrownBand/Staff/MagicOrb plus
V3_HairCurl* and V3_Cape* hooks used by idle and transformation captures.
"""
import argparse, math, sys
from pathlib import Path
import bpy


def args():
    av=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    p=argparse.ArgumentParser()
    p.add_argument("--white-output",required=True); p.add_argument("--black-output",required=True)
    return p.parse_args(av)


def mat(name,c,metal=0.0,rough=.45):
    m=bpy.data.materials.new(name); m.use_nodes=True
    b=m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value=(*c,1); b.inputs["Metallic"].default_value=metal; b.inputs["Roughness"].default_value=rough
    return m


def finish(o,m=None,smooth=True):
    if getattr(o,"data",None) is not None: o.data.name=o.name
    if m is not None: o.data.materials.append(m)
    if smooth and o.type=="MESH":
        for p in o.data.polygons: p.use_smooth=True
    return o


def sphere(n,p,s,m,seg=48,rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=p)
    o=bpy.context.object; o.name=n; o.scale=s; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); return finish(o,m)


def box(n,p,s,m,rot=(0,0,0),bevel=.035):
    bpy.ops.mesh.primitive_cube_add(location=p,rotation=rot)
    o=bpy.context.object; o.name=n; o.scale=s; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    mod=o.modifiers.new("SoftBevel","BEVEL"); mod.width=bevel; mod.segments=3; bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,m,False)


def cyl(n,p,r,d,m,rot=(0,0,0),verts=48):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=d,location=p,rotation=rot)
    o=bpy.context.object; o.name=n; return finish(o,m)


def cone(n,p,r1,r2,d,m,rot=(0,0,0),verts=48):
    bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=d,location=p,rotation=rot)
    o=bpy.context.object; o.name=n; return finish(o,m)


def torus(n,p,major,minor,m,rot=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=64,minor_segments=16,location=p,rotation=rot)
    o=bpy.context.object; o.name=n; return finish(o,m)


def tube(n,points,r,m):
    c=bpy.data.curves.new(n+"_Curve","CURVE"); c.dimensions="3D"; c.resolution_u=3; c.bevel_depth=r; c.bevel_resolution=3
    sp=c.splines.new("BEZIER"); sp.bezier_points.add(len(points)-1)
    for bp,co in zip(sp.bezier_points,points):
        bp.co=co; bp.handle_left_type="AUTO"; bp.handle_right_type="AUTO"
    o=bpy.data.objects.new(n,c); bpy.context.collection.objects.link(o); c.materials.append(m)
    bpy.context.view_layer.objects.active=o; o.select_set(True); bpy.ops.object.convert(target="MESH")
    o=bpy.context.object; o.name=n; o.data.name=n
    for p in o.data.polygons: p.use_smooth=True
    return o


def palette(side):
    if side=="white":
        return {
            "dress":mat("WQ_Ivory",(0.82,.78,.70),0,.44),
            "dress2":mat("WQ_Blue",(0.08,.24,.43),.02,.45),
            "cloth":mat("WQ_BlueHi",(.15,.42,.68),.02,.38),
            "gold":mat("WQ_Gold",(.72,.48,.14),.78,.22),
            "skin":mat("WQ_Skin",(.72,.50,.38),0,.54),
            "hair":mat("WQ_Hair",(.18,.11,.07),0,.55),
            "eye":mat("WQ_Eye",(.06,.23,.36),.05,.18),
            "gem":mat("WQ_Gem",(.15,.60,.95),.18,.12),
            "dark":mat("WQ_Dark",(.05,.045,.05),.15,.42),
        }
    return {
        "dress":mat("BQ_Black",(.08,.055,.09),.08,.48),
        "dress2":mat("BQ_Magenta",(.32,.025,.18),.03,.43),
        "cloth":mat("BQ_Violet",(.30,.08,.42),.04,.38),
        "gold":mat("BQ_Bronze",(.42,.22,.07),.70,.27),
        "skin":mat("BQ_Skin",(.43,.27,.31),0,.54),
        "hair":mat("BQ_Hair",(.025,.02,.03),.04,.52),
        "eye":mat("BQ_Eye",(.82,.06,.18),.05,.15),
        "gem":mat("BQ_Gem",(.92,.08,.36),.20,.10),
        "dark":mat("BQ_Dark",(.012,.01,.018),.18,.40),
    }


def build(side,outpath):
    P=palette(side); O=[]
    root=bpy.data.objects.new("WhiteQueenProductionV1" if side=="white" else "BlackQueenProductionV1",None); bpy.context.collection.objects.link(root)

    # Pedestal.
    O.append(cyl("PedestalLower",(0,0,.07),.47,.14,P["dark"],verts=64))
    O.append(torus("PedestalTrim",(0,0,.13),.405,.033,P["gold"]))
    O.append(cyl("PedestalUpper",(0,0,.20),.39,.13,P["dress"],verts=64))

    # Layered skirt / torso.
    O.append(cone("SkirtCore",(0,0,.73),.39,.24,.92,P["dress2"],verts=64))
    O.append(cone("SkirtOuter",(0,.01,.67),.43,.31,.65,P["dress"],verts=64))
    O.append(box("SkirtFrontPanel",(0,-.36,.69),(.16,.025,.30),P["cloth"],bevel=.035))
    O.append(cone("SkirtFrontPoint",(0,-.38,.38),.15,.02,.28,P["cloth"],verts=5))
    for i,x in enumerate((-.25,-.12,.12,.25)):
        O.append(box(f"SkirtPleat_{i}",(x,-.305,.64),(.032,.015,.26),P["gold"] if i in (0,3) else P["dress2"],bevel=.009))
    O.append(torus("WaistRing",(0,0,1.07),.25,.026,P["gold"]))

    O.append(sphere("Torso",(0,0,1.25),(.25,.18,.31),P["dress"],48,24))
    O.append(box("Bodice",(0,-.19,1.25),(.20,.035,.23),P["cloth"],bevel=.045))
    O.append(sphere("ChestGem",(0,-.235,1.27),(.060,.030,.070),P["gem"],32,16))

    # Cape with exact V3 prefix.
    O.append(box("V3_Cape",(0,.19,1.16),(.29,.035,.38),P["dress2"],rot=(math.radians(-8),0,0),bevel=.06))
    O.append(box("V3_Cape_L",(-.19,.21,.96),(.12,.026,.33),P["cloth"],rot=(math.radians(-10),0,math.radians(-5)),bevel=.04))
    O.append(box("V3_Cape_R",(.19,.21,.96),(.12,.026,.33),P["cloth"],rot=(math.radians(-10),0,math.radians(5)),bevel=.04))

    # Arms and hands.
    for sign,label in [(-1,"L"),(1,"R")]:
        O.append(sphere(f"Shoulder_{label}",(.29*sign,-.01,1.33),(.13,.13,.12),P["dress2"],36,18))
        O.append(sphere(f"Arm_{label}",(.34*sign,-.03,1.16),(.075,.08,.21),P["dress"],36,18))
        O.append(sphere(f"Hand_{label}",(.37*sign,-.08,1.00),(.075,.065,.078),P["skin"],30,15))

    # Face.
    O.append(sphere("Head",(0,-.02,1.66),(.19,.17,.21),P["skin"],52,26))
    O.append(sphere("Nose",(0,-.185,1.64),(.040,.030,.045),P["skin"],28,14))
    O.append(sphere("Eye_L",(-.065,-.185,1.70),(.028,.016,.028),P["eye"],24,12))
    O.append(sphere("Eye_R",(.065,-.185,1.70),(.028,.016,.028),P["eye"],24,12))
    O.append(box("Brow_L",(-.065,-.198,1.75),(.060,.010,.012),P["hair"],rot=(0,0,math.radians(-8)),bevel=.004))
    O.append(box("Brow_R",(.065,-.198,1.75),(.060,.010,.012),P["hair"],rot=(0,0,math.radians(8)),bevel=.004))
    O.append(box("Mouth",(0,-.198,1.57),(.055,.010,.010),P["dark"],bevel=.004))

    # Hair mass + authored curls.
    O.append(sphere("Hair",(0,.045,1.72),(.215,.18,.24),P["hair"],48,24))
    O.append(box("HairBack",(0,.15,1.49),(.21,.055,.34),P["hair"],rot=(math.radians(-5),0,0),bevel=.07))
    curl_specs=[(-.22,-.13,1.55),(.22,-.13,1.55),(-.24,.02,1.42),(.24,.02,1.42)]
    for i,(x,y,z) in enumerate(curl_specs):
        pts=[(x,y,z+.16),(x*1.05,y-.01,z+.05),(x*.92,y-.03,z-.08)]
        O.append(tube(f"V3_HairCurl_{i}",pts,.032,P["hair"]))

    # Crown.
    O.append(torus("CrownBand",(0,-.005,1.83),.18,.025,P["gold"]))
    for i,(x,z) in enumerate(((-.13,1.96),(-.065,2.02),(0,2.06),(.065,2.02),(.13,1.96))):
        O.append(cone(f"CrownPoint_{i}",(x,-.005,z),.035,.004,.22 if i!=2 else .26,P["gold"],verts=28))
    O.append(sphere("CrownGem",(0,-.185,1.88),(.045,.024,.052),P["gem"],28,14))

    # Staff and magic orb; Staff prefix drives capture.
    sx=.43
    O.append(cyl("Staff",(sx,-.01,1.18),.027,1.65,P["gold"],rot=(0,0,math.radians(-3)),verts=32))
    O.append(torus("StaffRing",(sx,-.02,1.94),.17,.025,P["gold"],rot=(math.radians(90),0,0)))
    O.append(torus("StaffOuterRing",(sx,-.02,1.94),.22,.015,P["gold"],rot=(math.radians(90),0,0)))
    O.append(sphere("MagicOrb",(sx,-.03,1.94),(.10,.075,.10),P["gem"],40,20))
    O.append(cone("StaffCrownTip",(sx,-.01,2.19),.045,.004,.22,P["gold"],verts=28))

    # Faction details.
    if side=="white":
        O.append(box("BodiceCrossV",(0,-.235,1.25),(.025,.010,.11),P["gold"],bevel=.006))
        O.append(box("BodiceCrossH",(0,-.237,1.27),(.085,.010,.025),P["gold"],bevel=.006))
        for i,x in enumerate((-.28,.28)):
            O.append(sphere(f"ShoulderGem_{i}",(x,-.13,1.36),(.040,.023,.040),P["gem"],24,12))
    else:
        O.append(cone("CrownHorn_L",(-.17,.015,1.97),.040,.004,.28,P["dark"],rot=(0,math.radians(-18),math.radians(-15)),verts=28))
        O.append(cone("CrownHorn_R",(.17,.015,1.97),.040,.004,.28,P["dark"],rot=(0,math.radians(18),math.radians(15)),verts=28))
        for i,x in enumerate((-.26,.26)):
            O.append(cone(f"ShoulderSpike_{i}",(x,-.02,1.50),.045,.004,.25,P["gold"],rot=(0,math.radians(12*x/.26),0),verts=24))

    # More trim/detail to avoid concept-blockout simplicity.
    for i,z in enumerate((.42,.58,.76,.94)):
        O.append(torus(f"SkirtTrim_{i}",(0,0,z),.34-i*.018,.010,P["gold"]))
    for i,(x,z) in enumerate(((-.18,1.16),(.18,1.16),(-.23,1.02),(.23,1.02))):
        O.append(sphere(f"RobeGem_{i}",(x,-.245,z),(.032,.018,.032),P["gem"],22,11))

    for o in O:o.parent=root
    bpy.ops.object.select_all(action="DESELECT"); root.select_set(True)
    for o in O:o.select_set(True)
    bpy.context.view_layer.objects.active=root
    out=Path(outpath).resolve(); out.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out),export_format="GLB",use_selection=True,export_animations=False,export_cameras=False,export_lights=False,export_apply=False)
    print("QUEEN_PRODUCTION_EXPORT_PASS",side,out,"parts=",len(O))

    for o in list(O):
        if o.name in bpy.data.objects:bpy.data.objects.remove(o,do_unlink=True)
    if root.name in bpy.data.objects:bpy.data.objects.remove(root,do_unlink=True)
    for m in list(bpy.data.meshes):
        if m.users==0:bpy.data.meshes.remove(m)
    for c in list(bpy.data.curves):
        if c.users==0:bpy.data.curves.remove(c)


def main():
    a=args(); bpy.ops.wm.read_factory_settings(use_empty=True)
    build("white",a.white_output); build("black",a.black_output)
    print("QUEEN_PRODUCTION_BUILD_PASS")


if __name__=="__main__":main()
