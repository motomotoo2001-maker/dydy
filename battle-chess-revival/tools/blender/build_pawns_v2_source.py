import bpy, math, os
from mathutils import Vector
from math import radians, sin, cos, pi

import argparse, sys
_cli = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
_parser = argparse.ArgumentParser()
_parser.add_argument('--output', required=True, help='Output .blend source path')
_args = _parser.parse_args(_cli)
SOURCE_BLEND = os.path.abspath(_args.output)
OUT = os.path.dirname(SOURCE_BLEND)
os.makedirs(OUT, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
scene.render.engine='BLENDER_EEVEE'
scene.render.resolution_x=512
scene.render.resolution_y=512
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.image_settings.color_mode='RGBA'
scene.render.film_transparent=False
scene.view_settings.look='AgX - Medium High Contrast'
scene.world=bpy.data.worlds.new('World')
scene.world.color=(0.008,0.006,0.008)

# ---------------- materials ----------------
def mat(name, color, metallic=0.0, rough=0.4):
    m=bpy.data.materials.new(name)
    m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Metallic'].default_value=metallic
    bs.inputs['Roughness'].default_value=rough
    return m

IVORY=mat('Ivory enamel',(0.82,0.79,0.68),0.28,0.23)
IVORY_HI=mat('Ivory highlight',(0.98,0.93,0.78),0.18,0.20)
GOLD=mat('Warm polished gold',(0.92,0.39,0.055),0.90,0.18)
GOLD_HI=mat('Gold highlight',(1.0,0.62,0.13),0.95,0.14)
BLUE=mat('Royal blue cloth',(0.025,0.17,0.52),0.08,0.38)
BLUE_HI=mat('Blue plume',(0.035,0.20,0.68),0.05,0.32)
BROWN=mat('Brown leather',(0.17,0.045,0.012),0.05,0.32)
BROWN_HI=mat('Brown leather highlight',(0.32,0.09,0.025),0.08,0.28)
SKIN=mat('Skin',(0.96,0.56,0.38),0.0,0.36)
SKIN_ROSE=mat('Cheek',(1.0,0.34,0.24),0.0,0.5)
WHITE=mat('Eye white',(0.99,0.99,0.97),0.0,0.14)
BROWN_EYE=mat('Brown iris',(0.34,0.11,0.015),0.0,0.20)
BLACK=mat('Deep black',(0.006,0.004,0.004),0.15,0.28)
GREEN=mat('Goblin skin',(0.36,0.60,0.10),0.0,0.42)
GREEN_HI=mat('Goblin skin light',(0.55,0.78,0.17),0.0,0.36)
DARK_METAL=mat('Blackened steel',(0.055,0.050,0.050),0.78,0.25)
BRONZE=mat('Antique bronze',(0.45,0.16,0.045),0.76,0.25)
RED=mat('Crimson cloth',(0.62,0.015,0.02),0.05,0.37)
RED_HI=mat('Crimson plume',(0.90,0.035,0.025),0.04,0.31)
TEETH=mat('Teeth',(0.95,0.87,0.69),0,0.32)
STONE=mat('Pedestal stone',(0.12,0.075,0.035),0.20,0.28)

# ---------------- helpers ----------------
def smooth(o):
    if hasattr(o.data,'polygons'):
        for p in o.data.polygons: p.use_smooth=True

def assign(o,m):
    o.data.materials.append(m)

def apply_mod(o, mod):
    bpy.context.view_layer.objects.active=o
    o.select_set(True)
    try: bpy.ops.object.modifier_apply(modifier=mod.name)
    except: pass
    o.select_set(False)

def ellipsoid(name, loc, scale, material, seg=64, rings=32):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=loc)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smooth(o); assign(o,material)
    return o

def rounded_box(name, loc, scale, material, rot=(0,0,0), bevel=0.08):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign(o,material)
    md=o.modifiers.new('Soft bevel','BEVEL'); md.width=bevel; md.segments=4
    apply_mod(o,md)
    smooth(o)
    return o

def cyl(name, loc, radius, depth, material, rot=(0,0,0), vertices=64):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rot)
    o=bpy.context.object; o.name=name; smooth(o); assign(o,material)
    return o

def cone(name, loc, r1, r2, depth, material, rot=(0,0,0), vertices=64):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rot)
    o=bpy.context.object; o.name=name; smooth(o); assign(o,material)
    return o

def torus(name, loc, major, minor, material, rot=(0,0,0), major_segments=64, minor_segments=20):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=major_segments, minor_segments=minor_segments, location=loc, rotation=rot)
    o=bpy.context.object; o.name=name; smooth(o); assign(o,material)
    return o

def curve_tube(name, pts, radius, material, bevel_res=5, taper=1.0):
    cu=bpy.data.curves.new(name,'CURVE'); cu.dimensions='3D'; cu.resolution_u=12; cu.bevel_depth=radius; cu.bevel_resolution=bevel_res; cu.use_fill_caps=True
    sp=cu.splines.new('BEZIER'); sp.bezier_points.add(len(pts)-1)
    for bp,co in zip(sp.bezier_points,pts):
        bp.co=co; bp.handle_left_type='AUTO'; bp.handle_right_type='AUTO'
    o=bpy.data.objects.new(name,cu); bpy.context.collection.objects.link(o); o.data.materials.append(material)
    return o

def convert_curve(o):
    bpy.context.view_layer.objects.active=o; o.select_set(True)
    bpy.ops.object.convert(target='MESH'); o.select_set(False); smooth(o)
    return o

def hemi(name, loc, scale, material, lower_cut=0.0):
    o=ellipsoid(name,loc,scale,material,72,36)
    import bmesh
    bm=bmesh.new(); bm.from_mesh(o.data)
    dead=[v for v in bm.verts if v.co.z < lower_cut]
    bmesh.ops.delete(bm,geom=dead,context='VERTS')
    bm.to_mesh(o.data); bm.free(); o.data.update(); smooth(o)
    sol=o.modifiers.new('Helmet thickness','SOLIDIFY'); sol.thickness=0.035; sol.offset=0.0
    apply_mod(o,sol)
    return o

def cross_parts(prefix, loc, size, thickness, material):
    x,y,z=loc
    a=rounded_box(prefix+'_V',(x,y,z),(size*0.20,thickness,size*0.50),material,bevel=size*0.06)
    b=rounded_box(prefix+'_H',(x,y,z+size*0.10),(size*0.42,thickness,size*0.17),material,bevel=size*0.06)
    return [a,b]

def mesh_prism(name, pts_xz, y0, y1, material):
    n=len(pts_xz); verts=[]
    for y in (y0,y1):
        verts += [(x,y,z) for x,z in pts_xz]
    faces=[]
    faces.append(tuple(range(n)))
    faces.append(tuple(range(2*n-1,n-1,-1)))
    for i in range(n):
        j=(i+1)%n; faces.append((i,j,n+j,n+i))
    me=bpy.data.meshes.new(name); me.from_pydata(verts,[],faces); me.update()
    o=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(o); assign(o,material)
    bev=o.modifiers.new('Edge bevel','BEVEL'); bev.width=0.035; bev.segments=3
    apply_mod(o,bev); smooth(o)
    return o

def plume(prefix, base, color_a, color_b, facing=1.0):
    x0,y0,z0=base
    objs=[]
    for i in range(11):
        u=(i-5)/5
        tip=(x0+0.18*u, y0+0.03*facing + 0.08*abs(u), z0+0.56-0.08*abs(u))
        mid=(x0+0.12*u, y0-0.08*facing, z0+0.30+0.08*(1-u*u))
        c=curve_tube(f'{prefix}_Plume_{i}',[(x0,y0,z0),mid,tip],0.055*(1-0.025*abs(i-5)),color_b if i%3==0 else color_a,4)
        objs.append(convert_curve(c))
    return objs

def make_pedestal(prefix, xoff, dark=False):
    mats=(DARK_METAL,BRONZE) if dark else (STONE,GOLD)
    objs=[]
    objs.append(cyl(prefix+'_Base0',(xoff,0,0.07),0.72,0.14,mats[0]))
    objs.append(cyl(prefix+'_Base1',(xoff,0,0.16),0.65,0.12,mats[1]))
    objs.append(cyl(prefix+'_Base2',(xoff,0,0.23),0.57,0.08,IVORY if not dark else DARK_METAL))
    objs.append(torus(prefix+'_Ring',(xoff,0,0.16),0.64,0.035,GOLD_HI if not dark else BRONZE))
    return objs

def parent_all(root, objs):
    for o in objs:
        if o and o != root: o.parent=root

def build_white(xoff=-1.15):
    objs=[]
    root=bpy.data.objects.new('WhitePawn_ROOT',None); bpy.context.collection.objects.link(root); root.location=(xoff,0,0)
    objs+=make_pedestal('WP',xoff,False)
    for s,x in [('L',xoff-0.23),('R',xoff+0.23)]:
        objs.append(ellipsoid(f'WP_Boot_{s}',(x,-0.075,0.44),(0.23,0.30,0.19),BROWN_HI,52,26))
        objs.append(rounded_box(f'WP_Sole_{s}',(x,-0.13,0.31),(0.25,0.30,0.055),BROWN,bevel=0.055))
        objs.append(torus(f'WP_BootTrim_{s}',(x,-0.02,0.55),0.19,0.024,GOLD,rot=(radians(90),0,0),major_segments=48))
        objs.append(cone(f'WP_Shin_{s}',(x,0,0.72),0.17,0.145,0.33,IVORY_HI))
        objs.append(ellipsoid(f'WP_Knee_{s}',(x,-0.06,0.86),(0.15,0.12,0.11),GOLD,40,20))
    objs.append(cone('WP_Skirt',(xoff,0,1.04),0.43,0.33,0.52,IVORY_HI))
    objs.append(torus('WP_Hem',(xoff,0,0.79),0.42,0.027,GOLD_HI))
    objs.append(ellipsoid('WP_Torso',(xoff,0,1.38),(0.37,0.28,0.40),IVORY,56,28))
    front=mesh_prism('WP_TabardFront',[(xoff-0.20,1.64),(xoff+0.20,1.64),(xoff+0.24,0.88),(xoff,0.78),(xoff-0.24,0.88)],-0.305,-0.225,BLUE); objs.append(front)
    back=mesh_prism('WP_TabardBack',[(xoff-0.20,1.62),(xoff+0.20,1.62),(xoff+0.24,0.88),(xoff,0.80),(xoff-0.24,0.88)],0.225,0.295,BLUE); objs.append(back)
    objs+=cross_parts('WP_ChestCross',(xoff,-0.345,1.30),0.32,0.032,GOLD_HI)
    objs.append(torus('WP_Belt',(xoff,0,1.12),0.34,0.040,BROWN,major_segments=48))
    objs.append(rounded_box('WP_Buckle',(xoff,-0.345,1.12),(0.095,0.035,0.07),GOLD_HI,bevel=0.03))
    objs.append(ellipsoid('WP_PauldronL',(xoff-0.38,-0.01,1.50),(0.20,0.18,0.18),IVORY_HI,44,22))
    objs.append(ellipsoid('WP_ArmL',(xoff-0.53,-0.03,1.31),(0.13,0.13,0.28),IVORY,44,22))
    objs.append(ellipsoid('WP_HandL',(xoff-0.62,-0.10,1.07),(0.14,0.12,0.15),SKIN,44,22))
    objs.append(ellipsoid('WP_PauldronR',(xoff+0.39,-0.01,1.50),(0.20,0.18,0.18),IVORY_HI,44,22))
    objs.append(ellipsoid('WP_ArmR',(xoff+0.52,-0.02,1.30),(0.13,0.13,0.27),IVORY,44,22))
    objs.append(ellipsoid('WP_HandR',(xoff+0.58,-0.12,1.09),(0.14,0.12,0.15),SKIN,44,22))
    objs.append(ellipsoid('WP_Head',(xoff,-0.02,2.02),(0.53,0.45,0.52),SKIN,72,36))
    for s,xx in [('L',xoff-0.49),('R',xoff+0.49)]:
        objs.append(ellipsoid(f'WP_Ear{s}',(xx,-0.01,2.03),(0.10,0.07,0.14),SKIN,36,18))
        objs.append(ellipsoid(f'WP_Hair{s}',(xx,-0.01,2.20),(0.10,0.075,0.18),BROWN,36,18))
    for s,xx in [('L',xoff-0.21),('R',xoff+0.21)]:
        objs.append(ellipsoid(f'WP_EyeW{s}',(xx,-0.435,2.10),(0.18,0.055,0.22),WHITE,48,24))
        objs.append(ellipsoid(f'WP_Iris{s}',(xx,-0.484,2.10),(0.092,0.026,0.125),BROWN_EYE,40,20))
        objs.append(ellipsoid(f'WP_Pupil{s}',(xx,-0.505,2.10),(0.044,0.017,0.070),BLACK,32,16))
        objs.append(ellipsoid(f'WP_Highlight{s}',(xx-0.025,-0.525,2.15),(0.018,0.008,0.025),WHITE,24,12))
    objs.append(ellipsoid('WP_Nose',(xoff,-0.475,1.98),(0.060,0.030,0.052),SKIN_ROSE,32,16))
    for xx in (xoff-0.36,xoff+0.36): objs.append(ellipsoid('WP_Cheek',(xx,-0.41,1.92),(0.10,0.018,0.07),SKIN_ROSE,30,15))
    for s,xx in [('L',xoff-0.20),('R',xoff+0.20)]:
        b=curve_tube(f'WP_Brow{s}',[(xx-0.09,-0.458,2.31),(xx,-0.475,2.34),(xx+0.09,-0.458,2.31)],0.014,BROWN,3); objs.append(convert_curve(b))
    sm=curve_tube('WP_Smile',[(xoff-0.12,-0.476,1.88),(xoff,-0.500,1.83),(xoff+0.13,-0.476,1.88)],0.016,BROWN,3); objs.append(convert_curve(sm))
    objs.append(hemi('WP_Helmet',(xoff,0,2.37),(0.59,0.52,0.44),IVORY,lower_cut=-0.02))
    objs.append(torus('WP_HelmetRim',(xoff,0,2.35),0.55,0.044,GOLD_HI))
    crest=curve_tube('WP_HelmetCrest',[(xoff,-0.505,2.42),(xoff-0.03,-0.535,2.53),(xoff,-0.55,2.64),(xoff+0.03,-0.535,2.53),(xoff,-0.505,2.42)],0.025,GOLD_HI,4); objs.append(convert_curve(crest))
    objs.append(cyl('WP_PlumeSocket',(xoff,0,2.79),0.09,0.16,GOLD_HI))
    objs+=plume('WP',(xoff,0,2.86),BLUE,BLUE_HI)
    sx=xoff-0.73
    objs.append(cyl('WP_SpearShaft',(sx,-0.08,1.58),0.034,2.50,BLUE_HI,vertices=40))
    objs.append(cone('WP_SpearHead',(sx,-0.08,2.98),0.16,0.0,0.46,IVORY_HI,vertices=4))
    objs.append(cone('WP_SpearNeck',(sx,-0.08,2.71),0.065,0.05,0.14,GOLD_HI,vertices=32))
    objs.append(ellipsoid('WP_SpearPommel',(sx,-0.08,0.31),(0.07,0.07,0.07),GOLD_HI,32,16))
    shx=xoff+0.62
    objs.append(cyl('WP_Shield',(shx,-0.18,1.21),0.38,0.10,BLUE,rot=(radians(90),0,0),vertices=72))
    objs.append(torus('WP_ShieldRim',(shx,-0.235,1.21),0.36,0.038,GOLD_HI,rot=(radians(90),0,0),major_segments=72))
    objs+=cross_parts('WP_ShieldCross',(shx,-0.295,1.21),0.46,0.030,GOLD_HI)
    parent_all(root,objs)
    return root,objs

def build_black(xoff=1.15):
    objs=[]
    root=bpy.data.objects.new('BlackPawn_ROOT',None); bpy.context.collection.objects.link(root); root.location=(xoff,0,0)
    objs+=make_pedestal('BP',xoff,True)
    for s,x in [('L',xoff-0.23),('R',xoff+0.23)]:
        objs.append(ellipsoid(f'BP_Boot_{s}',(x,-0.07,0.43),(0.23,0.29,0.19),BROWN,50,25))
        objs.append(rounded_box(f'BP_Sole_{s}',(x,-0.13,0.30),(0.25,0.30,0.055),DARK_METAL,bevel=0.05))
        objs.append(cone(f'BP_Shin_{s}',(x,0,0.69),0.18,0.15,0.33,DARK_METAL))
        objs.append(ellipsoid(f'BP_Knee_{s}',(x,-0.06,0.84),(0.15,0.12,0.11),BRONZE,40,20))
    objs.append(cone('BP_Skirt',(xoff,0,1.02),0.44,0.34,0.50,DARK_METAL))
    objs.append(ellipsoid('BP_Torso',(xoff,0,1.36),(0.38,0.29,0.41),DARK_METAL,56,28))
    objs.append(torus('BP_Belt',(xoff,0,1.12),0.35,0.045,BROWN,major_segments=48))
    objs.append(rounded_box('BP_Buckle',(xoff,-0.35,1.12),(0.10,0.036,0.075),BRONZE,bevel=0.03))
    objs.append(torus('BP_Collar',(xoff,0,1.58),0.34,0.055,RED,major_segments=48))
    cape_pts=[(xoff-0.33,1.55),(xoff+0.33,1.55),(xoff+0.38,0.86),(xoff+0.18,0.78),(xoff,0.86),(xoff-0.17,0.75),(xoff-0.38,0.86)]
    objs.append(mesh_prism('BP_Cape',cape_pts,0.26,0.34,RED))
    objs.append(ellipsoid('BP_PauldronL',(xoff-0.40,-0.02,1.50),(0.22,0.19,0.18),BRONZE,44,22))
    objs.append(ellipsoid('BP_ArmL',(xoff-0.53,-0.02,1.31),(0.14,0.13,0.27),DARK_METAL,44,22))
    objs.append(ellipsoid('BP_HandL',(xoff-0.64,-0.09,1.07),(0.15,0.12,0.15),GREEN_HI,44,22))
    objs.append(ellipsoid('BP_PauldronR',(xoff+0.40,-0.02,1.50),(0.22,0.19,0.18),BRONZE,44,22))
    objs.append(ellipsoid('BP_ArmR',(xoff+0.53,-0.02,1.31),(0.14,0.13,0.27),DARK_METAL,44,22))
    objs.append(ellipsoid('BP_HandR',(xoff+0.62,-0.10,1.08),(0.15,0.12,0.15),GREEN_HI,44,22))
    objs.append(ellipsoid('BP_Head',(xoff,-0.02,2.00),(0.52,0.44,0.48),GREEN,70,35))
    objs.append(cone('BP_EarL',(xoff-0.53,-0.01,2.06),0.13,0.0,0.42,GREEN_HI,rot=(0,radians(-76),radians(4)),vertices=40))
    objs.append(cone('BP_EarR',(xoff+0.53,-0.01,2.06),0.13,0.0,0.42,GREEN_HI,rot=(0,radians(76),radians(-4)),vertices=40))
    eye_y=-0.425
    for s,xx in [('L',xoff-0.20),('R',xoff+0.20)]:
        objs.append(ellipsoid(f'BP_EyeW{s}',(xx,eye_y,2.09),(0.18,0.052,0.20),TEETH,46,23))
        objs.append(ellipsoid(f'BP_Iris{s}',(xx,-0.474,2.08),(0.085,0.024,0.105),RED_HI,36,18))
        objs.append(ellipsoid(f'BP_Pupil{s}',(xx,-0.494,2.08),(0.040,0.015,0.065),BLACK,28,14))
    objs.append(ellipsoid('BP_Nose',(xoff,-0.475,1.96),(0.085,0.035,0.065),GREEN_HI,32,16))
    objs.append(ellipsoid('BP_Mouth',(xoff,-0.445,1.82),(0.25,0.035,0.11),BLACK,40,20))
    for i in range(5):
        xx=xoff-0.15+i*0.075
        objs.append(cone(f'BP_Tooth_{i}',(xx,-0.482,1.84),0.035,0.012,0.10,TEETH,rot=(radians(90),0,0),vertices=20))
    for s,xx,tilt in [('L',xoff-0.20,-1),('R',xoff+0.20,1)]:
        b=curve_tube(f'BP_Brow{s}',[(xx-0.11,-0.454,2.29+0.03*tilt),(xx,-0.477,2.25),(xx+0.11,-0.454,2.29-0.03*tilt)],0.022,BLACK,3); objs.append(convert_curve(b))
    objs.append(hemi('BP_Helmet',(xoff,0,2.36),(0.59,0.52,0.44),DARK_METAL,lower_cut=-0.03))
    objs.append(torus('BP_HelmetRim',(xoff,0,2.34),0.55,0.045,BRONZE))
    for i,a in enumerate([25,90,155,205,270,335]):
        aa=radians(a); objs.append(ellipsoid(f'BP_Rivet{i}',(xoff+0.50*cos(aa),0.43*sin(aa),2.38),(0.028,0.028,0.028),BRONZE,20,10))
    objs.append(cyl('BP_PlumeSocket',(xoff,0,2.79),0.09,0.16,BRONZE))
    objs+=plume('BP',(xoff,0,2.86),RED,RED_HI)
    sx=xoff-0.72
    objs.append(cyl('BP_WeaponShaft',(sx,-0.08,1.50),0.040,2.20,BROWN,vertices=36))
    objs.append(cone('BP_BladeCore',(sx,-0.08,2.76),0.18,0.0,0.48,DARK_METAL,vertices=4))
    objs.append(torus('BP_BladeGuard',(sx,-0.08,2.48),0.09,0.022,BRONZE,rot=(radians(90),0,0),major_segments=32))
    shx=xoff+0.60
    pts=[(shx-0.33,1.52),(shx+0.33,1.52),(shx+0.30,1.05),(shx,0.72),(shx-0.30,1.05)]
    objs.append(mesh_prism('BP_Shield',pts,-0.255,-0.145,DARK_METAL))
    for j,(px,pz) in enumerate([(shx-0.28,1.45),(shx,1.50),(shx+0.28,1.45),(shx+0.25,1.08),(shx,0.80),(shx-0.25,1.08)]):
        objs.append(ellipsoid(f'BP_ShieldStud{j}',(px,-0.29,pz),(0.03,0.018,0.03),BRONZE,20,10))
    slash=rounded_box('BP_ShieldSlash',(shx,-0.31,1.18),(0.26,0.025,0.075),RED,rot=(0,radians(18),radians(-32)),bevel=0.04); objs.append(slash)
    parent_all(root,objs)
    return root,objs

wp,wpobjs=build_white(-1.18)
bp,bpobjs=build_black(1.18)

bpy.ops.mesh.primitive_plane_add(size=16, location=(0,0,-0.01)); floor=bpy.context.object; floor.name='Floor'; assign(floor,mat('Floor',(0.055,0.028,0.018),0.05,0.25))
bpy.ops.mesh.primitive_plane_add(size=10, location=(0,2.4,2.6), rotation=(radians(90),0,0)); back=bpy.context.object; back.name='Backdrop'; assign(back,mat('Backdrop',(0.018,0.010,0.010),0,0.70))

def area(name,loc,energy,color,size):
    d=bpy.data.lights.new(name,'AREA'); d.energy=energy; d.color=color; d.shape='DISK'; d.size=size
    o=bpy.data.objects.new(name,d); bpy.context.collection.objects.link(o); o.location=loc
    direction=Vector((0,0,1.5))-o.location; o.rotation_euler=direction.to_track_quat('-Z','Y').to_euler(); return o
area('Key',(-4.5,-5.5,6.0),1200,(1.0,0.62,0.33),4.0)
area('Fill',(4.5,-3.0,4.5),700,(0.43,0.58,1.0),3.5)
area('Rim',(0,3.5,5.5),1300,(1.0,0.20,0.08),3.0)
for x in (-3.0,3.0):
    d=bpy.data.lights.new('Bounce','POINT'); d.energy=220; d.color=(1.0,0.34,0.10); d.shadow_soft_size=1.6
    o=bpy.data.objects.new('Bounce',d); bpy.context.collection.objects.link(o); o.location=(x,-1.5,1.4)

def look_at(obj,target):
    direction=Vector(target)-obj.location; obj.rotation_euler=direction.to_track_quat('-Z','Y').to_euler()

bpy.ops.object.camera_add(location=(4.8,-8.6,3.35)); cam=bpy.context.object; cam.data.lens=62; scene.camera=cam; look_at(cam,(0,0,1.55))

bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
print('PAWN_SOURCE_BUILD_PASS', SOURCE_BLEND, 'white_parts', len(wpobjs), 'black_parts', len(bpobjs))
