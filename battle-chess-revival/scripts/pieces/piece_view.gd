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
	rotation_degrees.y = 180.0 if side == &"Black" else 0.0
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
	if piece_type == &"Pawn" and side == &"Black":
		_build_black_pawn_production_blockout()
		return
	if piece_type == &"Knight" and side == &"White":
		_build_white_knight_production_blockout()
		return
	if piece_type == &"Knight" and side == &"Black":
		_build_black_knight_production_blockout()
		return
	if piece_type == &"Bishop" and side == &"White":
		_build_white_bishop_production_blockout()
		return
	if piece_type == &"Bishop" and side == &"Black":
		_build_black_bishop_production_blockout()
		return
	if piece_type == &"Rook" and side == &"White":
		_build_white_rook_production_blockout()
		return
	if piece_type == &"Rook" and side == &"Black":
		_build_black_rook_production_blockout()
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
	_add_sphere_mat("Nose", 0.055, Vector3(0, 1.12, -0.225), skin, Vector3(0.85, 0.75, 1.2))
	_add_sphere_mat("Eye_L", 0.027, Vector3(-0.075, 1.18, -0.222), eye)
	_add_sphere_mat("Eye_R", 0.027, Vector3(0.075, 1.18, -0.222), eye)
	_add_box_mat("Brow_L", Vector3(0.09, 0.018, 0.018), Vector3(-0.078, 1.235, -0.222), dark)
	_add_box_mat("Brow_R", Vector3(0.09, 0.018, 0.018), Vector3(0.078, 1.235, -0.222), dark)

	# Oversized rounded helmet with gold rim and blue crest.
	_add_sphere_mat("HelmetDome", 0.265, Vector3(0, 1.30, -0.005), ivory_dark, Vector3(1.06, 0.72, 1.04))
	_add_box_mat("HelmetRim", Vector3(0.54, 0.06, 0.34), Vector3(0, 1.245, -0.02), gold)
	_add_box_mat("HelmetNoseGuard", Vector3(0.055, 0.23, 0.045), Vector3(0, 1.14, -0.235), gold)
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

func _build_black_pawn_production_blockout() -> void:
	visual_root.name = "VisualRoot_BlackPawnProductionV1"

	var charcoal := _material(Color("#302a31"))
	charcoal.roughness = 0.56
	var leather := _material(Color("#4b342c"))
	leather.roughness = 0.72
	var leather_dark := _material(Color("#241c20"))
	leather_dark.roughness = 0.68
	var bronze := _material(Color("#79583b"))
	bronze.roughness = 0.38
	bronze.metallic = 0.42
	var violet := _material(Color("#5b426e"))
	violet.roughness = 0.46
	var green := _material(Color("#718250"))
	green.roughness = 0.60
	var green_dark := _material(Color("#465330"))
	green_dark.roughness = 0.62
	var red := _material(Color("#8d3943"))
	red.roughness = 0.46
	var eye := _material(Color("#d4bf68"))
	eye.roughness = 0.18
	var steel := _material(Color("#8b8a86"))
	steel.roughness = 0.29
	steel.metallic = 0.66

	# Dark chess pedestal, still readable as a pawn.
	_add_cylinder_mat("PedestalLower", 0.43, 0.08, Vector3(0, 0.04, 0), leather_dark)
	_add_cylinder_mat("PedestalRing", 0.39, 0.045, Vector3(0, 0.105, 0), bronze)
	_add_cylinder_mat("PedestalUpper", 0.35, 0.09, Vector3(0, 0.165, 0), charcoal)

	# Short goblin proportions: big boots, thin legs, chunky torso.
	_add_capsule_mat("Boot_L", 0.12, 0.30, Vector3(-0.14, 0.31, 0.045), leather_dark, Vector3(90, 0, 0))
	_add_capsule_mat("Boot_R", 0.12, 0.30, Vector3(0.14, 0.31, 0.045), leather_dark, Vector3(90, 0, 0))
	_add_capsule_mat("Leg_L", 0.08, 0.31, Vector3(-0.13, 0.47, 0), charcoal)
	_add_capsule_mat("Leg_R", 0.08, 0.31, Vector3(0.13, 0.47, 0), charcoal)
	_add_capsule_mat("Torso", 0.255, 0.58, Vector3(0, 0.75, 0), leather)
	_add_box_mat("ChestPlate", Vector3(0.42, 0.28, 0.08), Vector3(0, 0.82, -0.22), charcoal)
	_add_box_mat("Belt", Vector3(0.52, 0.09, 0.30), Vector3(0, 0.65, 0), leather_dark)
	_add_box_mat("BeltBuckle", Vector3(0.10, 0.09, 0.035), Vector3(0, 0.65, -0.17), bronze)

	# Long goblin arms and oversized hands.
	_add_sphere_mat("Shoulder_L", 0.14, Vector3(-0.29, 0.91, 0), charcoal, Vector3(1.08, 0.78, 1.0))
	_add_sphere_mat("Shoulder_R", 0.14, Vector3(0.29, 0.91, 0), charcoal, Vector3(1.08, 0.78, 1.0))
	_add_capsule_mat("Arm_L", 0.075, 0.40, Vector3(-0.34, 0.74, 0), green_dark, Vector3(0, 0, -17))
	_add_capsule_mat("Arm_R", 0.075, 0.40, Vector3(0.34, 0.74, 0), green_dark, Vector3(0, 0, 18))
	_add_sphere_mat("Hand_L", 0.095, Vector3(-0.39, 0.57, 0), green)
	_add_sphere_mat("Hand_R", 0.095, Vector3(0.39, 0.57, 0), green)

	# Crooked shield.
	var shield_mesh := CylinderMesh.new()
	shield_mesh.top_radius = 0.27
	shield_mesh.bottom_radius = 0.27
	shield_mesh.height = 0.075
	var shield := MeshInstance3D.new()
	shield.name = "Shield"
	shield.mesh = shield_mesh
	shield.material_override = charcoal
	shield.position = Vector3(-0.43, 0.70, -0.02)
	shield.rotation_degrees = Vector3(0, 0, 90)
	visual_root.add_child(shield)
	_add_box_mat("ShieldMarkV", Vector3(0.045, 0.31, 0.05), Vector3(-0.47, 0.70, -0.02), red, Vector3(0, 0, 18))
	_add_box_mat("ShieldMarkH", Vector3(0.045, 0.05, 0.28), Vector3(-0.47, 0.70, -0.02), red, Vector3(0, 0, -16))

	# Expressive goblin head: large nose, ears, glowing eyes and angry brows.
	_add_sphere_mat("Head", 0.235, Vector3(0, 1.13, -0.01), green, Vector3(1.03, 0.93, 0.92))
	_add_sphere_mat("Nose", 0.070, Vector3(0, 1.10, -0.225), green_dark, Vector3(1.05, 0.72, 1.32))
	_add_sphere_mat("Ear_L", 0.115, Vector3(-0.25, 1.14, -0.02), green, Vector3(1.55, 0.55, 0.72))
	_add_sphere_mat("Ear_R", 0.115, Vector3(0.25, 1.14, -0.02), green, Vector3(1.55, 0.55, 0.72))
	_add_sphere_mat("Eye_L", 0.031, Vector3(-0.075, 1.18, -0.216), eye)
	_add_sphere_mat("Eye_R", 0.031, Vector3(0.075, 1.18, -0.216), eye)
	_add_box_mat("Brow_L", Vector3(0.10, 0.022, 0.018), Vector3(-0.078, 1.235, -0.220), leather_dark, Vector3(0, 0, -14))
	_add_box_mat("Brow_R", Vector3(0.10, 0.022, 0.018), Vector3(0.078, 1.235, -0.220), leather_dark, Vector3(0, 0, 14))

	# Bucket helmet, deliberately asymmetrical and worn-looking.
	_add_cylinder_mat("HelmetBucket", 0.255, 0.25, Vector3(0, 1.34, 0), bronze)
	_add_box_mat("HelmetBand", Vector3(0.54, 0.06, 0.36), Vector3(0, 1.25, -0.01), leather_dark)
	_add_box_mat("HelmetPatch", Vector3(0.16, 0.10, 0.025), Vector3(0.11, 1.39, -0.255), violet, Vector3(0, 0, 11))

	# Short knife used by the toe-stab capture.
	_add_cylinder_mat("KnifeGrip", 0.035, 0.24, Vector3(0.41, 0.68, -0.03), leather_dark, Vector3(0, 0, -58))
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.055, 0.30, 0.025)
	var blade := MeshInstance3D.new()
	blade.name = "KnifeBlade"
	blade.mesh = blade_mesh
	blade.material_override = steel
	blade.position = Vector3(0.50, 0.55, -0.03)
	blade.rotation_degrees = Vector3(0, 0, -58)
	visual_root.add_child(blade)

func _build_white_knight_production_blockout() -> void:
	visual_root.name = "VisualRoot_WhiteKnightProductionV1"

	var ivory := _material(Color("#e9e1d4"))
	ivory.roughness = 0.48
	var ivory_shadow := _material(Color("#c5b9aa"))
	ivory_shadow.roughness = 0.56
	var blue := _material(Color("#355d86"))
	blue.roughness = 0.44
	var gold := _material(Color("#c89b46"))
	gold.roughness = 0.25
	gold.metallic = 0.72
	var leather := _material(Color("#4b3328"))
	leather.roughness = 0.70
	var skin := _material(Color("#d9a27b"))
	skin.roughness = 0.56
	var dark := _material(Color("#252127"))
	dark.roughness = 0.42
	var eye := _material(Color("#26384f"))
	eye.roughness = 0.18

	_add_cylinder_mat("PedestalLower", 0.45, 0.08, Vector3(0, 0.04, 0), dark)
	_add_cylinder_mat("PedestalRing", 0.41, 0.045, Vector3(0, 0.105, 0), gold)
	_add_cylinder_mat("PedestalUpper", 0.37, 0.09, Vector3(0, 0.165, 0), ivory_shadow)

	# Horse body and four separated legs.
	_add_sphere_mat("HorseBody", 0.34, Vector3(0, 0.72, 0.03), ivory, Vector3(1.08, 0.82, 1.42))
	for x in [-0.20, 0.20]:
		for z in [-0.19, 0.21]:
			_add_capsule_mat("HorseLeg", 0.075, 0.52, Vector3(x, 0.43, z), ivory_shadow)
			_add_capsule_mat("Hoof", 0.095, 0.20, Vector3(x, 0.22, z - 0.02), leather, Vector3(90, 0, 0))

	# Neck and expressive head, projecting toward the enemy side (-Z).
	_add_capsule_mat("HorseNeck", 0.18, 0.62, Vector3(0, 1.02, -0.24), ivory, Vector3(-28, 0, 0))
	_add_sphere_mat("HorseHead", 0.24, Vector3(0, 1.26, -0.46), ivory, Vector3(0.92, 0.78, 1.30))
	_add_sphere_mat("Muzzle", 0.16, Vector3(0, 1.17, -0.68), ivory_shadow, Vector3(1.0, 0.76, 1.15))
	_add_sphere_mat("Eye_L", 0.032, Vector3(-0.13, 1.34, -0.61), eye)
	_add_sphere_mat("Eye_R", 0.032, Vector3(0.13, 1.34, -0.61), eye)
	_add_sphere_mat("Ear_L", 0.075, Vector3(-0.12, 1.50, -0.43), ivory, Vector3(0.65, 1.45, 0.55))
	_add_sphere_mat("Ear_R", 0.075, Vector3(0.12, 1.50, -0.43), ivory, Vector3(0.65, 1.45, 0.55))
	_add_box_mat("Mane", Vector3(0.12, 0.56, 0.13), Vector3(0, 1.21, -0.22), blue, Vector3(-18, 0, 0))

	# Saddle and rider.
	_add_box_mat("Saddle", Vector3(0.44, 0.12, 0.50), Vector3(0, 1.00, 0.13), leather)
	_add_capsule_mat("RiderTorso", 0.18, 0.48, Vector3(0, 1.31, 0.14), ivory_shadow)
	_add_sphere_mat("RiderHead", 0.15, Vector3(0, 1.62, 0.09), skin)
	_add_sphere_mat("RiderHelmet", 0.18, Vector3(0, 1.70, 0.09), ivory_shadow, Vector3(1.0, 0.65, 1.0))
	_add_box_mat("HelmetBand", Vector3(0.38, 0.05, 0.26), Vector3(0, 1.65, 0.02), gold)
	_add_box_mat("Plume", Vector3(0.09, 0.30, 0.11), Vector3(0, 1.91, 0.12), blue, Vector3(0, 0, -8))

	# Rider arms, shield and compact lance.
	_add_capsule_mat("RiderArm_L", 0.055, 0.30, Vector3(-0.22, 1.36, 0.09), ivory_shadow, Vector3(0, 0, -28))
	_add_capsule_mat("RiderArm_R", 0.055, 0.30, Vector3(0.22, 1.36, 0.09), ivory_shadow, Vector3(0, 0, 22))
	var shield_mesh := CylinderMesh.new()
	shield_mesh.top_radius = 0.20
	shield_mesh.bottom_radius = 0.20
	shield_mesh.height = 0.055
	var shield := MeshInstance3D.new()
	shield.name = "KnightShield"
	shield.mesh = shield_mesh
	shield.material_override = blue
	shield.position = Vector3(-0.31, 1.28, 0.05)
	shield.rotation_degrees = Vector3(0, 0, 90)
	visual_root.add_child(shield)
	_add_box_mat("ShieldStripe", Vector3(0.04, 0.24, 0.04), Vector3(-0.34, 1.28, 0.05), gold)

	_add_cylinder_mat("Lance", 0.025, 0.95, Vector3(0.31, 1.36, -0.24), leather, Vector3(42, 0, 0))
	var tip_mesh := CylinderMesh.new()
	tip_mesh.top_radius = 0.0
	tip_mesh.bottom_radius = 0.07
	tip_mesh.height = 0.18
	var tip := MeshInstance3D.new()
	tip.name = "LanceTip"
	tip.mesh = tip_mesh
	tip.material_override = gold
	tip.position = Vector3(0.31, 1.68, -0.55)
	tip.rotation_degrees = Vector3(42, 0, 0)
	visual_root.add_child(tip)

func _build_black_knight_production_blockout() -> void:
	visual_root.name = "VisualRoot_BlackKnightProductionV1"

	var charcoal := _material(Color("#2a2530"))
	charcoal.roughness = 0.52
	var black := _material(Color("#15151b"))
	black.roughness = 0.48
	var bone := _material(Color("#9a948b"))
	bone.roughness = 0.56
	var violet := _material(Color("#6d3f8c"))
	violet.roughness = 0.40
	var steel := _material(Color("#57545e"))
	steel.roughness = 0.30
	steel.metallic = 0.58
	var leather := _material(Color("#3a2927"))
	leather.roughness = 0.72
	var glow := _material(Color("#b66bf0"))
	glow.roughness = 0.15
	glow.emission_enabled = true
	glow.emission = Color("#9c55d8")
	glow.emission_energy_multiplier = 2.2

	_add_cylinder_mat("PedestalLower", 0.45, 0.08, Vector3(0, 0.04, 0), black)
	_add_cylinder_mat("PedestalRing", 0.41, 0.045, Vector3(0, 0.105, 0), violet)
	_add_cylinder_mat("PedestalUpper", 0.37, 0.09, Vector3(0, 0.165, 0), charcoal)

	# Lean nightmare horse with bony joints and oversized hooves.
	_add_sphere_mat("HorseBody", 0.33, Vector3(0, 0.72, 0.04), charcoal, Vector3(1.02, 0.76, 1.45))
	for x in [-0.20, 0.20]:
		for z in [-0.19, 0.21]:
			_add_capsule_mat("HorseLeg", 0.067, 0.53, Vector3(x, 0.43, z), black)
			_add_sphere_mat("Knee", 0.085, Vector3(x, 0.48, z), bone)
			_add_capsule_mat("Hoof", 0.105, 0.21, Vector3(x, 0.21, z - 0.03), black, Vector3(90, 0, 0))

	_add_capsule_mat("HorseNeck", 0.17, 0.65, Vector3(0, 1.03, -0.25), charcoal, Vector3(-30, 0, 0))
	_add_sphere_mat("HorseHead", 0.23, Vector3(0, 1.28, -0.47), charcoal, Vector3(0.88, 0.73, 1.34))
	_add_sphere_mat("Muzzle", 0.15, Vector3(0, 1.18, -0.70), black, Vector3(1.0, 0.70, 1.18))
	_add_sphere_mat("Eye_L", 0.034, Vector3(-0.13, 1.34, -0.62), glow)
	_add_sphere_mat("Eye_R", 0.034, Vector3(0.13, 1.34, -0.62), glow)
	_add_box_mat("Mane", Vector3(0.11, 0.61, 0.13), Vector3(0, 1.22, -0.21), violet, Vector3(-20, 0, 0))
	_add_cylinder_mat("Horn_L", 0.035, 0.24, Vector3(-0.12, 1.50, -0.45), bone, Vector3(-30, 0, -28))
	_add_cylinder_mat("Horn_R", 0.035, 0.24, Vector3(0.12, 1.50, -0.45), bone, Vector3(-30, 0, 28))

	# Dark rider with horned helmet.
	_add_box_mat("Saddle", Vector3(0.44, 0.12, 0.50), Vector3(0, 1.00, 0.13), leather)
	_add_capsule_mat("RiderTorso", 0.18, 0.50, Vector3(0, 1.31, 0.14), steel)
	_add_sphere_mat("RiderHead", 0.145, Vector3(0, 1.62, 0.09), black)
	_add_sphere_mat("RiderHelmet", 0.18, Vector3(0, 1.70, 0.09), charcoal, Vector3(1.0, 0.66, 1.0))
	_add_cylinder_mat("HelmetHorn_L", 0.028, 0.25, Vector3(-0.13, 1.84, 0.06), bone, Vector3(0, 0, -38))
	_add_cylinder_mat("HelmetHorn_R", 0.028, 0.25, Vector3(0.13, 1.84, 0.06), bone, Vector3(0, 0, 38))
	_add_sphere_mat("VisorGlow_L", 0.025, Vector3(-0.055, 1.69, -0.09), glow)
	_add_sphere_mat("VisorGlow_R", 0.025, Vector3(0.055, 1.69, -0.09), glow)

	_add_capsule_mat("RiderArm_L", 0.055, 0.31, Vector3(-0.22, 1.36, 0.09), steel, Vector3(0, 0, -30))
	_add_capsule_mat("RiderArm_R", 0.055, 0.31, Vector3(0.22, 1.36, 0.09), steel, Vector3(0, 0, 24))
	var shield_mesh := CylinderMesh.new()
	shield_mesh.top_radius = 0.20
	shield_mesh.bottom_radius = 0.20
	shield_mesh.height = 0.055
	var shield := MeshInstance3D.new()
	shield.name = "KnightShield"
	shield.mesh = shield_mesh
	shield.material_override = charcoal
	shield.position = Vector3(-0.31, 1.28, 0.05)
	shield.rotation_degrees = Vector3(0, 0, 90)
	visual_root.add_child(shield)
	_add_box_mat("ShieldRune", Vector3(0.045, 0.24, 0.04), Vector3(-0.34, 1.28, 0.05), violet, Vector3(0, 0, 18))

	_add_cylinder_mat("Lance", 0.025, 0.95, Vector3(0.31, 1.36, -0.24), black, Vector3(42, 0, 0))
	var tip_mesh := CylinderMesh.new()
	tip_mesh.top_radius = 0.0
	tip_mesh.bottom_radius = 0.07
	tip_mesh.height = 0.18
	var tip := MeshInstance3D.new()
	tip.name = "LanceTip"
	tip.mesh = tip_mesh
	tip.material_override = violet
	tip.position = Vector3(0.31, 1.68, -0.55)
	tip.rotation_degrees = Vector3(42, 0, 0)
	visual_root.add_child(tip)

func _build_white_bishop_production_blockout() -> void:
	visual_root.name = "VisualRoot_WhiteBishopProductionV1"
	var ivory := _material(Color("#e7ddd0")); ivory.roughness = 0.52
	var ivory_shadow := _material(Color("#c8bbad")); ivory_shadow.roughness = 0.58
	var gold := _material(Color("#c69a48")); gold.roughness = 0.25; gold.metallic = 0.68
	var blue := _material(Color("#3f668a")); blue.roughness = 0.46
	var skin := _material(Color("#b9a68f")); skin.roughness = 0.62
	var dark := _material(Color("#252126")); dark.roughness = 0.48
	var eye := _material(Color("#334559")); eye.roughness = 0.18
	var staff_wood := _material(Color("#5a3b2b")); staff_wood.roughness = 0.70
	var gem := _material(Color("#5fc5d4")); gem.roughness = 0.12; gem.emission_enabled = true; gem.emission = Color("#4fa8bd"); gem.emission_energy_multiplier = 1.7

	_add_cylinder_mat("PedestalLower", 0.44, 0.08, Vector3(0, 0.04, 0), dark)
	_add_cylinder_mat("PedestalRing", 0.40, 0.045, Vector3(0, 0.105, 0), gold)
	_add_cylinder_mat("PedestalUpper", 0.36, 0.09, Vector3(0, 0.165, 0), ivory_shadow)

	# Long ceremonial robe.
	_add_cylinder_mat("RobeLower", 0.29, 0.72, Vector3(0, 0.55, 0), ivory)
	_add_capsule_mat("Torso", 0.22, 0.55, Vector3(0, 0.95, 0), ivory_shadow)
	_add_box_mat("Sash", Vector3(0.08, 0.72, 0.34), Vector3(0, 0.72, -0.17), blue, Vector3(0, 0, 6))
	_add_box_mat("Collar", Vector3(0.50, 0.10, 0.36), Vector3(0, 1.15, 0), gold)

	# Elephant-like bishop head: huge ears + short trunk for readable charge silhouette.
	_add_sphere_mat("Head", 0.23, Vector3(0, 1.35, -0.02), skin, Vector3(0.95, 1.0, 0.92))
	_add_sphere_mat("Ear_L", 0.20, Vector3(-0.23, 1.36, -0.01), ivory_shadow, Vector3(0.65, 1.15, 0.50))
	_add_sphere_mat("Ear_R", 0.20, Vector3(0.23, 1.36, -0.01), ivory_shadow, Vector3(0.65, 1.15, 0.50))
	_add_capsule_mat("Trunk", 0.065, 0.42, Vector3(0, 1.18, -0.23), skin, Vector3(25, 0, 0))
	_add_sphere_mat("Eye_L", 0.028, Vector3(-0.08, 1.40, -0.22), eye)
	_add_sphere_mat("Eye_R", 0.028, Vector3(0.08, 1.40, -0.22), eye)

	# Tall bishop mitre.
	_add_box_mat("MitreBase", Vector3(0.38, 0.20, 0.30), Vector3(0, 1.58, -0.01), ivory_shadow)
	_add_box_mat("MitreTall", Vector3(0.28, 0.46, 0.22), Vector3(0, 1.83, -0.01), ivory, Vector3(0, 0, 8))
	_add_box_mat("MitreStripe", Vector3(0.055, 0.48, 0.025), Vector3(0, 1.83, -0.13), gold, Vector3(0, 0, 8))

	# Arms and ornate staff.
	_add_capsule_mat("Arm_L", 0.075, 0.38, Vector3(-0.28, 1.03, 0), ivory_shadow, Vector3(0, 0, -14))
	_add_capsule_mat("Arm_R", 0.075, 0.38, Vector3(0.28, 1.03, 0), ivory_shadow, Vector3(0, 0, 14))
	_add_sphere_mat("Hand_L", 0.085, Vector3(-0.32, 0.87, -0.02), skin)
	_add_sphere_mat("Hand_R", 0.085, Vector3(0.32, 0.87, -0.02), skin)
	_add_cylinder_mat("Staff", 0.028, 1.35, Vector3(0.40, 1.05, -0.02), staff_wood, Vector3(0, 0, -4))
	_add_sphere_mat("StaffGem", 0.105, Vector3(0.44, 1.73, -0.02), gem)
	_add_cylinder_mat("StaffHalo", 0.035, 0.30, Vector3(0.44, 1.63, -0.02), gold, Vector3(90, 0, 0))

func _build_black_bishop_production_blockout() -> void:
	visual_root.name = "VisualRoot_BlackBishopProductionV1"
	var charcoal := _material(Color("#26232c")); charcoal.roughness = 0.52
	var violet := _material(Color("#654080")); violet.roughness = 0.43
	var bone := _material(Color("#9d9688")); bone.roughness = 0.58
	var leather := _material(Color("#3c2b2b")); leather.roughness = 0.70
	var steel := _material(Color("#56515b")); steel.roughness = 0.30; steel.metallic = 0.55
	var glow := _material(Color("#b959ef")); glow.roughness = 0.14; glow.emission_enabled = true; glow.emission = Color("#a64adb"); glow.emission_energy_multiplier = 2.4
	var red := _material(Color("#7d3444")); red.roughness = 0.46

	_add_cylinder_mat("PedestalLower", 0.44, 0.08, Vector3(0, 0.04, 0), charcoal)
	_add_cylinder_mat("PedestalRing", 0.40, 0.045, Vector3(0, 0.105, 0), violet)
	_add_cylinder_mat("PedestalUpper", 0.36, 0.09, Vector3(0, 0.165, 0), steel)

	_add_cylinder_mat("RobeLower", 0.30, 0.75, Vector3(0, 0.57, 0), charcoal)
	_add_capsule_mat("Torso", 0.22, 0.55, Vector3(0, 0.98, 0), leather)
	_add_box_mat("RobePanel", Vector3(0.15, 0.75, 0.34), Vector3(0, 0.73, -0.17), violet, Vector3(0, 0, -5))
	_add_box_mat("ShoulderPlate_L", Vector3(0.28, 0.12, 0.34), Vector3(-0.22, 1.17, 0), steel, Vector3(0, 0, -10))
	_add_box_mat("ShoulderPlate_R", Vector3(0.28, 0.12, 0.34), Vector3(0.22, 1.17, 0), steel, Vector3(0, 0, 10))

	# Necromancer/ram head with horned ceremonial mask.
	_add_sphere_mat("Head", 0.22, Vector3(0, 1.38, -0.02), bone, Vector3(0.90, 1.04, 0.90))
	_add_capsule_mat("Snout", 0.07, 0.34, Vector3(0, 1.26, -0.23), bone, Vector3(30, 0, 0))
	_add_sphere_mat("Eye_L", 0.030, Vector3(-0.075, 1.43, -0.215), glow)
	_add_sphere_mat("Eye_R", 0.030, Vector3(0.075, 1.43, -0.215), glow)
	_add_cylinder_mat("Horn_L", 0.035, 0.40, Vector3(-0.15, 1.62, -0.02), bone, Vector3(0, 0, -35))
	_add_cylinder_mat("Horn_R", 0.035, 0.40, Vector3(0.15, 1.62, -0.02), bone, Vector3(0, 0, 35))
	_add_box_mat("CrownMask", Vector3(0.36, 0.24, 0.25), Vector3(0, 1.60, -0.01), charcoal)
	_add_box_mat("MaskRune", Vector3(0.05, 0.25, 0.025), Vector3(0, 1.60, -0.145), red)

	_add_capsule_mat("Arm_L", 0.075, 0.40, Vector3(-0.28, 1.02, 0), leather, Vector3(0, 0, -16))
	_add_capsule_mat("Arm_R", 0.075, 0.40, Vector3(0.28, 1.02, 0), leather, Vector3(0, 0, 16))
	_add_cylinder_mat("Staff", 0.030, 1.38, Vector3(0.40, 1.05, -0.02), steel, Vector3(0, 0, -4))
	_add_sphere_mat("StaffOrb", 0.11, Vector3(0.44, 1.75, -0.02), glow)
	_add_box_mat("StaffProng_L", Vector3(0.045, 0.28, 0.05), Vector3(0.36, 1.77, -0.02), bone, Vector3(0, 0, -28))
	_add_box_mat("StaffProng_R", Vector3(0.045, 0.28, 0.05), Vector3(0.52, 1.77, -0.02), bone, Vector3(0, 0, 28))

func _build_white_rook_production_blockout() -> void:
	visual_root.name = "VisualRoot_WhiteRookProductionV1"
	var stone := _material(Color("#b9b1a6")); stone.roughness = 0.78
	var stone_light := _material(Color("#d6cec2")); stone_light.roughness = 0.72
	var stone_dark := _material(Color("#817a73")); stone_dark.roughness = 0.82
	var gold := _material(Color("#bd9141")); gold.roughness = 0.27; gold.metallic = 0.66
	var blue := _material(Color("#42698c")); blue.roughness = 0.50
	var eye := _material(Color("#6fd0df")); eye.roughness = 0.12; eye.emission_enabled = true; eye.emission = Color("#54b5ca"); eye.emission_energy_multiplier = 1.8
	var dark := _material(Color("#2a2728")); dark.roughness = 0.52

	_add_cylinder_mat("PedestalLower", 0.48, 0.09, Vector3(0, 0.045, 0), dark)
	_add_cylinder_mat("PedestalRing", 0.44, 0.05, Vector3(0, 0.115, 0), gold)
	_add_cylinder_mat("PedestalUpper", 0.40, 0.10, Vector3(0, 0.19, 0), stone_dark)

	# Castle-golem body with heavy shoulders and articulated fists.
	_add_box_mat("TowerCore", Vector3(0.62, 0.92, 0.62), Vector3(0, 0.72, 0), stone)
	_add_box_mat("ChestPlate", Vector3(0.68, 0.28, 0.68), Vector3(0, 0.91, -0.03), stone_light)
	_add_box_mat("BeltBand", Vector3(0.68, 0.10, 0.68), Vector3(0, 0.50, 0), gold)
	_add_box_mat("Shoulder_L", Vector3(0.28, 0.25, 0.34), Vector3(-0.43, 0.93, 0), stone_dark, Vector3(0,0,-10))
	_add_box_mat("Shoulder_R", Vector3(0.28, 0.25, 0.34), Vector3(0.43, 0.93, 0), stone_dark, Vector3(0,0,10))
	_add_box_mat("Arm_L", Vector3(0.20, 0.48, 0.22), Vector3(-0.48, 0.68, 0), stone, Vector3(0,0,-8))
	_add_box_mat("Arm_R", Vector3(0.20, 0.48, 0.22), Vector3(0.48, 0.68, 0), stone, Vector3(0,0,8))
	_add_box_mat("Fist_L", Vector3(0.28, 0.24, 0.28), Vector3(-0.52, 0.43, -0.02), stone_dark)
	_add_box_mat("Fist_R", Vector3(0.28, 0.24, 0.28), Vector3(0.52, 0.43, -0.02), stone_dark)

	# Angry face carved into the tower.
	_add_box_mat("Brow_L", Vector3(0.18, 0.07, 0.08), Vector3(-0.15, 1.04, -0.34), stone_dark, Vector3(0,0,-10))
	_add_box_mat("Brow_R", Vector3(0.18, 0.07, 0.08), Vector3(0.15, 1.04, -0.34), stone_dark, Vector3(0,0,10))
	_add_sphere_mat("Eye_L", 0.055, Vector3(-0.15, 0.98, -0.35), eye, Vector3(1.2,0.75,0.55))
	_add_sphere_mat("Eye_R", 0.055, Vector3(0.15, 0.98, -0.35), eye, Vector3(1.2,0.75,0.55))
	_add_box_mat("Mouth", Vector3(0.30, 0.06, 0.06), Vector3(0, 0.83, -0.35), dark)

	# Crenellated castle top.
	_add_box_mat("CrownBase", Vector3(0.78, 0.18, 0.78), Vector3(0, 1.26, 0), stone_light)
	for x in [-0.28, 0.0, 0.28]:
		_add_box_mat("CrenelFront", Vector3(0.18, 0.24, 0.20), Vector3(x, 1.45, -0.28), stone)
		_add_box_mat("CrenelBack", Vector3(0.18, 0.24, 0.20), Vector3(x, 1.45, 0.28), stone)
	for z in [-0.04, 0.18]:
		_add_box_mat("CrenelSideL", Vector3(0.20, 0.24, 0.18), Vector3(-0.28, 1.45, z), stone)
		_add_box_mat("CrenelSideR", Vector3(0.20, 0.24, 0.18), Vector3(0.28, 1.45, z), stone)

	# Small blue heraldic plate.
	_add_box_mat("Heraldry", Vector3(0.26, 0.30, 0.035), Vector3(0, 0.69, -0.33), blue)
	_add_box_mat("HeraldryCrossV", Vector3(0.045, 0.24, 0.045), Vector3(0, 0.69, -0.36), gold)
	_add_box_mat("HeraldryCrossH", Vector3(0.20, 0.045, 0.045), Vector3(0, 0.69, -0.36), gold)

func _build_black_rook_production_blockout() -> void:
	visual_root.name = "VisualRoot_BlackRookProductionV1"
	var obsidian := _material(Color("#242127")); obsidian.roughness = 0.40; obsidian.metallic = 0.15
	var obsidian_light := _material(Color("#3a343c")); obsidian_light.roughness = 0.46
	var lava := _material(Color("#c45127")); lava.roughness = 0.18; lava.emission_enabled = true; lava.emission = Color("#e35c24"); lava.emission_energy_multiplier = 2.2
	var ember := _material(Color("#f0a13a")); ember.roughness = 0.12; ember.emission_enabled = true; ember.emission = Color("#ff9d32"); ember.emission_energy_multiplier = 3.0
	var steel := _material(Color("#5a4d52")); steel.roughness = 0.32; steel.metallic = 0.48
	var violet := _material(Color("#5c3c74")); violet.roughness = 0.45
	var dark := _material(Color("#121216")); dark.roughness = 0.50

	_add_cylinder_mat("PedestalLower", 0.48, 0.09, Vector3(0, 0.045, 0), dark)
	_add_cylinder_mat("PedestalRing", 0.44, 0.05, Vector3(0, 0.115, 0), lava)
	_add_cylinder_mat("PedestalUpper", 0.40, 0.10, Vector3(0, 0.19, 0), obsidian)

	_add_box_mat("TowerCore", Vector3(0.64, 0.94, 0.64), Vector3(0, 0.72, 0), obsidian)
	_add_box_mat("ChestPlate", Vector3(0.70, 0.28, 0.70), Vector3(0, 0.91, -0.03), obsidian_light)
	_add_box_mat("LavaCrackV", Vector3(0.055, 0.64, 0.035), Vector3(-0.10, 0.75, -0.335), lava, Vector3(0,0,12))
	_add_box_mat("LavaCrackH", Vector3(0.34, 0.045, 0.035), Vector3(0.03, 0.72, -0.338), ember, Vector3(0,0,-16))

	_add_box_mat("Shoulder_L", Vector3(0.30, 0.26, 0.36), Vector3(-0.44, 0.94, 0), steel, Vector3(0,0,-12))
	_add_box_mat("Shoulder_R", Vector3(0.30, 0.26, 0.36), Vector3(0.44, 0.94, 0), steel, Vector3(0,0,12))
	_add_box_mat("Arm_L", Vector3(0.20, 0.50, 0.22), Vector3(-0.49, 0.68, 0), obsidian_light, Vector3(0,0,-10))
	_add_box_mat("Arm_R", Vector3(0.20, 0.50, 0.22), Vector3(0.49, 0.68, 0), obsidian_light, Vector3(0,0,10))
	_add_box_mat("Fist_L", Vector3(0.30, 0.25, 0.30), Vector3(-0.54, 0.42, -0.02), obsidian)
	_add_box_mat("Fist_R", Vector3(0.30, 0.25, 0.30), Vector3(0.54, 0.42, -0.02), obsidian)

	_add_sphere_mat("Eye_L", 0.057, Vector3(-0.15, 0.99, -0.36), ember, Vector3(1.25,0.70,0.55))
	_add_sphere_mat("Eye_R", 0.057, Vector3(0.15, 0.99, -0.36), ember, Vector3(1.25,0.70,0.55))
	_add_box_mat("Brow_L", Vector3(0.19, 0.07, 0.08), Vector3(-0.15, 1.05, -0.35), obsidian, Vector3(0,0,-14))
	_add_box_mat("Brow_R", Vector3(0.19, 0.07, 0.08), Vector3(0.15, 1.05, -0.35), obsidian, Vector3(0,0,14))
	_add_box_mat("Mouth", Vector3(0.31, 0.065, 0.06), Vector3(0, 0.83, -0.36), lava)

	_add_box_mat("CrownBase", Vector3(0.80, 0.18, 0.80), Vector3(0, 1.27, 0), obsidian_light)
	for x in [-0.29, 0.0, 0.29]:
		_add_box_mat("CrenelFront", Vector3(0.18, 0.25, 0.20), Vector3(x, 1.46, -0.29), obsidian)
		_add_box_mat("CrenelBack", Vector3(0.18, 0.25, 0.20), Vector3(x, 1.46, 0.29), obsidian)
	for z in [-0.05, 0.19]:
		_add_box_mat("CrenelSideL", Vector3(0.20, 0.25, 0.18), Vector3(-0.29, 1.46, z), obsidian)
		_add_box_mat("CrenelSideR", Vector3(0.20, 0.25, 0.18), Vector3(0.29, 1.46, z), obsidian)

	_add_box_mat("RunePlate", Vector3(0.27, 0.31, 0.035), Vector3(0, 0.69, -0.34), violet)
	_add_box_mat("RuneV", Vector3(0.045, 0.25, 0.045), Vector3(0, 0.69, -0.37), lava, Vector3(0,0,20))
	_add_box_mat("RuneH", Vector3(0.20, 0.045, 0.045), Vector3(0, 0.69, -0.37), lava, Vector3(0,0,-20))

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
		&"Knight": return 1.95
		&"Bishop": return 2.05
		&"Rook": return 1.75
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
