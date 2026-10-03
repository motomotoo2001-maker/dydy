class_name PieceView
extends Node3D

const WHITE_PAWN_ASSET_PATH := "res://assets/models/white_pawn_production_v1.glb"
const BLACK_PAWN_ASSET_PATH := "res://assets/models/black_pawn_concept_v3.glb"
const WHITE_KNIGHT_ASSET_PATH := "res://assets/models/white_knight_production_v1.glb"
const BLACK_KNIGHT_ASSET_PATH := "res://assets/models/black_knight_production_v1.glb"
const WHITE_BISHOP_ASSET_PATH := "res://assets/models/white_bishop_production_v1.glb"
const BLACK_BISHOP_ASSET_PATH := "res://assets/models/black_bishop_production_v1.glb"
const WHITE_ROOK_ASSET_PATH := "res://assets/models/white_rook_concept_v3.glb"
const BLACK_ROOK_ASSET_PATH := "res://assets/models/black_rook_concept_v3.glb"
const WHITE_QUEEN_ASSET_PATH := "res://assets/models/white_queen_concept_v3.glb"
const BLACK_QUEEN_ASSET_PATH := "res://assets/models/black_queen_concept_v3.glb"
const WHITE_KING_ASSET_PATH := "res://assets/models/white_king_concept_v3.glb"
const BLACK_KING_ASSET_PATH := "res://assets/models/black_king_concept_v3.glb"

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
var _visual_part_rest: Dictionary = {}
var _named_parts: Dictionary = {}
var _idle_clock := 0.0
var _idle_phase := 0.0
var _battle_animation_active := false
var _presentation_animation_active := false
var _selected := false

func _ready() -> void:
	set_process(DisplayServer.get_name() != "headless")

func _process(delta: float) -> void:
	if visual_root == null or _battle_animation_active or _presentation_animation_active:
		return
	_idle_clock += delta
	var profile := _idle_profile(piece_type)
	var wave := sin(_idle_clock * profile.x + _idle_phase)
	var slow_wave := sin(_idle_clock * profile.x * 0.47 + _idle_phase * 0.7)
	var selected_lift := 0.045 if _selected else 0.0
	var selected_scale := 1.035 if _selected else 1.0
	visual_root.position.y = selected_lift + wave * profile.y
	visual_root.rotation_degrees.z = slow_wave * profile.z
	visual_root.scale = Vector3.ONE * _design_scale(piece_type) * selected_scale
	_apply_secondary_idle(wave, slow_wave)

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
	_idle_phase = float(abs(hash(String(home_square) + String(side)))) * 0.00017
	_build_visual()
	_cache_visual_part_rest()
	_build_anchors()
	_apply_rest_pose()

func reset_visual() -> void:
	_presentation_animation_active = false
	_selected = false
	if visual_root == null:
		return
	visual_root.position = Vector3.ZERO
	visual_root.rotation = Vector3.ZERO
	_restore_visual_part_rest()
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
	_visual_part_rest.clear()
	_named_parts.clear()
	for child in get_children():
		child.free()
	_build_visual()
	_cache_visual_part_rest()
	_build_anchors()
	_apply_rest_pose()

func set_battle_animation_active(active: bool) -> void:
	_battle_animation_active = active
	if active and visual_root != null:
		visual_root.position = Vector3.ZERO
		visual_root.rotation = Vector3.ZERO

func set_selected(active: bool) -> void:
	_selected = active
	if visual_root == null or _battle_animation_active or _presentation_animation_active:
		return
	if not active:
		visual_root.position = Vector3.ZERO
		visual_root.rotation = Vector3.ZERO
		_apply_rest_pose()

func is_selected() -> bool:
	return _selected

func begin_move_presentation() -> void:
	if visual_root == null:
		return
	_presentation_animation_active = true
	_restore_visual_part_rest()
	var base_scale := Vector3.ONE * _design_scale(piece_type)
	_apply_move_part_pose(true)
	var tween := create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "scale", base_scale * Vector3(1.045, 0.94, 1.045), 0.10)
	tween.tween_property(visual_root, "rotation_degrees:x", -4.5, 0.10)
	await tween.finished

func end_move_presentation() -> void:
	if visual_root == null:
		_presentation_animation_active = false
		return
	var base_scale := Vector3.ONE * _design_scale(piece_type)
	var tween := create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "scale", base_scale, 0.14)
	tween.tween_property(visual_root, "rotation_degrees", Vector3.ZERO, 0.14)
	tween.tween_property(visual_root, "position", Vector3.ZERO, 0.14)
	await tween.finished
	_restore_visual_part_rest()
	_presentation_animation_active = false

func play_check_reaction() -> void:
	if visual_root == null:
		return
	_presentation_animation_active = true
	_restore_visual_part_rest()
	_pose_named(["Head", "RiderHead"], Vector3(-5.0, 0.0, 0.0), Vector3(0.0, -0.02, 0.0))
	var base_scale := Vector3.ONE * _design_scale(piece_type)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "rotation_degrees:z", -7.0, 0.07)
	tween.tween_property(visual_root, "rotation_degrees:z", 8.0, 0.09)
	tween.tween_property(visual_root, "rotation_degrees:z", -4.0, 0.07)
	tween.tween_property(visual_root, "rotation_degrees:z", 0.0, 0.10)
	var squash := create_tween()
	squash.tween_property(visual_root, "scale", base_scale * Vector3(1.06, 0.90, 1.06), 0.10)
	squash.tween_property(visual_root, "scale", base_scale, 0.18)
	await tween.finished
	visual_root.scale = base_scale
	_restore_visual_part_rest()
	_presentation_animation_active = false

func play_victory_pose() -> void:
	if visual_root == null:
		return
	_presentation_animation_active = true
	_restore_visual_part_rest()
	_apply_victory_part_pose()
	var base_scale := Vector3.ONE * _design_scale(piece_type)
	var tween := create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "position:y", 0.085, 0.24)
	tween.tween_property(visual_root, "rotation_degrees:z", -3.5 if side == &"White" else 3.5, 0.24)
	tween.tween_property(visual_root, "scale", base_scale * 1.055, 0.24)
	await tween.finished

func play_defeat_pose() -> void:
	if visual_root == null:
		return
	_presentation_animation_active = true
	_restore_visual_part_rest()
	_pose_named(["Head", "RiderHead", "HorseHead"], Vector3(12.0, 0.0, 0.0), Vector3(0.0, -0.04, 0.0))
	var base_scale := Vector3.ONE * _design_scale(piece_type)
	var tween := create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "position:y", -0.035, 0.26)
	tween.tween_property(visual_root, "rotation_degrees:z", 9.0 if side == &"White" else -9.0, 0.26)
	tween.tween_property(visual_root, "scale", base_scale * Vector3(1.04, 0.86, 1.04), 0.26)
	await tween.finished

func get_visual_parts(prefix: String) -> Array[Node3D]:
	var result: Array[Node3D] = []
	if visual_root == null:
		return result
	_collect_visual_parts(visual_root, prefix, result)
	return result

func get_visual_part(part_name: String) -> Node3D:
	if _named_parts.has(part_name):
		return _named_parts[part_name] as Node3D
	if visual_root == null:
		return null
	var found := visual_root.find_child(part_name, true, false)
	return found as Node3D

func get_part_rest_rotation(part: Node3D) -> Vector3:
	if part == null:
		return Vector3.ZERO
	var key := part.get_instance_id()
	if _visual_part_rest.has(key):
		return _visual_part_rest[key]["rotation"]
	return part.rotation_degrees

func get_part_rest_position(part: Node3D) -> Vector3:
	if part == null:
		return Vector3.ZERO
	var key := part.get_instance_id()
	if _visual_part_rest.has(key):
		return _visual_part_rest[key]["position"]
	return part.position

func _apply_move_part_pose(active: bool) -> void:
	if not active:
		_restore_visual_part_rest()
		return
	match piece_type:
		&"Pawn":
			_pose_named(["Spear_Shaft", "SpearShaft", "Knife_Grip", "KnifeGrip"], Vector3(0, 0, -8))
			_pose_named(["Head"], Vector3(-3, 0, 0))
		&"Knight":
			_pose_named(["HorseHead"], Vector3(-6, 0, 0), Vector3(0, -0.015, -0.025))
			_pose_prefix("Leg_", Vector3(12, 0, 0))
		&"Bishop":
			_pose_named(["Staff"], Vector3(0, 0, -9))
			_pose_named(["Trunk", "Snout", "V3_TrunkTip"], Vector3(-6, 0, 0))
		&"Rook":
			_pose_prefix("Arm_", Vector3(0, 0, 8))
			_pose_prefix("Fist_", Vector3(0, 0, 10))
		&"Queen":
			_pose_named(["Staff"], Vector3(0, 0, 9))
			_pose_prefix("V3_HairCurl", Vector3(-3, 0, 0))
		&"King":
			_pose_named(["Scepter"], Vector3(0, 0, -7))
			_pose_prefix("Arm_", Vector3(0, 0, -5))

func _apply_victory_part_pose() -> void:
	match piece_type:
		&"Pawn":
			_pose_named(["Spear_Shaft", "SpearShaft", "Knife_Grip", "KnifeGrip"], Vector3(0, 0, 16))
		&"Knight":
			_pose_named(["HorseHead"], Vector3(-10, 0, 0), Vector3(0, 0.035, -0.02))
			_pose_named(["Plume", "V3_Plume_0", "V3_Plume_1", "V3_Plume_2"], Vector3(0, 0, 10))
		&"Bishop":
			_pose_named(["Staff"], Vector3(0, 0, 18))
			_pose_named(["Trunk", "Snout", "V3_TrunkTip"], Vector3(-12, 0, 0))
		&"Rook":
			_pose_prefix("Arm_", Vector3(0, 0, 22))
			_pose_prefix("Fist_", Vector3(0, 0, 28))
		&"Queen":
			_pose_named(["Staff"], Vector3(0, 0, 24))
			_pose_prefix("V3_Cape", Vector3(-8, 0, 0), Vector3(0, 0.03, 0.04))
		&"King":
			_pose_named(["Scepter"], Vector3(0, 0, -20))
			_pose_prefix("Arm_", Vector3(0, 0, -13))

func _pose_named(names: Array, rotation_offset: Vector3, position_offset: Vector3 = Vector3.ZERO) -> void:
	for candidate in names:
		var part := get_visual_part(String(candidate))
		if part == null:
			continue
		var key := part.get_instance_id()
		if not _visual_part_rest.has(key):
			continue
		var rest: Dictionary = _visual_part_rest[key]
		part.rotation_degrees = rest["rotation"] + rotation_offset
		part.position = rest["position"] + position_offset

func _pose_prefix(prefix: String, rotation_offset: Vector3, position_offset: Vector3 = Vector3.ZERO) -> void:
	for part in get_visual_parts(prefix):
		var key := part.get_instance_id()
		if not _visual_part_rest.has(key):
			continue
		var rest: Dictionary = _visual_part_rest[key]
		part.rotation_degrees = rest["rotation"] + rotation_offset
		part.position = rest["position"] + position_offset

func _apply_secondary_idle(wave: float, slow_wave: float) -> void:
	match piece_type:
		&"Pawn":
			_idle_named(["Head"], Vector3(slow_wave * 1.2, 0, wave * 0.7))
			_idle_named(["Helmet_Crest", "HelmetCrest", "Concept_Plume_0", "Concept_Plume_1", "Concept_Plume_2", "V3_Plume_0", "V3_Plume_1", "V3_Plume_2", "Production_Plume_0", "Production_Plume_1", "Production_Plume_2"], Vector3(0, slow_wave * 1.2, wave * 2.8))
			_idle_named(["Spear_Shaft", "SpearShaft", "Knife_Grip", "KnifeGrip"], Vector3(0, 0, slow_wave * 1.6))
		&"Knight":
			_idle_named(["HorseHead"], Vector3(wave * 1.8, 0, slow_wave * 0.9))
			_idle_named(["Mane"], Vector3(wave * 1.2, 0, slow_wave * 1.6))
			_idle_named(["Plume", "Concept_Plume_0", "Concept_Plume_1", "Concept_Plume_2", "Concept_RedPlume_0", "Concept_RedPlume_1", "Concept_RedPlume_2", "V3_Plume_0", "V3_Plume_1", "V3_Plume_2"], Vector3(0, wave * 1.2, slow_wave * 3.2))
			_idle_named(["RiderTorso"], Vector3(slow_wave * 0.8, 0, wave * 0.5))
		&"Bishop":
			_idle_named(["Head"], Vector3(slow_wave * 0.8, 0, wave * 0.45))
			_idle_named(["Trunk", "Snout"], Vector3(wave * 1.5, 0, 0))
			_idle_named(["Staff"], Vector3(0, 0, slow_wave * 1.4))
		&"Rook":
			_idle_named(["Fist_L", "Fist_R", "Fist_-1", "Fist_1"], Vector3(0, 0, wave * 0.7))
			_idle_named(["CrownBase"], Vector3(0, slow_wave * 0.25, 0))
		&"Queen":
			_idle_named(["Head"], Vector3(slow_wave * 0.7, 0, wave * 0.5))
			_idle_named(["Staff"], Vector3(0, 0, slow_wave * 1.3))
			_idle_named(["MagicOrb", "Concept_CrownGem", "Concept_StaffRing"], Vector3(0, slow_wave * 0.5, wave * 0.8), Vector3(0, wave * 0.010, 0))
			_idle_named(["Hair", "HairBack"], Vector3(wave * 0.8, 0, slow_wave * 0.8))
		&"King":
			_idle_named(["Head"], Vector3(slow_wave * 0.65, 0, wave * 0.35))
			_idle_named(["Beard", "BeardMain", "Concept_FurCollar"], Vector3(wave * 0.7, 0, slow_wave * 0.5))
			_idle_named(["Scepter"], Vector3(0, 0, slow_wave * 1.0))

func _idle_named(
	names: Array,
	rotation_offset: Vector3,
	position_offset: Vector3 = Vector3.ZERO
) -> void:
	for candidate in names:
		var key := String(candidate)
		if not _named_parts.has(key):
			continue
		var part := _named_parts[key] as Node3D
		if part == null:
			continue
		var id := part.get_instance_id()
		if not _visual_part_rest.has(id):
			continue
		var rest: Dictionary = _visual_part_rest[id]
		part.rotation_degrees = rest["rotation"] + rotation_offset
		part.position = rest["position"] + position_offset

func _idle_profile(t: StringName) -> Vector3:
	match t:
		&"Pawn": return Vector3(2.1, 0.020, 0.55)
		&"Knight": return Vector3(1.55, 0.028, 0.70)
		&"Bishop": return Vector3(1.35, 0.018, 0.48)
		&"Rook": return Vector3(0.85, 0.008, 0.16)
		&"Queen": return Vector3(1.15, 0.022, 0.42)
		&"King": return Vector3(0.95, 0.016, 0.32)
	return Vector3(1.0, 0.01, 0.2)

func _collect_visual_parts(node: Node, prefix: String, out: Array[Node3D]) -> void:
	for child in node.get_children():
		if child is Node3D:
			var n := child as Node3D
			if String(n.name).begins_with(prefix):
				out.append(n)
		_collect_visual_parts(child, prefix, out)

func _cache_visual_part_rest() -> void:
	_visual_part_rest.clear()
	_named_parts.clear()
	if visual_root == null:
		return
	_cache_visual_node(visual_root)

func _cache_visual_node(node: Node) -> void:
	for child in node.get_children():
		if child is Node3D:
			var n := child as Node3D
			_visual_part_rest[n.get_instance_id()] = {
				"position": n.position,
				"rotation": n.rotation_degrees,
				"scale": n.scale
			}
			if not _named_parts.has(String(n.name)):
				_named_parts[String(n.name)] = n
		_cache_visual_node(child)

func _restore_visual_part_rest() -> void:
	for key in _visual_part_rest.keys():
		var entry: Dictionary = _visual_part_rest[key]
		var node := instance_from_id(int(key)) as Node3D
		if node == null:
			continue
		node.position = entry["position"]
		node.rotation_degrees = entry["rotation"]
		node.scale = entry["scale"]

func _apply_rest_pose() -> void:
	if visual_root == null:
		return
	visual_root.scale = Vector3.ONE * _design_scale(piece_type)

func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	if piece_type == &"Pawn" and side == &"White":
		# Headless logic/smoke tests keep the lightweight fallback. The real GLB
		# is still imported by the editor parse step and is used by Xvfb renders/gameplay.
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(WHITE_PAWN_ASSET_PATH, "WhitePawnRefinedMeshV1"):
				return
		_build_white_pawn_production_blockout()
		return
	if piece_type == &"Pawn" and side == &"Black":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(BLACK_PAWN_ASSET_PATH, "BlackPawnRefinedMeshV1"):
				return
		_build_black_pawn_production_blockout()
		return
	if piece_type == &"Knight" and side == &"White":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(WHITE_KNIGHT_ASSET_PATH, "WhiteKnightRefinedMeshV1"):
				return
		_build_white_knight_production_blockout()
		return
	if piece_type == &"Knight" and side == &"Black":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(BLACK_KNIGHT_ASSET_PATH, "BlackKnightRefinedMeshV1"):
				return
		_build_black_knight_production_blockout()
		return
	if piece_type == &"Bishop" and side == &"White":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(WHITE_BISHOP_ASSET_PATH, "WhiteBishopRefinedMeshV1"):
				return
		_build_white_bishop_production_blockout()
		return
	if piece_type == &"Bishop" and side == &"Black":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(BLACK_BISHOP_ASSET_PATH, "BlackBishopRefinedMeshV1"):
				return
		_build_black_bishop_production_blockout()
		return
	if piece_type == &"Rook" and side == &"White":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(WHITE_ROOK_ASSET_PATH, "WhiteRookRefinedMeshV1"):
				return
		_build_white_rook_production_blockout()
		return
	if piece_type == &"Rook" and side == &"Black":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(BLACK_ROOK_ASSET_PATH, "BlackRookRefinedMeshV1"):
				return
		_build_black_rook_production_blockout()
		return
	if piece_type == &"Queen" and side == &"White":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(WHITE_QUEEN_ASSET_PATH, "WhiteQueenRefinedMeshV1"):
				return
		_build_white_queen_production_blockout()
		return
	if piece_type == &"Queen" and side == &"Black":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(BLACK_QUEEN_ASSET_PATH, "BlackQueenRefinedMeshV1"):
				return
		_build_black_queen_production_blockout()
		return
	if piece_type == &"King" and side == &"White":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(WHITE_KING_ASSET_PATH, "WhiteKingRefinedMeshV1"):
				return
		_build_white_king_production_blockout()
		return
	if piece_type == &"King" and side == &"Black":
		if DisplayServer.get_name() != "headless":
			if _build_external_asset(BLACK_KING_ASSET_PATH, "BlackKingRefinedMeshV1"):
				return
		_build_black_king_production_blockout()
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

func _build_external_asset(path: String, asset_name: String) -> bool:
	if not ResourceLoader.exists(path):
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("Could not load production asset: %s" % path)
		return false
	var instance := packed.instantiate()
	if instance == null:
		push_warning("Could not instantiate production asset: %s" % path)
		return false
	visual_root.name = "VisualRoot_%s" % asset_name
	instance.name = asset_name
	visual_root.add_child(instance)
	return true

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

func _build_white_queen_production_blockout() -> void:
	visual_root.name = "VisualRoot_WhiteQueenProductionV1"
	var ivory := _material(Color("#eee5d7")); ivory.roughness = 0.48
	var ivory_shadow := _material(Color("#cbbdad")); ivory_shadow.roughness = 0.56
	var gold := _material(Color("#c89c49")); gold.roughness = 0.24; gold.metallic = 0.72
	var blue := _material(Color("#416b91")); blue.roughness = 0.44
	var skin := _material(Color("#d8a07d")); skin.roughness = 0.55
	var hair := _material(Color("#a4774f")); hair.roughness = 0.58
	var dark := _material(Color("#262228")); dark.roughness = 0.46
	var cyan := _material(Color("#67d5e6")); cyan.roughness = 0.12; cyan.emission_enabled = true; cyan.emission = Color("#54c8dc"); cyan.emission_energy_multiplier = 2.5

	_add_cylinder_mat("PedestalLower", 0.45, 0.08, Vector3(0, 0.04, 0), dark)
	_add_cylinder_mat("PedestalRing", 0.41, 0.045, Vector3(0, 0.105, 0), gold)
	_add_cylinder_mat("PedestalUpper", 0.37, 0.09, Vector3(0, 0.165, 0), ivory_shadow)

	# Layered gown with a broad readable silhouette.
	_add_cylinder_mat("SkirtLower", 0.34, 0.82, Vector3(0, 0.58, 0), ivory)
	_add_cylinder_mat("SkirtGoldBand", 0.35, 0.06, Vector3(0, 0.29, 0), gold)
	_add_capsule_mat("Torso", 0.21, 0.58, Vector3(0, 1.05, 0), ivory_shadow)
	_add_box_mat("CorsetPanel", Vector3(0.26, 0.42, 0.055), Vector3(0, 1.04, -0.22), blue)
	_add_box_mat("Collar", Vector3(0.46, 0.09, 0.34), Vector3(0, 1.29, 0), gold)

	# Head, hair and expressive eyes.
	_add_sphere_mat("Head", 0.19, Vector3(0, 1.49, -0.01), skin, Vector3(0.95, 1.06, 0.92))
	_add_sphere_mat("HairBack", 0.22, Vector3(0, 1.50, 0.10), hair, Vector3(1.06, 1.15, 0.90))
	_add_sphere_mat("Eye_L", 0.025, Vector3(-0.065, 1.53, -0.19), blue)
	_add_sphere_mat("Eye_R", 0.025, Vector3(0.065, 1.53, -0.19), blue)
	_add_box_mat("Brow_L", Vector3(0.085, 0.016, 0.018), Vector3(-0.068, 1.58, -0.195), hair, Vector3(0,0,-6))
	_add_box_mat("Brow_R", Vector3(0.085, 0.016, 0.018), Vector3(0.068, 1.58, -0.195), hair, Vector3(0,0,6))

	# Tall crown.
	_add_cylinder_mat("CrownBand", 0.20, 0.10, Vector3(0, 1.70, 0), gold)
	for x in [-0.13, 0.0, 0.13]:
		_add_box_mat("CrownPoint", Vector3(0.08, 0.30 if x == 0.0 else 0.23, 0.08), Vector3(x, 1.86 if x == 0.0 else 1.82, 0), gold, Vector3(0,0,x*45.0))
	_add_sphere_mat("CrownGem", 0.055, Vector3(0, 1.76, -0.19), cyan)

	# Arms, gloves and theatrical staff.
	_add_capsule_mat("Arm_L", 0.068, 0.42, Vector3(-0.28, 1.10, 0), ivory_shadow, Vector3(0,0,-22))
	_add_capsule_mat("Arm_R", 0.068, 0.42, Vector3(0.28, 1.10, 0), ivory_shadow, Vector3(0,0,22))
	_add_sphere_mat("Hand_L", 0.078, Vector3(-0.34, 0.91, -0.03), skin)
	_add_sphere_mat("Hand_R", 0.078, Vector3(0.34, 0.91, -0.03), skin)
	_add_cylinder_mat("Staff", 0.026, 1.30, Vector3(0.43, 1.10, -0.03), gold, Vector3(0,0,-3))
	_add_sphere_mat("MagicOrb", 0.13, Vector3(0.46, 1.78, -0.03), cyan)
	_add_box_mat("OrbHaloV", Vector3(0.035, 0.34, 0.035), Vector3(0.46, 1.78, -0.03), gold)
	_add_box_mat("OrbHaloH", Vector3(0.34, 0.035, 0.035), Vector3(0.46, 1.78, -0.03), gold)

func _build_black_queen_production_blockout() -> void:
	visual_root.name = "VisualRoot_BlackQueenProductionV1"
	var charcoal := _material(Color("#24212b")); charcoal.roughness = 0.50
	var violet := _material(Color("#68407f")); violet.roughness = 0.42
	var violet_dark := _material(Color("#402a50")); violet_dark.roughness = 0.50
	var steel := _material(Color("#5b5361")); steel.roughness = 0.30; steel.metallic = 0.52
	var skin := _material(Color("#9b839c")); skin.roughness = 0.55
	var hair := _material(Color("#211a28")); hair.roughness = 0.52
	var magenta := _material(Color("#d05bea")); magenta.roughness = 0.12; magenta.emission_enabled = true; magenta.emission = Color("#bd48dc"); magenta.emission_energy_multiplier = 2.8
	var red := _material(Color("#7c334d")); red.roughness = 0.45
	var dark := _material(Color("#111116")); dark.roughness = 0.48

	_add_cylinder_mat("PedestalLower", 0.45, 0.08, Vector3(0, 0.04, 0), dark)
	_add_cylinder_mat("PedestalRing", 0.41, 0.045, Vector3(0, 0.105, 0), magenta)
	_add_cylinder_mat("PedestalUpper", 0.37, 0.09, Vector3(0, 0.165, 0), charcoal)

	# Angular sorceress gown.
	_add_cylinder_mat("SkirtLower", 0.35, 0.84, Vector3(0, 0.59, 0), charcoal)
	_add_box_mat("SkirtPanel", Vector3(0.28, 0.72, 0.055), Vector3(0, 0.62, -0.31), violet, Vector3(0,0,-5))
	_add_capsule_mat("Torso", 0.21, 0.58, Vector3(0, 1.06, 0), violet_dark)
	_add_box_mat("ChestArmor", Vector3(0.38, 0.30, 0.06), Vector3(0, 1.10, -0.22), steel)
	_add_box_mat("Collar", Vector3(0.52, 0.11, 0.36), Vector3(0, 1.31, 0), charcoal)

	# Pale face, black hair and glowing eyes.
	_add_sphere_mat("Head", 0.19, Vector3(0, 1.50, -0.01), skin, Vector3(0.93, 1.08, 0.90))
	_add_sphere_mat("HairBack", 0.23, Vector3(0, 1.50, 0.11), hair, Vector3(1.08, 1.22, 0.92))
	_add_sphere_mat("Eye_L", 0.026, Vector3(-0.065, 1.54, -0.19), magenta)
	_add_sphere_mat("Eye_R", 0.026, Vector3(0.065, 1.54, -0.19), magenta)
	_add_box_mat("Brow_L", Vector3(0.09, 0.018, 0.018), Vector3(-0.067, 1.59, -0.195), hair, Vector3(0,0,-12))
	_add_box_mat("Brow_R", Vector3(0.09, 0.018, 0.018), Vector3(0.067, 1.59, -0.195), hair, Vector3(0,0,12))

	# Horned crown.
	_add_cylinder_mat("CrownBand", 0.20, 0.10, Vector3(0, 1.71, 0), steel)
	_add_cylinder_mat("CrownHorn_L", 0.032, 0.34, Vector3(-0.13, 1.88, 0), charcoal, Vector3(0,0,-30))
	_add_cylinder_mat("CrownHorn_R", 0.032, 0.34, Vector3(0.13, 1.88, 0), charcoal, Vector3(0,0,30))
	_add_sphere_mat("CrownGem", 0.055, Vector3(0, 1.77, -0.19), magenta)

	_add_capsule_mat("Arm_L", 0.068, 0.43, Vector3(-0.28, 1.10, 0), violet_dark, Vector3(0,0,-24))
	_add_capsule_mat("Arm_R", 0.068, 0.43, Vector3(0.28, 1.10, 0), violet_dark, Vector3(0,0,24))
	_add_sphere_mat("Hand_L", 0.078, Vector3(-0.34, 0.91, -0.03), skin)
	_add_sphere_mat("Hand_R", 0.078, Vector3(0.34, 0.91, -0.03), skin)

	# Crooked dark staff with magenta spell core.
	_add_cylinder_mat("Staff", 0.028, 1.32, Vector3(0.43, 1.10, -0.03), steel, Vector3(0,0,-4))
	_add_sphere_mat("MagicOrb", 0.135, Vector3(0.47, 1.79, -0.03), magenta)
	_add_box_mat("OrbProng_L", Vector3(0.04, 0.34, 0.04), Vector3(0.36, 1.79, -0.03), charcoal, Vector3(0,0,-30))
	_add_box_mat("OrbProng_R", Vector3(0.04, 0.34, 0.04), Vector3(0.58, 1.79, -0.03), charcoal, Vector3(0,0,30))
	_add_box_mat("SpellRune", Vector3(0.18, 0.18, 0.035), Vector3(0, 0.82, -0.34), red, Vector3(0,0,45))

func _build_white_king_production_blockout() -> void:
	visual_root.name = "VisualRoot_WhiteKingProductionV1"
	var ivory := _material(Color("#eee4d6")); ivory.roughness = 0.50
	var ivory_shadow := _material(Color("#c9baaa")); ivory_shadow.roughness = 0.58
	var gold := _material(Color("#c99b45")); gold.roughness = 0.23; gold.metallic = 0.74
	var blue := _material(Color("#3b6288")); blue.roughness = 0.45
	var red := _material(Color("#8a3d43")); red.roughness = 0.48
	var skin := _material(Color("#d49b75")); skin.roughness = 0.56
	var beard := _material(Color("#e6dfd2")); beard.roughness = 0.68
	var dark := _material(Color("#2b2526")); dark.roughness = 0.50
	var eye := _material(Color("#33465a")); eye.roughness = 0.18
	var gem := _material(Color("#58c5d8")); gem.roughness = 0.12; gem.emission_enabled = true; gem.emission = Color("#4ab2c6"); gem.emission_energy_multiplier = 1.7

	_add_cylinder_mat("PedestalLower", 0.47, 0.08, Vector3(0, 0.04, 0), dark)
	_add_cylinder_mat("PedestalRing", 0.43, 0.05, Vector3(0, 0.115, 0), gold)
	_add_cylinder_mat("PedestalUpper", 0.39, 0.10, Vector3(0, 0.19, 0), ivory_shadow)

	# Wide, slightly comedic royal body.
	_add_cylinder_mat("RobeLower", 0.36, 0.78, Vector3(0, 0.57, 0), ivory)
	_add_sphere_mat("Belly", 0.30, Vector3(0, 0.92, -0.02), red, Vector3(1.08, 0.92, 0.92))
	_add_capsule_mat("Torso", 0.24, 0.55, Vector3(0, 1.13, 0), ivory_shadow)
	_add_box_mat("RoyalSash", Vector3(0.11, 0.75, 0.35), Vector3(0.06, 0.91, -0.18), blue, Vector3(0,0,-12))
	_add_box_mat("Belt", Vector3(0.64, 0.10, 0.34), Vector3(0, 0.79, 0), gold)

	# Old king face and oversized beard.
	_add_sphere_mat("Head", 0.22, Vector3(0, 1.50, -0.02), skin, Vector3(1.0, 1.0, 0.94))
	_add_sphere_mat("Nose", 0.060, Vector3(0, 1.47, -0.235), skin, Vector3(0.95,0.78,1.25))
	_add_sphere_mat("Eye_L", 0.026, Vector3(-0.075, 1.55, -0.225), eye)
	_add_sphere_mat("Eye_R", 0.026, Vector3(0.075, 1.55, -0.225), eye)
	_add_sphere_mat("BeardMain", 0.22, Vector3(0, 1.31, -0.16), beard, Vector3(0.95,1.18,0.72))
	_add_sphere_mat("Moustache_L", 0.075, Vector3(-0.07, 1.43, -0.235), beard, Vector3(1.35,0.52,0.65))
	_add_sphere_mat("Moustache_R", 0.075, Vector3(0.07, 1.43, -0.235), beard, Vector3(1.35,0.52,0.65))

	# Large readable crown.
	_add_cylinder_mat("CrownBand", 0.23, 0.12, Vector3(0, 1.70, 0), gold)
	for x in [-0.16, -0.05, 0.05, 0.16]:
		_add_box_mat("CrownPoint", Vector3(0.07, 0.31 if absf(x) < 0.10 else 0.24, 0.07), Vector3(x, 1.88 if absf(x) < 0.10 else 1.84, 0), gold, Vector3(0,0,x*50.0))
	_add_sphere_mat("CrownGem", 0.060, Vector3(0, 1.77, -0.22), gem)

	# Arms and royal cape blocks.
	_add_box_mat("Cape_L", Vector3(0.18, 0.70, 0.10), Vector3(-0.27, 1.08, 0.18), red, Vector3(0,0,8))
	_add_box_mat("Cape_R", Vector3(0.18, 0.70, 0.10), Vector3(0.27, 1.08, 0.18), red, Vector3(0,0,-8))
	_add_capsule_mat("Arm_L", 0.075, 0.42, Vector3(-0.32, 1.12, 0), ivory_shadow, Vector3(0,0,-16))
	_add_capsule_mat("Arm_R", 0.075, 0.42, Vector3(0.32, 1.12, 0), ivory_shadow, Vector3(0,0,16))
	_add_sphere_mat("Hand_L", 0.085, Vector3(-0.37, 0.94, -0.03), skin)
	_add_sphere_mat("Hand_R", 0.085, Vector3(0.37, 0.94, -0.03), skin)

	# Scepter stays compact; trapdoor remote is spawned by BattleDirector.
	_add_cylinder_mat("Scepter", 0.026, 0.95, Vector3(-0.43, 1.12, -0.02), gold, Vector3(0,0,5))
	_add_sphere_mat("ScepterGem", 0.095, Vector3(-0.47, 1.60, -0.02), gem)

func _build_black_king_production_blockout() -> void:
	visual_root.name = "VisualRoot_BlackKingProductionV1"
	var charcoal := _material(Color("#242029")); charcoal.roughness = 0.50
	var armor := _material(Color("#514a55")); armor.roughness = 0.31; armor.metallic = 0.52
	var red := _material(Color("#87363d")); red.roughness = 0.43
	var crimson := _material(Color("#b63c35")); crimson.roughness = 0.40
	var skin := _material(Color("#9a493e")); skin.roughness = 0.55
	var horn := _material(Color("#8d8173")); horn.roughness = 0.58
	var violet := _material(Color("#694080")); violet.roughness = 0.42
	var glow := _material(Color("#e16a45")); glow.roughness = 0.12; glow.emission_enabled = true; glow.emission = Color("#d45132"); glow.emission_energy_multiplier = 2.5
	var dark := _material(Color("#111116")); dark.roughness = 0.48

	_add_cylinder_mat("PedestalLower", 0.47, 0.08, Vector3(0, 0.04, 0), dark)
	_add_cylinder_mat("PedestalRing", 0.43, 0.05, Vector3(0, 0.115, 0), crimson)
	_add_cylinder_mat("PedestalUpper", 0.39, 0.10, Vector3(0, 0.19, 0), charcoal)

	# Demon-lord silhouette: broad torso, belly armor and cape.
	_add_cylinder_mat("RobeLower", 0.37, 0.80, Vector3(0, 0.58, 0), charcoal)
	_add_sphere_mat("BellyArmor", 0.31, Vector3(0, 0.92, -0.02), armor, Vector3(1.10,0.90,0.90))
	_add_capsule_mat("Torso", 0.25, 0.57, Vector3(0, 1.14, 0), red)
	_add_box_mat("ChestPlate", Vector3(0.48, 0.32, 0.07), Vector3(0, 1.14, -0.25), armor)
	_add_box_mat("Cape_L", Vector3(0.20, 0.76, 0.11), Vector3(-0.29, 1.10, 0.19), violet, Vector3(0,0,10))
	_add_box_mat("Cape_R", Vector3(0.20, 0.76, 0.11), Vector3(0.29, 1.10, 0.19), violet, Vector3(0,0,-10))

	# Red demon face with fangs and emissive eyes.
	_add_sphere_mat("Head", 0.22, Vector3(0, 1.51, -0.02), skin, Vector3(1.0,1.0,0.94))
	_add_sphere_mat("Nose", 0.055, Vector3(0, 1.48, -0.23), skin, Vector3(0.90,0.75,1.20))
	_add_sphere_mat("Eye_L", 0.030, Vector3(-0.078, 1.56, -0.225), glow)
	_add_sphere_mat("Eye_R", 0.030, Vector3(0.078, 1.56, -0.225), glow)
	_add_box_mat("Fang_L", Vector3(0.035, 0.12, 0.035), Vector3(-0.06, 1.38, -0.225), horn, Vector3(0,0,8))
	_add_box_mat("Fang_R", Vector3(0.035, 0.12, 0.035), Vector3(0.06, 1.38, -0.225), horn, Vector3(0,0,-8))

	# Huge horned crown.
	_add_cylinder_mat("CrownBand", 0.23, 0.12, Vector3(0, 1.71, 0), armor)
	_add_cylinder_mat("CrownHorn_L", 0.038, 0.45, Vector3(-0.17, 1.90, 0), horn, Vector3(0,0,-34))
	_add_cylinder_mat("CrownHorn_R", 0.038, 0.45, Vector3(0.17, 1.90, 0), horn, Vector3(0,0,34))
	_add_box_mat("CrownCenter", Vector3(0.09, 0.34, 0.09), Vector3(0, 1.91, 0), crimson)
	_add_sphere_mat("CrownGem", 0.060, Vector3(0, 1.78, -0.22), glow)

	_add_capsule_mat("Arm_L", 0.078, 0.43, Vector3(-0.33, 1.12, 0), red, Vector3(0,0,-18))
	_add_capsule_mat("Arm_R", 0.078, 0.43, Vector3(0.33, 1.12, 0), red, Vector3(0,0,18))
	_add_sphere_mat("Hand_L", 0.088, Vector3(-0.38, 0.94, -0.03), skin)
	_add_sphere_mat("Hand_R", 0.088, Vector3(0.38, 0.94, -0.03), skin)

	_add_cylinder_mat("Scepter", 0.028, 0.98, Vector3(-0.44, 1.12, -0.02), armor, Vector3(0,0,5))
	_add_sphere_mat("ScepterCore", 0.10, Vector3(-0.48, 1.62, -0.02), glow)
	_add_box_mat("ScepterRune", Vector3(0.18, 0.18, 0.04), Vector3(-0.48, 1.62, -0.02), violet, Vector3(0,0,45))

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
		&"Queen": return 2.05
		&"King": return 2.10
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
