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

func reset_visual() -> void:
	if visual_root == null:
		return
	visual_root.position = Vector3.ZERO
	visual_root.rotation = Vector3.ZERO
	visual_root.scale = Vector3.ONE
	visible = true
	reset_tint()

func set_tint(color: Color) -> void:
	for material in _base_materials:
		material.albedo_color = color

func reset_tint() -> void:
	for i in range(mini(_base_materials.size(), _base_colors.size())):
		_base_materials[i].albedo_color = _base_colors[i]

func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	var main_color := Color("#eee3c9") if side == &"White" else Color("#241b31")
	var accent_color := Color("#c69b49") if side == &"White" else Color("#7045b8")

	_add_cylinder("Base", 0.36, 0.10, Vector3(0, 0.05, 0), main_color)

	var height := _piece_height(piece_type)
	match piece_type:
		&"Pawn":
			_add_capsule("Body", 0.22, 0.70, Vector3(0, 0.48, 0), main_color)
			_add_sphere("Head", 0.23, Vector3(0, 0.88, 0), main_color)
			_add_box("Spear", Vector3(0.05, 0.72, 0.05), Vector3(0.28, 0.66, 0), accent_color)
		&"Knight":
			_add_capsule("HorseBody", 0.30, 0.90, Vector3(0, 0.64, 0), main_color)
			_add_box("HorseHead", Vector3(0.42, 0.34, 0.34), Vector3(0.22, 1.05, 0), main_color)
			_add_capsule("Rider", 0.18, 0.52, Vector3(-0.08, 1.24, 0), accent_color)
		&"Bishop":
			_add_cylinder("Body", 0.27, 0.98, Vector3(0, 0.62, 0), main_color)
			_add_sphere("Head", 0.25, Vector3(0, 1.20, 0), main_color)
			_add_box("Staff", Vector3(0.06, 1.25, 0.06), Vector3(0.34, 0.83, 0), accent_color)
		&"Rook":
			_add_box("Tower", Vector3(0.66, 1.05, 0.66), Vector3(0, 0.61, 0), main_color)
			_add_box("Crown", Vector3(0.78, 0.22, 0.78), Vector3(0, 1.23, 0), accent_color)
		&"Queen":
			_add_cylinder("Body", 0.31, 1.12, Vector3(0, 0.69, 0), main_color)
			_add_sphere("Head", 0.25, Vector3(0, 1.40, 0), main_color)
			_add_box("Wand", Vector3(0.05, 0.92, 0.05), Vector3(0.37, 0.95, 0), accent_color)
			_add_sphere("MagicOrb", 0.10, Vector3(0.37, 1.43, 0), accent_color)
		&"King":
			_add_cylinder("Body", 0.34, 1.15, Vector3(0, 0.70, 0), main_color)
			_add_sphere("Head", 0.27, Vector3(0, 1.43, 0), main_color)
			_add_box("Crown", Vector3(0.52, 0.18, 0.52), Vector3(0, 1.75, 0), accent_color)
		_:
			_add_capsule("Body", 0.25, height * 0.70, Vector3(0, height * 0.45, 0), main_color)

func _build_anchors() -> void:
	battle_target = _marker("BattleTarget", Vector3(0, 0.85, 0))
	foot_target = _marker("FootTarget", Vector3(0, 0.12, 0))
	head_target = _marker("HeadTarget", Vector3(0, _piece_height(piece_type) * 0.88, 0))
	weapon_socket = _marker("WeaponSocket", Vector3(0.32, 0.72, 0))
	vfx_anchor = _marker("VFXAnchor", Vector3(0, 0.80, 0))

func _marker(marker_name: String, p: Vector3) -> Marker3D:
	var m := Marker3D.new()
	m.name = marker_name
	m.position = p
	add_child(m)
	return m

func _piece_height(t: StringName) -> float:
	match t:
		&"Pawn": return 1.05
		&"Knight": return 1.55
		&"Bishop": return 1.65
		&"Rook": return 1.45
		&"Queen": return 1.75
		&"King": return 1.85
	return 1.20

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.32
	mat.metallic = 0.08
	_base_materials.append(mat)
	_base_colors.append(color)
	return mat

func _add_box(node_name: String, size: Vector3, p: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = p
	mi.material_override = _material(color)
	visual_root.add_child(mi)

func _add_cylinder(node_name: String, radius: float, height: float, p: Vector3, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = p
	mi.material_override = _material(color)
	visual_root.add_child(mi)

func _add_capsule(node_name: String, radius: float, height: float, p: Vector3, color: Color) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = p
	mi.material_override = _material(color)
	visual_root.add_child(mi)

func _add_sphere(node_name: String, radius: float, p: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = p
	mi.material_override = _material(color)
	visual_root.add_child(mi)

func change_type(new_type: StringName) -> void:
	piece_type = new_type
	_base_materials.clear()
	_base_colors.clear()
	for child in get_children():
		child.free()
	_build_visual()
	_build_anchors()
