class_name PieceView
extends Node3D

var piece_type: StringName = &"Pawn"
var side: StringName = &"White"
var home_square: StringName = &"A1"
var current_square: StringName = &"A1"

var visual_root: Node3D
var battle_target: Marker3D
var foot_target: Marker3D
var head_target: Marker3D
var weapon_socket: Marker3D
var vfx_anchor: Marker3D

var _base_materials: Array[StandardMaterial3D] = []
var _base_colors: Array[Color] = []

func setup(
	p_piece_type: StringName,
	p_side: StringName,
	p_square: StringName,
	world_position: Vector3
) -> void:
	piece_type = p_piece_type
	side = p_side
	home_square = p_square
	current_square = p_square
	name = "%s_%s_%s" % [String(side), String(piece_type), String(home_square)]
	position = world_position
	_build_visual()
	_build_anchors()
	_apply_rest_pose()

func reset_visual() -> void:
	if visual_root == null:
		return
	visual_root.position = Vector3.ZERO
	visual_root.rotation = Vector3.ZERO
	_apply_rest_pose()
	visible = true
	reset_tint()

func set_tint(color: Color) -> void:
	for material in _base_materials:
		material.albedo_color = color

func reset_tint() -> void:
	for i in range(mini(_base_materials.size(), _base_colors.size())):
		_base_materials[i].albedo_color = _base_colors[i]

func change_type(new_type: StringName) -> void:
	piece_type = new_type
	_base_materials.clear()
	_base_colors.clear()
	for child in get_children():
		child.free()
	_build_visual()
	_build_anchors()
	_apply_rest_pose()

func _apply_rest_pose() -> void:
	if visual_root == null:
		return
	visual_root.scale = Vector3.ONE * _design_scale(piece_type)

func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	if piece_type == &"Pawn" and side == &"White":
		_build_white_pawn_production_blockout()
		return

	var main_color := Color("#e9dfca") if side == &"White" else Color("#271d31")
	var accent_color := Color("#c69b49") if side == &"White" else Color("#7647b8")
	_add_cylinder_color("Base", 0.37, 0.10, Vector3(0, 0.05, 0), main_color)

	var height := _piece_height(piece_type)
	match piece_type:
		&"Pawn":
			_add_capsule_color("Body", 0.23, 0.72, Vector3(0, 0.49, 0), main_color)
			_add_sphere_color("Head", 0.24, Vector3(0, 0.91, 0), main_color)
			_add_box_color("Spear", Vector3(0.05, 0.78, 0.05), Vector3(0.29, 0.70, 0), accent_color)
		&"Knight":
			_add_capsule_color("HorseBody", 0.31, 0.95, Vector3(0, 0.66, 0), main_color)
			_add_box_color("HorseHead", Vector3(0.44, 0.36, 0.36), Vector3(0.23, 1.10, 0), main_color)
			_add_capsule_color("Rider", 0.19, 0.56, Vector3(-0.08, 1.31, 0), accent_color)
		&"Bishop":
			_add_cylinder_color("Body", 0.28, 1.02, Vector3(0, 0.64, 0), main_color)
			_add_sphere_color("Head", 0.26, Vector3(0, 1.25, 0), main_color)
			_add_box_color("Staff", Vector3(0.06, 1.32, 0.06), Vector3(0.36, 0.87, 0), accent_color)
		&"Rook":
			_add_box_color("Tower", Vector3(0.69, 1.10, 0.69), Vector3(0, 0.64, 0), main_color)
			_add_box_color("Crown", Vector3(0.82, 0.23, 0.82), Vector3(0, 1.29, 0), accent_color)
		&"Queen":
			_add_cylinder_color("Body", 0.32, 1.18, Vector3(0, 0.72, 0), main_color)
			_add_sphere_color("Head", 0.26, Vector3(0, 1.47, 0), main_color)
			_add_box_color("Wand", Vector3(0.05, 0.98, 0.05), Vector3(0.38, 1.00, 0), accent_color)
			_add_sphere_color("MagicOrb", 0.11, Vector3(0.38, 1.51, 0), accent_color)
		&"King":
			_add_cylinder_color("Body", 0.35, 1.20, Vector3(0, 0.73, 0), main_color)
			_add_sphere_color("Head", 0.28, Vector3(0, 1.49, 0), main_color)
			_add_box_color("Crown", Vector3(0.55, 0.20, 0.55), Vector3(0, 1.82, 0), accent_color)
		_:
			_add_capsule_color("Body", 0.25, height * 0.70, Vector3(0, height * 0.45, 0), main_color)

func _build_white_pawn_production_blockout() -> void:
	visual_root.name = "VisualRoot_WhitePawnProductionV1"

	var ivory := _material(Color("#e8e1d6"))
	ivory.roughness = 0.54
	ivory.metallic = 0.0
	var ivory_dark := _material(Color("#b8ad9b"))
	ivory_dark.roughness = 0.62
	var blue := _material(Color("#31577f"))
	blue.roughness = 0.48
	var gold := _material(Color("#c79a43"))
	gold.roughness = 0.27
	gold.metallic = 0.72
	var bronze := _material(Color("#7a532f"))
	bronze.roughness = 0.34
	bronze.metallic = 0.58
	var leather := _material(Color("#4b3024"))
	leather.roughness = 0.72
	var skin := _material(Color("#d59f78"))
	skin.roughness = 0.58
	var dark := _material(Color("#211d20"))
	dark.roughness = 0.48
	var eye := _material(Color("#25374d"))
	eye.roughness = 0.22

	# Chess pedestal.
	_add_cylinder_mat("PedestalLower", 0.43, 0.08, Vector3(0, 0.04, 0), dark)
	_add_cylinder_mat("PedestalGoldRing", 0.39, 0.045, Vector3(0, 0.105, 0), gold)
	_add_cylinder_mat("PedestalUpper", 0.35, 0.09, Vector3(0, 0.165, 0), ivory_dark)

	# Oversized boots and separated legs for a rig-friendly silhouette.
	_add_capsule_mat("Boot_L", 0.115, 0.30, Vector3(-0.14, 0.31, 0.045), leather, Vector3(90, 0, 0))
	_add_capsule_mat("Boot_R", 0.115, 0.30, Vector3(0.14, 0.31, 0.045), leather, Vector3(90, 0, 0))
	_add_capsule_mat("Leg_L", 0.085, 0.34, Vector3(-0.13, 0.48, 0), blue)
	_add_capsule_mat("Leg_R", 0.085, 0.34, Vector3(0.13, 0.48, 0), blue)

	# Chunky torso + belt.
	_add_capsule_mat("Torso", 0.265, 0.62, Vector3(0, 0.76, 0), ivory)
	_add_box_mat("Belt", Vector3(0.54, 0.10, 0.30), Vector3(0, 0.66, 0), leather)
	_add_box_mat("BeltBuckle", Vector3(0.12, 0.11, 0.035), Vector3(0, 0.66, 0.17), gold)

	# Shoulders / arms.
	_add_sphere_mat("Shoulder_L", 0.16, Vector3(-0.30, 0.92, 0), ivory_dark, Vector3(1.1, 0.75, 1.0))
	_add_sphere_mat("Shoulder_R", 0.16, Vector3(0.30, 0.92, 0), ivory_dark, Vector3(1.1, 0.75, 1.0))
	_add_capsule_mat("Arm_L", 0.085, 0.39, Vector3(-0.34, 0.77, 0), ivory, Vector3(0, 0, -18))
	_add_capsule_mat("Arm_R", 0.085, 0.39, Vector3(0.34, 0.77, 0), ivory, Vector3(0, 0, 16))
	_add_sphere_mat("Hand_L", 0.095, Vector3(-0.39, 0.60, 0), skin)
	_add_sphere_mat("Hand_R", 0.095, Vector3(0.39, 0.60, 0), skin)

	# Shield on the left arm.
	var shield_mesh := CylinderMesh.new()
	shield_mesh.top_radius = 0.29
	shield_mesh.bottom_radius = 0.29
	shield_mesh.height = 0.075
	var shield := MeshInstance3D.new()
	shield.name = "Shield"
	shield.mesh = shield_mesh
	shield.material_override = blue
	shield.position = Vector3(-0.43, 0.72, 0.02)
	shield.rotation_degrees = Vector3(0, 0, 90)
	visual_root.add_child(shield)
	_add_box_mat("ShieldCrossV", Vector3(0.05, 0.34, 0.05), Vector3(-0.47, 0.72, 0.02), gold)
	_add_box_mat("ShieldCrossH", Vector3(0.05, 0.05, 0.34), Vector3(-0.47, 0.72, 0.02), gold)

	# Head and expressive readable face.
	_add_sphere_mat("Head", 0.235, Vector3(0, 1.14, 0.015), skin, Vector3(1.0, 0.98, 0.92))
	_add_sphere_mat("Nose", 0.055, Vector3(0, 1.12, 0.225), skin, Vector3(0.85, 0.75, 1.2))
	_add_sphere_mat("Eye_L", 0.027, Vector3(-0.075, 1.18, 0.222), eye)
	_add_sphere_mat("Eye_R", 0.027, Vector3(0.075, 1.18, 0.222), eye)
	_add_box_mat("Brow_L", Vector3(0.09, 0.018, 0.018), Vector3(-0.078, 1.235, 0.222), dark)
	_add_box_mat("Brow_R", Vector3(0.09, 0.018, 0.018), Vector3(0.078, 1.235, 0.222), dark)

	# Oversized rounded helmet with gold rim and blue crest.
	_add_sphere_mat("HelmetDome", 0.265, Vector3(0, 1.30, -0.005), ivory_dark, Vector3(1.06, 0.72, 1.04))
	_add_box_mat("HelmetRim", Vector3(0.54, 0.06, 0.34), Vector3(0, 1.245, 0.02), gold)
	_add_box_mat("HelmetNoseGuard", Vector3(0.055, 0.23, 0.045), Vector3(0, 1.14, 0.235), gold)
	_add_box_mat("HelmetCrest", Vector3(0.10, 0.30, 0.16), Vector3(0, 1.50, -0.03), blue, Vector3(0, 0, -8))

	# Short spear, deliberately compact so it does not collide with neighbors.
	_add_cylinder_mat("SpearShaft", 0.026, 0.92, Vector3(0.40, 0.89, 0.02), bronze, Vector3(0, 0, -7))
	var tip_mesh := CylinderMesh.new()
	tip_mesh.top_radius = 0.0
	tip_mesh.bottom_radius = 0.075
	tip_mesh.height = 0.20
	var tip := MeshInstance3D.new()
	tip.name = "SpearTip"
	tip.mesh = tip_mesh
	tip.material_override = gold
	tip.position = Vector3(0.51, 1.36, 0.02)
	tip.rotation_degrees = Vector3(0, 0, -7)
	visual_root.add_child(tip)

func _build_anchors() -> void:
	battle_target = _marker("BattleTarget", Vector3(0, 0.82, 0))
	foot_target = _marker("FootTarget", Vector3(0, 0.22, 0))
	head_target = _marker("HeadTarget", Vector3(0, _piece_height(piece_type) * 0.88, 0))
	weapon_socket = _marker("WeaponSocket", Vector3(0.38, 0.82, 0))
	vfx_anchor = _marker("VFXAnchor", Vector3(0, 0.90, 0))

func _marker(marker_name: String, p: Vector3) -> Marker3D:
	var m := Marker3D.new()
	m.name = marker_name
	m.position = p
	add_child(m)
	return m

func _piece_height(t: StringName) -> float:
	match t:
		&"Pawn": return 1.42
		&"Knight": return 1.60
		&"Bishop": return 1.70
		&"Rook": return 1.50
		&"Queen": return 1.82
		&"King": return 1.90
	return 1.20

func _design_scale(t: StringName) -> float:
	match t:
		&"Pawn": return 1.02
		&"Knight": return 1.08
		&"Bishop": return 1.07
		&"Rook": return 1.08
		&"Queen": return 1.06
		&"King": return 1.06
	return 1.0

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.34
	mat.metallic = 0.06
	_base_materials.append(mat)
	_base_colors.append(color)
	return mat

func _add_box_color(node_name: String, size: Vector3, p: Vector3, color: Color) -> void:
	_add_box_mat(node_name, size, p, _material(color))

func _add_cylinder_color(node_name: String, radius: float, height: float, p: Vector3, color: Color) -> void:
	_add_cylinder_mat(node_name, radius, height, p, _material(color))

func _add_capsule_color(node_name: String, radius: float, height: float, p: Vector3, color: Color) -> void:
	_add_capsule_mat(node_name, radius, height, p, _material(color))

func _add_sphere_color(node_name: String, radius: float, p: Vector3, color: Color) -> void:
	_add_sphere_mat(node_name, radius, p, _material(color))

func _add_box_mat(
	node_name: String,
	size: Vector3,
	p: Vector3,
	material: Material,
	rotation_deg: Vector3 = Vector3.ZERO
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = p
	mi.rotation_degrees = rotation_deg
	mi.material_override = material
	visual_root.add_child(mi)

func _add_cylinder_mat(
	node_name: String,
	radius: float,
	height: float,
	p: Vector3,
	material: Material,
	rotation_deg: Vector3 = Vector3.ZERO
) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = p
	mi.rotation_degrees = rotation_deg
	mi.material_override = material
	visual_root.add_child(mi)

func _add_capsule_mat(
	node_name: String,
	radius: float,
	height: float,
	p: Vector3,
	material: Material,
	rotation_deg: Vector3 = Vector3.ZERO
) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = p
	mi.rotation_degrees = rotation_deg
	mi.material_override = material
	visual_root.add_child(mi)

func _add_sphere_mat(
	node_name: String,
	radius: float,
	p: Vector3,
	material: Material,
	scale_value: Vector3 = Vector3.ONE
) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = p
	mi.scale = scale_value
	mi.material_override = material
	visual_root.add_child(mi)
