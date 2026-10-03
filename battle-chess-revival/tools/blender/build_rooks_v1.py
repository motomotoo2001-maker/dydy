#!/usr/bin/env python3
"""Build production-v1 White/Black Rook GLBs for Battle Chess Revival.

Rooks are fortress-bruiser characters with named TowerCore/CrownBase/Arm_*/
Fist_* pieces so current idle, presentation and jump-crush capture animation
can drive them before the later Skeleton3D pass.
"""
import argparse
import math
import sys
from pathlib import Path
import bpy


def parse_args():
    argv=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    p=argparse.ArgumentParser()
    p.add_argument("--white-output",required=True)
    p.add_argument("--black-output",required=True)
    return p.parse_args(argv)


def mat(name,c,metal=0.0,rough=0.45):
    m=bpy.data.materials.new(name); m.use_nodes=True
    bs=m.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value=(*c,1)
    bs.inputs["Metallic"].default_value=metal
    bs.inputs["Roughness"].default_value=rough
    return m


def finish(o,m=None,smooth=True):
    if getattr(o,"data",None) is not None: o.data.name=o.name
    if m is not None: o.data.materials.append(m)
    if smooth and o.type=="MESH":
        for p in o.data.polygons: p.use_smooth=True
    return o


def box(name,pos,scale,m,rot=(0,0,0),bevel=.04):
    bpy.ops.mesh.primitive_cube_add(location=pos,rotation=rot)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel>0:
        mod=o.modifiers.new("EdgeBevel","BEVEL"); mod.width=bevel; mod.segments=3
        bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,m,False)


def sphere(name,pos,scale,m,seg=48,rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=pos)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,m)


def cyl(name,pos,radius,depth,m,rot=(0,0,0),verts=48):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=radius,depth=depth,location=pos,rotation=rot)
    o=bpy.context.object; o.name=name
    return finish(o,m)


def cone(name,pos,r1,r2,depth,m,rot=(0,0,0),verts=48):
    bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=depth,location=pos,rotation=rot)
    o=bpy.context.object; o.name=name
    return finish(o,m)


def torus(name,pos,major,minor,m,rot=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=64,minor_segments=16,location=pos,rotation=rot)
    o=bpy.context.object; o.name=name
    return finish(o,m)


def palette(side):
    if side=="white":
        return {
            "stone":mat("WR_Marble",(0.72,0.70,0.66),0.02,.50),
            "stone2":mat("WR_MarbleHi",(0.88,0.85,0.78),0.01,.42),
            "blue":mat("WR_Blue",(0.08,0.22,0.38),.03,.47),
            "blue2":mat("WR_BlueHi",(0.14,0.38,0.60),.03,.40),
            "gold":mat("WR_Gold",(0.67,0.43,0.13),.78,.24),
            "steel":mat("WR_Steel",(0.35,0.39,0.43),.82,.23),
            "dark":mat("WR_Dark",(0.05,0.05,0.06),.16,.46),
            "eye":mat("WR_Eye",(0.10,0.58,0.95),.10,.16),
        }
    return {
        "stone":mat("BR_Basalt",(0.10,0.09,0.105),.10,.54),
        "stone2":mat("BR_IronStone",(0.20,0.18,0.20),.28,.40),
        "blue":mat("BR_Red",(0.34,0.025,0.035),.04,.47),
        "blue2":mat("BR_RedHi",(0.60,0.055,0.035),.06,.35),
        "gold":mat("BR_Bronze",(0.40,0.21,0.07),.72,.29),
        "steel":mat("BR_BlackSteel",(0.12,0.13,0.15),.84,.22),
        "dark":mat("BR_Dark",(0.012,0.012,0.016),.20,.43),
        "eye":mat("BR_Eye",(0.96,0.12,0.025),.10,.13),
    }


def build(side,output):
    P=palette(side); objs=[]
    root=bpy.data.objects.new("WhiteRookProductionV1" if side=="white" else "BlackRookProductionV1",None)
    bpy.context.collection.objects.link(root)

    # Dense chess pedestal / fortress footing.
    objs.append(cyl("PedestalLower",(0,0,.07),.50,.14,P["dark"],verts=64))
    objs.append(torus("PedestalTrim",(0,0,.13),.43,.035,P["gold"]))
    objs.append(cyl("PedestalUpper",(0,0,.21),.42,.16,P["stone"],verts=64))
    objs.append(torus("PedestalUpperTrim",(0,0,.285),.39,.022,P["gold"]))

    # Main keep with chamfered block layers.
    objs.append(box("TowerCore",(0,0,.88),(.34,.31,.56),P["stone"],bevel=.08))
    objs.append(box("TowerFrontArmor",(0,-.325,.91),(.30,.045,.46),P["stone2"],bevel=.05))
    objs.append(box("TowerBackArmor",(0,.325,.91),(.30,.045,.46),P["stone2"],bevel=.05))
    objs.append(box("WaistBand",(0,0,.58),(.37,.34,.075),P["gold"],bevel=.025))
    objs.append(box("ChestBand",(0,0,1.20),(.37,.34,.065),P["gold"],bevel=.025))

    # Tabard/crest, including exact capture prefix.
    objs.append(box("Tabard",(0,-.39,.82),(.19,.025,.30),P["blue"],bevel=.035))
    objs.append(cone("V3_TabardPoint",(0,-.40,.49),.18,.02,.30,P["blue"],verts=5))
    objs.append(box("TabardStripe",(0,-.423,.82),(.035,.012,.25),P["gold"],bevel=.008))

    # Face built into the tower.
    objs.append(box("BrowBlock",(0,-.39,1.27),(.26,.035,.09),P["stone2"],bevel=.035))
    objs.append(sphere("EyeL",(-.13,-.435,1.28),(.055,.025,.050),P["eye"],32,16))
    objs.append(sphere("EyeR",(.13,-.435,1.28),(.055,.025,.050),P["eye"],32,16))
    objs.append(box("Brow_L",(-.13,-.46,1.34),(.10,.018,.022),P["dark"],rot=(0,0,math.radians(-8)),bevel=.01))
    objs.append(box("Brow_R",(.13,-.46,1.34),(.10,.018,.022),P["dark"],rot=(0,0,math.radians(8)),bevel=.01))
    objs.append(box("Mouth",(0,-.445,1.14),(.12,.018,.025),P["dark"],bevel=.01))

    # Castle crown silhouette.
    objs.append(box("CrownBase",(0,0,1.48),(.40,.37,.16),P["stone2"],bevel=.045))
    battlements=[(-.31,-.27),(-.10,-.27),(.10,-.27),(.31,-.27),(-.31,.27),(-.10,.27),(.10,.27),(.31,.27)]
    for i,(x,y) in enumerate(battlements):
        objs.append(box(f"CrownMerlon_{i}",(x,y,1.68),(.085,.085,.17),P["stone"],bevel=.025))
    objs.append(torus("CrownGoldBand",(0,0,1.48),.34,.025,P["gold"],rot=(0,0,0)))

    # Massive shoulders.
    for sign,label in [(-1,"L"),(1,"R")]:
        objs.append(sphere(f"Shoulder_{label}",(.42*sign,-.01,1.18),(.20,.20,.19),P["stone2"],44,22))
        objs.append(box(f"ShoulderPlate_{label}",(.47*sign,-.04,1.22),(.17,.16,.11),P["steel"],rot=(0,math.radians(6*sign),0),bevel=.055))
        # Arm segments intentionally named with Arm_ prefix.
        objs.append(sphere(f"Arm_{label}_Upper",(.49*sign,-.02,.99),(.12,.13,.23),P["stone"],40,20))
        objs.append(sphere(f"Arm_{label}_Forearm",(.53*sign,-.07,.74),(.13,.14,.22),P["stone2"],40,20))
        # Oversized animated fists.
        objs.append(sphere(f"Fist_{label}",(.55*sign,-.12,.53),(.20,.18,.18),P["stone2"],44,22))
        for j,(dx,dz) in enumerate(((-.07,.07),(0,.09),(.07,.07))):
            objs.append(sphere(
                f"V3_FistKnuckle_{label}_{j}",
                (.55*sign+dx,-.275,.57+dz),(.060,.045,.055),P["steel"],28,14
            ))
        objs.append(box(f"FistBand_{label}",(.55*sign,-.06,.62),(.17,.14,.045),P["gold"],bevel=.018))

    # Front fortress details.
    for i,x in enumerate((-.24,-.12,.12,.24)):
        objs.append(box(f"FrontStoneRib_{i}",(x,-.382,.91),(.025,.014,.36),P["stone"],bevel=.008))
    for i,z in enumerate((.70,.88,1.06)):
        objs.append(box(f"FrontStoneCourse_{i}",(0,-.385,z),(.27,.014,.018),P["stone"],bevel=.006))
    objs.append(box("ChestEmblemV",(0,-.442,.94),(.038,.012,.20),P["gold"],bevel=.01))
    objs.append(box("ChestEmblemH",(0,-.444,.98),(.14,.012,.038),P["gold"],bevel=.01))

    if side=="black":
        # Lava fissures and spikes create a stronger hostile silhouette.
        for i,(x,z,ang) in enumerate(((-.18,.78,-18),(.16,.92,14),(-.10,1.10,8),(.20,1.19,-12))):
            objs.append(box(f"LavaCrack_{i}",(x,-.442,z),(.018,.010,.13),P["blue2"],rot=(0,0,math.radians(ang)),bevel=.006))
        for sign,label in [(-1,"L"),(1,"R")]:
            objs.append(cone(f"ShoulderSpike_{label}",(.46*sign,-.04,1.48),.07,.005,.32,P["steel"],rot=(0,math.radians(14*sign),0),verts=28))
        for i,x in enumerate((-.26,0,.26)):
            objs.append(cone(f"CrownSpike_{i}",(x,0,1.84),.055,.004,.28,P["steel"],verts=28))
    else:
        # Blue enamel heraldry and polished corner caps.
        for sign,label in [(-1,"L"),(1,"R")]:
            objs.append(box(f"HeraldicPlate_{label}",(.26*sign,-.435,1.04),(.065,.012,.12),P["blue2"],bevel=.02))
        for i,x in enumerate((-.29,.29)):
            objs.append(sphere(f"CrownGem_{i}",(x,-.37,1.52),(.045,.025,.045),P["eye"],28,14))

    # Side armor bands make the silhouette less box-like.
    for sign,label in [(-1,"L"),(1,"R")]:
        objs.append(box(f"SideBand_{label}",(.355*sign,0,.92),(.035,.30,.42),P["gold"],bevel=.015))
        objs.append(box(f"SideInset_{label}",(.395*sign,0,.91),(.025,.22,.28),P["blue"],bevel=.018))

    for o in objs: o.parent=root

    bpy.ops.object.select_all(action="DESELECT"); root.select_set(True)
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active=root
    out=Path(output).resolve(); out.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(out),export_format="GLB",use_selection=True,
        export_animations=False,export_cameras=False,export_lights=False,export_apply=False
    )
    print("ROOK_PRODUCTION_EXPORT_PASS",side,out,"parts=",len(objs))

    for o in list(objs):
        if o.name in bpy.data.objects: bpy.data.objects.remove(o,do_unlink=True)
    if root.name in bpy.data.objects: bpy.data.objects.remove(root,do_unlink=True)
    for mesh in list(bpy.data.meshes):
        if mesh.users==0: bpy.data.meshes.remove(mesh)


def main():
    a=parse_args(); bpy.ops.wm.read_factory_settings(use_empty=True)
    build("white",a.white_output)
    build("black",a.black_output)
    print("ROOK_PRODUCTION_BUILD_PASS")


if __name__=="__main__":
    main()
