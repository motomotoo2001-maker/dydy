# Battle Chess Revival — White Pawn production asset v1
# Authored procedurally in Blender 5.2.2 from the approved White Pawn concept sheet.
# Output: assets/models/white_pawn_production_v1.glb

import bpy, math, os
from mathutils import Vector, Euler
from math import radians, sin, cos, pi

ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT=os.environ.get('BCR_WHITE_PAWN_OUT', os.path.join(ROOT, 'assets', 'models'))
os.makedirs(OUT, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
try:
    scene.render.engine='BLENDER_EEVEE'
except Exception:
    try:
        scene.render.engine='BLENDER_EEVEE_NEXT'
    except Exception:
        scene.render.engine='BLENDER_WORKBENCH'
scene.render.resolution_x=512
scene.render.resolution_y=512
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.film_transparent=False
scene.render.image_settings.color_mode='RGBA'
scene.render.image_settings.color_depth='8'
scene.render.use_file_extension=True
scene.view_settings.look='AgX - Medium High Contrast'
scene.world=bpy.data.worlds.new('World')
scene.world.color=(0.006,0.004,0.003)

def mat(name, color, metallic=0.0, rough=0.45, emission=None, emission_strength=0):
    m=bpy.data.materials.new(name)
    m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Metallic'].default_value=metallic
    bs.inputs['Roughness'].default_value=rough
    if emission:
        bs.inputs['Emission Color'].default_value=(*emission,1)
        bs.inputs['Emission Strength'].default_value=emission_strength
    return m

GOLD=mat('Gold',(0.78,0.32,0.045),0.88,0.2)
GOLD2=mat('Polished_Gold',(1.0,0.55,0.10),0.92,0.16)
IVORY=mat('Ivory_Enamel',(0.84,0.82,0.72),0.38,0.20)
IVORY2=mat('Warm_Ivory',(0.96,0.92,0.80),0.15,0.28)
LEATHER=mat('Boot_Leather',(0.16,0.055,0.020),0.08,0.30)
LEATHER2=mat('Leather_Highlight',(0.30,0.11,0.035),0.10,0.27)
SKIN=mat('Skin',(0.89,0.46,0.29),0.0,0.40)
SKIN_LIGHT=mat('Skin_Light',(1.0,0.63,0.43),0.0,0.35)
EYEW=mat('Eye_White',(0.98,0.98,0.96),0,0.14)
IRIS=mat('Iris_Brown',(0.25,0.085,0.02),0,0.18)
PUPIL=mat('Pupil',(0.002,0.002,0.002),0,0.25)
HAIR=mat('Hair',(0.12,0.055,0.018),0,0.42)
RED=mat('Plume_Red',(0.55,0.008,0.008),0,0.33)
RED2=mat('Plume_Highlight',(0.90,0.025,0.015),0,0.30)
STONE=mat('Base_Stone',(0.11,0.07,0.035),0.20,0.26)

def smooth(o):
    if hasattr(o.data,'polygons'):
        for p in o.data.polygons: p.use_smooth=True

def assign(o,m):
    o.data.materials.append(m)

def bevel(o,width=0.05,segments=3):
    md=o.modifiers.new('Bevel','BEVEL')
    md.width=width
    md.segments=segments

def uv(name,loc,scale,material,seg=32,rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=loc)
    o=bpy.context.object
    o.name=name
    o.data.name=name
    o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    smooth(o)
    assign(o,material)
    return o

def cube(name,loc,scale,material,rot=(0,0,0),bev=0.08):
    bpy.ops.mesh.primitive_cube_add(location=loc,rotation=rot)
    o=bpy.context.object
    o.name=name
    o.data.name=name
    o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    assign(o,material)
    bevel(o,bev,4)
    return o

def cyl(name,loc,radius,depth,material,rot=(0,0,0),vertices=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc,rotation=rot)
    o=bpy.context.object
    o.name=name
    o.data.name=name
    smooth(o)
    assign(o,material)
    return o

def torus(name,loc,major,minor,material,rot=(0,0,0),major_segments=28,minor_segments=10):
    bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=major_segments,minor_segments=minor_segments,location=loc,rotation=rot)
    o=bpy.context.object
    o.name=name
    o.data.name=name
    smooth(o)
    assign(o,material)
    return o

def cone(name,loc,r1,r2,depth,material,rot=(0,0,0),vertices=20):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r1,radius2=r2,depth=depth,location=loc,rotation=rot)
    o=bpy.context.object
    o.name=name
    o.data.name=name
    smooth(o)
    assign(o,material)
    return o

def curve_tube(name,pts,radius,material,bevel_res=5):
    cu=bpy.data.curves.new(name,'CURVE')
    cu.dimensions='3D'
    cu.resolution_u=12
    cu.bevel_depth=radius
    cu.bevel_resolution=bevel_res
    sp=cu.splines.new('BEZIER')
    sp.bezier_points.add(len(pts)-1)
    for bp,co in zip(sp.bezier_points,pts):
        bp.co=co
        bp.handle_left_type='AUTO'
        bp.handle_right_type='AUTO'
    o=bpy.data.objects.new(name,cu)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(material)
    return o

def feather(name,base,tip,width,material,bend=0.0):
    b=Vector(base)
    t=Vector(tip)
    d=t-b
    n=Vector((1,0,0))
    if abs(d.normalized().dot(n))>0.9:
        n=Vector((0,1,0))
    side=d.cross(n).normalized()
    verts=[]
    faces=[]
    rings=8
    for i in range(rings):
        u=i/(rings-1)
        c=b+d*u+Vector((bend*sin(u*pi),0,0))
        w=width*(sin(pi*u)**0.7)*0.72+width*0.05
        thick=w*0.22
        verts.extend([tuple(c+side*w),tuple(c-side*w),tuple(c+Vector((0,thick,0))),tuple(c-Vector((0,thick,0)))])
        if i:
            a=(i-1)*4
            z=i*4
            faces.extend([(a,z,z+2,a+2),(a+2,z+2,z+1,a+1),(a+1,z+1,z+3,a+3),(a+3,z+3,z,a)])
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    o=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(o)
    assign(o,material)
    smooth(o)
    sub=o.modifiers.new('Subsurf','SUBSURF')
    sub.levels=2
    sub.render_levels=2
    return o

def parent_bone(obj,arm,bone):
    mw=obj.matrix_world.copy()
    obj.parent=arm
    obj.parent_type='BONE'
    obj.parent_bone=bone
    obj.matrix_world=mw

bpy.ops.object.armature_add(enter_editmode=True,location=(0,0,0))
arm=bpy.context.object
arm.name='WhitePawn_Rig'
arm.data.name='WhitePawn_Skeleton'
eb=arm.data.edit_bones
root=eb[0]
root.name='root'
root.head=(0,0,0.05)
root.tail=(0,0,0.45)
def addbone(name,head,tail,parent='root'):
    b=eb.new(name)
    b.head=head
    b.tail=tail
    b.parent=eb.get(parent)
    return b
addbone('pelvis',(0,0,0.55),(0,0,1.05))
addbone('spine',(0,0,1.0),(0,0,1.55),'pelvis')
addbone('neck',(0,0,1.50),(0,0,1.78),'spine')
addbone('head',(0,0,1.72),(0,0,2.42),'neck')
addbone('upper_arm.L',(-0.18,0,1.45),(-0.58,0,1.30),'spine')
addbone('forearm.L',(-0.58,0,1.30),(-0.72,-0.02,1.04),'upper_arm.L')
addbone('hand.L',(-0.72,-0.02,1.04),(-0.76,-0.02,0.91),'forearm.L')
addbone('upper_arm.R',(0.18,0,1.45),(0.58,0,1.30),'spine')
addbone('forearm.R',(0.58,0,1.30),(0.72,-0.02,1.04),'upper_arm.R')
addbone('hand.R',(0.72,-0.02,1.04),(0.76,-0.02,0.91),'forearm.R')
addbone('thigh.L',(-0.18,0,0.88),(-0.22,0,0.52),'pelvis')
addbone('shin.L',(-0.22,0,0.52),(-0.23,0,0.25),'thigh.L')
addbone('foot.L',(-0.23,0,0.25),(-0.23,-0.24,0.12),'shin.L')
addbone('thigh.R',(0.18,0,0.88),(0.22,0,0.52),'pelvis')
addbone('shin.R',(0.22,0,0.52),(0.23,0,0.25),'thigh.R')
addbone('foot.R',(0.23,0,0.25),(0.23,-0.24,0.12),'shin.R')
addbone('weapon',(-0.76,-0.02,0.95),(-0.76,-0.02,2.0),'hand.L')
addbone('plume',(0,0,2.55),(0,0,3.12),'head')
bpy.ops.object.mode_set(mode='OBJECT')

base_objs=[]
base_objs.append(cyl('Base_Lower',(0,0,0.09),0.70,0.18,STONE))
base_objs.append(cyl('Base_Mid',(0,0,0.18),0.63,0.12,LEATHER))
base_objs.append(cyl('Base_Upper',(0,0,0.27),0.55,0.08,GOLD))
base_objs.append(torus('Base_GoldRing',(0,0,0.17),0.64,0.035,GOLD2))
base_objs.append(torus('Base_GoldRing2',(0,0,0.05),0.69,0.028,GOLD2))
for i in range(16):
    a=2*pi*i/16
    r=0.60
    base_objs.append(uv(f'BaseStud_{i}',(r*cos(a),r*sin(a),0.155),(0.035,0.035,0.028),GOLD2,16,8))

parts=[]
for side,x in [('L',-0.23),('R',0.23)]:
    parts.append((uv(f'Boot_{side}',(x,-0.05,0.42),(0.23,0.30,0.20),LEATHER,16,8),f'foot.{side}'))
    parts.append((cube(f'Sole_{side}',(x,-0.12,0.29),(0.25,0.32,0.06),LEATHER2,bev=0.06),f'foot.{side}'))
    parts.append((uv(f'ToeCap_{side}',(x,-0.24,0.42),(0.22,0.20,0.14),LEATHER2,28,14),f'foot.{side}'))
    parts.append((torus(f'BootBand_{side}',(x,-0.05,0.51),0.19,0.025,GOLD,rot=(radians(90),0,0),major_segments=28),f'shin.{side}'))
    parts.append((cone(f'ShinArmor_{side}',(x,0.0,0.67),0.18,0.15,0.34,IVORY2),f'shin.{side}'))
    parts.append((uv(f'Knee_{side}',(x,-0.055,0.84),(0.16,0.13,0.11),GOLD,16,8),f'thigh.{side}'))

parts.append((cone('SkirtArmor',(0,0,1.02),0.44,0.34,0.58,IVORY2),'pelvis'))
for z,r in [(0.74,0.43),(1.28,0.34)]:
    parts.append((torus(f'ArmorTrim_{z}',(0,0,z),r,0.028,GOLD2),'pelvis' if z<1 else 'spine'))
parts.append((uv('Torso',(0,0,1.35),(0.38,0.29,0.43),IVORY,16,8),'spine'))
parts.append((uv('ChestPlate',(0,-0.22,1.43),(0.30,0.07,0.30),IVORY2,28,14),'spine'))
parts.append((torus('Belt',(0,0,1.11),0.35,0.045,LEATHER,major_segments=24),'pelvis'))
parts.append((cube('Buckle',(0,-0.37,1.10),(0.10,0.035,0.085),GOLD2,bev=0.03),'pelvis'))
parts.append((curve_tube('Chest_Emblem',[(-0.13,-0.305,1.55),(0,-0.34,1.46),(0.13,-0.305,1.55)],0.025,GOLD2),'spine'))

for side,x,sgn in [('L',-0.48,-1),('R',0.48,1)]:
    parts.append((uv(f'Pauldron_{side}',(x*0.85,-0.01,1.52),(0.20,0.18,0.18),IVORY2,28,14),f'upper_arm.{side}'))
    parts.append((cone(f'UpperArm_{side}',(x*1.05,0,1.33),0.13,0.11,0.34,IVORY,rot=(0,radians(12*sgn),radians(7*sgn))),f'upper_arm.{side}'))
    parts.append((torus(f'Cuff_{side}',(x*1.32,-0.005,1.14),0.115,0.023,GOLD,rot=(0,radians(90),0),major_segments=28),f'forearm.{side}'))
    parts.append((cone(f'Forearm_{side}',(x*1.32,0,1.12),0.12,0.095,0.27,IVORY2,rot=(0,radians(7*sgn),radians(9*sgn))),f'forearm.{side}'))
    parts.append((uv(f'Hand_{side}',(x*1.48,-0.03,0.99),(0.15,0.13,0.15),SKIN_LIGHT,28,14),f'hand.{side}'))
    parts.append((uv(f'Gauntlet_{side}',(x*1.45,0.055,1.02),(0.13,0.05,0.12),GOLD,16,8),f'hand.{side}'))

parts.append((uv('Head',(0,-0.015,2.03),(0.54,0.48,0.53),SKIN_LIGHT,64,32),'head'))
for x in (-0.38,0.38):
    parts.append((uv('Cheek',(x,-0.405,1.96),(0.15,0.07,0.13),SKIN,16,8),'head'))
for side,x in [('L',-0.53),('R',0.53)]:
    parts.append((uv(f'Ear_{side}',(x,-0.01,2.03),(0.11,0.07,0.15),SKIN,16,8),'head'))
    parts.append((uv(f'HairLock_{side}',(x*0.87,-0.03,2.18),(0.10,0.08,0.22),HAIR,16,8),'head'))
for side,x in [('L',-0.21),('R',0.21)]:
    parts.append((uv(f'EyeWhite_{side}',(x,-0.455,2.12),(0.19,0.055,0.23),EYEW,16,8),'head'))
    parts.append((uv(f'Iris_{side}',(x,-0.505,2.105),(0.090,0.028,0.120),IRIS,28,14),'head'))
    parts.append((uv(f'Pupil_{side}',(x,-0.525,2.11),(0.045,0.018,0.067),PUPIL,16,8),'head'))
    parts.append((uv(f'EyeHighlight_{side}',(x-0.02,-0.543,2.16),(0.016,0.008,0.022),EYEW,16,8),'head'))
for side,x,tilt in [('L',-0.21,-0.08),('R',0.21,0.08)]:
    parts.append((curve_tube(f'Brow_{side}',[(x-0.10,-0.505,2.34),(x,-0.525,2.37+tilt),(x+0.10,-0.505,2.34)],0.018,HAIR,3),'head'))
parts.append((uv('Nose',(0,-0.535,1.98),(0.065,0.035,0.055),SKIN,16,8),'head'))
parts.append((curve_tube('Smile',[(-0.10,-0.535,1.87),(0,-0.553,1.83),(0.12,-0.535,1.88)],0.018,HAIR,3),'head'))

bpy.ops.mesh.primitive_uv_sphere_add(segments=36,ring_count=18,location=(0,0,2.37))
helm=bpy.context.object
helm.name='Helmet_Dome'
helm.data.name='Helmet_Dome'
helm.scale=(0.59,0.53,0.44)
bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
me=helm.data
for p in me.polygons: p.use_smooth=True
import bmesh
bm=bmesh.new()
bm.from_mesh(me)
kill=[v for v in bm.verts if v.co.z < -0.02]
bmesh.ops.delete(bm,geom=kill,context='VERTS')
bm.to_mesh(me)
bm.free()
me.update()
assign(helm,IVORY)
parts.append((helm,'head'))
parts.append((torus('Helmet_Rim',(0,0,2.35),0.545,0.045,GOLD2),'head'))
for i,a in enumerate([radians(25),radians(155),radians(205),radians(335)]):
    parts.append((uv(f'HelmetRivet_{i}',(0.50*cos(a),0.44*sin(a),2.39),(0.032,0.032,0.032),GOLD2,16,8),'head'))
parts.append((curve_tube('Helmet_Crest',[(0,-0.52,2.43),(-0.03,-0.55,2.54),(0,-0.56,2.64),(0.03,-0.55,2.54),(0,-0.52,2.43)],0.027,GOLD2,4),'head'))
parts.append((cyl('PlumeSocket',(0,0,2.78),0.10,0.18,GOLD2),'plume'))
for i in range(16):
    ang=(i-7.5)*0.12
    base=(0.0,0.02,2.84)
    tip=(0.14*math.sin(ang),-0.02+0.12*math.cos(i*0.8),3.30+0.12*math.cos(ang))
    parts.append((feather(f'Production_Plume_{i}',base,tip,0.11*(1-0.02*abs(i-7.5)),RED2 if i%3==0 else RED,bend=0.08*math.sin(i*1.7)),'plume'))

parts.append((cyl('Spear_Shaft',(-0.79,-0.08,1.55),0.035,2.55,GOLD,vertices=20),'weapon'))
for z in [0.56,1.05,2.18]:
    parts.append((torus(f'SpearBand_{z}',(-0.79,-0.08,z),0.05,0.013,GOLD2,major_segments=24),'weapon'))
parts.append((cone('Spear_Head',(-0.79,-0.08,2.98),0.16,0.0,0.48,IVORY2,vertices=4),'weapon'))
parts.append((cone('SpearNeck',(-0.79,-0.08,2.68),0.07,0.05,0.14,GOLD2,vertices=20),'weapon'))
parts.append((uv('Spear_Pommel',(-0.79,-0.08,0.26),(0.08,0.08,0.08),GOLD2,16,8),'weapon'))

for o,b in parts:
    parent_bone(o,arm,b)
for o in base_objs:
    parent_bone(o,arm,'root')
for side,x in [('L',-0.30),('R',0.30)]:
    parent_bone(curve_tube(f'ChestEdge_{side}',[(x,-0.31,1.62),(x*1.07,-0.34,1.46),(x*0.95,-0.31,1.27)],0.020,GOLD2,3),arm,'spine')

bpy.context.view_layer.objects.active=arm
arm.select_set(True)
act=bpy.data.actions.new('ToeStab')
arm.animation_data_create()
arm.animation_data.action=act
scene.render.fps=30

def keybone(name,frame,loc=None,rot=None,scale=None):
    pb=arm.pose.bones[name]
    pb.rotation_mode='XYZ'
    if loc is not None:
        pb.location=loc
        pb.keyframe_insert('location',frame=frame)
    if rot is not None:
        pb.rotation_euler=Euler(tuple(radians(v) for v in rot),'XYZ')
        pb.keyframe_insert('rotation_euler',frame=frame)
    if scale is not None:
        pb.scale=scale
        pb.keyframe_insert('scale',frame=frame)

bones=['root','pelvis','spine','head','upper_arm.L','forearm.L','hand.L','upper_arm.R','forearm.R','hand.R','thigh.L','shin.L','foot.L','thigh.R','shin.R','foot.R','weapon','plume']
for bn in bones:
    keybone(bn,1,loc=(0,0,0),rot=(0,0,0))
keybone('pelvis',8,loc=(0,0.05,0.02),rot=(0,0,-5))
keybone('spine',8,rot=(-4,0,7))
keybone('upper_arm.L',8,rot=(10,-12,-30))
keybone('forearm.L',8,rot=(15,5,-25))
keybone('weapon',8,rot=(0,20,8))
keybone('head',8,rot=(0,0,-7))
keybone('plume',8,rot=(8,0,10))
keybone('root',15,loc=(0,-0.18,0))
keybone('pelvis',15,loc=(0,-0.06,-0.03),rot=(7,0,8))
keybone('spine',15,rot=(14,0,-8))
keybone('upper_arm.L',15,rot=(30,-20,38))
keybone('forearm.L',15,rot=(-25,5,25))
keybone('hand.L',15,rot=(15,0,0))
keybone('weapon',15,rot=(48,0,-8))
keybone('head',15,rot=(7,0,5))
keybone('foot.R',15,rot=(-12,0,0))
keybone('plume',15,rot=(-18,0,-14))
for bn in ['root','pelvis','spine','upper_arm.L','forearm.L','hand.L','weapon','head','foot.R','plume']:
    pb=arm.pose.bones[bn]
    pb.keyframe_insert('location',frame=19)
    pb.keyframe_insert('rotation_euler',frame=19)
for bn in bones:
    keybone(bn,32,loc=(0,0,0),rot=(0,0,0))
scene.frame_start=1
scene.frame_end=32

bpy.ops.mesh.primitive_plane_add(size=14,location=(0,0,-0.01))
g=bpy.context.object
g.name='Ground'
assign(g,mat('GroundMat',(0.055,0.025,0.015),0.05,0.24))
bpy.ops.mesh.primitive_plane_add(size=7,location=(0,1.35,2.0),rotation=(radians(90),0,0))
bd=bpy.context.object
bd.name='Backdrop'
assign(bd,mat('BackdropMat',(0.025,0.010,0.006),0,0.65))

def area(name,loc,energy,color,size,rot=(0,0,0)):
    data=bpy.data.lights.new(name,'AREA')
    data.energy=energy
    data.color=color
    data.shape='DISK'
    data.size=size
    o=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(o)
    o.location=loc
    o.rotation_euler=rot
    return o

area('Key',(-4,-5,6),1150,(1.0,0.64,0.35),4.5,(radians(35),0,radians(-32)))
area('Fill',(4,-2,4),700,(0.45,0.58,1.0),3.5,(radians(55),0,radians(55)))
area('Rim',(0,3,5),1200,(1.0,0.18,0.06),3.0,(radians(120),0,radians(180)))
ld=bpy.data.lights.new('WarmBounce','POINT')
ld.energy=320
ld.color=(1.0,0.38,0.12)
ld.shadow_soft_size=2
lo=bpy.data.objects.new('WarmBounce',ld)
bpy.context.collection.objects.link(lo)
lo.location=(0,-1.2,1.2)

bpy.ops.object.camera_add(location=(4.15,-7.2,3.30))
cam=bpy.context.object
cam.name='Camera'
cam.data.lens=58
scene.camera=cam
def look_at(obj,target):
    direction=Vector(target)-obj.location
    obj.rotation_euler=direction.to_track_quat('-Z','Y').to_euler()
look_at(cam,(0,0,1.55))

scene.frame_set(1)
if os.environ.get('BCR_SAVE_BLEND') == '1':
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'white_pawn_production_v1.blend'))

arm.scale=(0.59,0.59,0.59)
arm.rotation_euler=(0.0,0.0,math.pi)
bpy.context.view_layer.update()
bpy.ops.object.select_all(action='DESELECT')
arm.select_set(True)
for obj in bpy.data.objects:
    if obj == arm or obj.parent == arm:
        obj.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'white_pawn_production_v1.glb'),export_format='GLB',use_selection=True,export_animations=True,export_cameras=False,export_lights=False,export_apply=True)
print('WHITE_PAWN_EXPORT_OK',os.path.join(OUT,'white_pawn_production_v1.glb'))
