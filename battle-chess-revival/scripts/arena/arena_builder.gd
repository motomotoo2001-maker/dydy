class_name ArenaBuilder
extends Node3D

const CELL_SIZE := 1.20
const BOARD_Y := 0.38
const CATHEDRAL_ASSET_PATH := "res://assets/models/cathedral_production_v1.glb"

const QUALITY_LOW := 0
const QUALITY_MEDIUM := 1
const QUALITY_HIGH := 2

var generated: Node3D
var board_root: Node3D
var sockets_root: Node3D
var pieces_root: Node3D
var battle_stage: Node3D
var gameplay_camera: Camera3D
var battle_camera: Camera3D

var _pieces: Array[PieceView] = []
var _sockets: Dictionary = {}
var _piece_by_square: Dictionary = {}
var selection_root: Node3D
var last_move_root: Node3D
var danger_root: Node3D
var _selected_piece: PieceView
var _cathedral_material_cache: Dictionary = {}
var quality_preset := QUALITY_HIGH

func build() -> void:
	if generated != null and is_instance_valid(generated):
		generated.queue_free()
		await get_tree().process_frame

	generated = Node3D.new()
	generated.name = "Generated"
	add_child(generated)

	_build_environment()
	_build_cathedral()
	_build_board()
	_build_battle_stage()
	_build_cameras()
	_build_lighting()
	_build_pieces()
	_build_selection_root()
	_build_last_move_root()
	_build_danger_root()

func apply_quality_preset(level: int) -> void:
	quality_preset = clampi(level, QUALITY_LOW, QUALITY_HIGH)
	if generated == null:
		return

	var world := generated.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world != null and world.environment != null:
		var env := world.environment
		match quality_preset:
			QUALITY_LOW:
				env.ssao_enabled = false
				env.glow_enabled = false
				env.fog_enabled = false
				env.ssil_enabled = false
				env.volumetric_fog_enabled = false
			QUALITY_MEDIUM:
				env.ssao_enabled = true
				env.ssao_radius = 0.95
				env.ssao_intensity = 1.05
				env.ssao_power = 1.05
				env.ssao_detail = 0.45
				env.glow_enabled = true
				env.glow_intensity = 0.12
				env.fog_enabled = true
				env.fog_density = 0.0015
				env.ssil_enabled = false
				env.volumetric_fog_enabled = false
			_:
				env.ssao_enabled = true
				env.ssao_radius = 1.25
				env.ssao_intensity = 1.38
				env.ssao_power = 1.18
				env.ssao_detail = 0.62
				env.glow_enabled = true
				env.glow_intensity = 0.20
				env.fog_enabled = true
				env.fog_density = 0.002
				if RenderingServer.get_current_rendering_method() == "forward_plus":
					env.ssil_enabled = true
					env.volumetric_fog_enabled = true
					env.volumetric_fog_density = 0.010
					env.volumetric_fog_length = 30.0
				else:
					env.ssil_enabled = false
					env.volumetric_fog_enabled = false

	var lighting := generated.get_node_or_null("Lighting")
	if lighting != null:
		var sun := lighting.get_node_or_null("SunWarm") as DirectionalLight3D
		var warm := lighting.get_node_or_null("WarmFill") as OmniLight3D
		var window := lighting.get_node_or_null("WindowSunFill") as OmniLight3D
		if sun != null:
			sun.shadow_enabled = true
			sun.directional_shadow_max_distance = 22.0 if quality_preset == QUALITY_LOW else (30.0 if quality_preset == QUALITY_MEDIUM else 36.0)
		if warm != null:
			warm.shadow_enabled = quality_preset == QUALITY_HIGH
		if window != null:
			window.shadow_enabled = quality_preset >= QUALITY_MEDIUM


func quality_label() -> String:
	match quality_preset:
		QUALITY_LOW:
			return "Низкое"
		QUALITY_MEDIUM:
			return "Среднее"
		_:
			return "Высокое"


func get_square_count() -> int:
	return _sockets.size()

func get_piece_count() -> int:
	return _pieces.size()

func get_all_pieces() -> Array[PieceView]:
	return _pieces

func get_piece_at(square: StringName) -> PieceView:
	return _piece_by_square.get(square) as PieceView

func move_piece(piece: PieceView, square: StringName) -> void:
	if piece == null or not _sockets.has(square):
		return
	_piece_by_square.erase(piece.current_square)
	piece.current_square = square
	_piece_by_square[square] = piece
	piece.global_position = get_socket(square).global_position

func animate_piece_move(piece: PieceView, square: StringName) -> void:
	if piece == null or not _sockets.has(square):
		return
	_piece_by_square.erase(piece.current_square)
	piece.current_square = square
	_piece_by_square[square] = piece
	var target := get_socket(square).global_position
	var origin := piece.global_position
	await piece.begin_move_presentation()

	match piece.piece_type:
		&"Pawn":
			await _arc_piece_to(piece, origin, target, 0.16, 0.11, 0.11)
		&"Knight":
			await _arc_piece_to(piece, origin, target, 0.72, 0.18, 0.18)
		&"Bishop":
			await _arc_piece_to(piece, origin, target, 0.26, 0.14, 0.14)
		&"Queen":
			await _arc_piece_to(piece, origin, target, 0.34, 0.15, 0.15)
		&"King":
			await _arc_piece_to(piece, origin, target, 0.20, 0.18, 0.18)
		&"Rook":
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(piece, "global_position", target, 0.32)
			await tween.finished
		_:
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(piece, "global_position", target, 0.28)
			await tween.finished

	_spawn_move_landing_fx(target, piece)
	await piece.end_move_presentation()


func _arc_piece_to(
	piece: PieceView,
	origin: Vector3,
	target: Vector3,
	height: float,
	out_time: float,
	in_time: float
) -> void:
	var midpoint := (origin + target) * 0.5
	midpoint.y = maxf(origin.y, target.y) + height
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "global_position", midpoint, out_time)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(piece, "global_position", target, in_time)
	await tween.finished


func _spawn_move_landing_fx(target: Vector3, piece: PieceView) -> void:
	if generated == null or piece == null:
		return
	var ring := MeshInstance3D.new()
	ring.name = "MoveLandingFX"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.30
	mesh.bottom_radius = 0.30
	mesh.height = 0.018
	mesh.radial_segments = 40
	ring.mesh = mesh

	var color := Color("#7bd8ff") if piece.side == &"White" else Color("#ff795f")
	if piece.piece_type == &"Queen":
		color = Color("#e3b6ff") if piece.side == &"White" else Color("#e56cff")
	elif piece.piece_type == &"Rook":
		color = Color("#ffd596") if piece.side == &"White" else Color("#ff9a5f")

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(color.r, color.g, color.b, 0.34)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.65
	ring.material_override = material
	ring.global_position = target + Vector3(0, 0.025, 0)
	var strength := 1.22 if piece.piece_type == &"Rook" else (1.10 if piece.piece_type == &"King" else 1.0)
	ring.scale = Vector3(0.45, 1.0, 0.45) * strength
	generated.add_child(ring)

	var tween := create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector3(1.65, 1.0, 1.65) * strength, 0.24)
	tween.tween_property(ring, "transparency", 1.0, 0.24)
	tween.chain().tween_callback(ring.queue_free)


func reset_pieces() -> void:
	clear_selection()
	clear_last_move()
	if pieces_root == null:
		return
	for child in pieces_root.get_children():
		child.free()
	_pieces.clear()
	_piece_by_square.clear()
	_populate_pieces()

func sync_pieces_from_state(state: ChessState) -> void:
	# Rebuild the visual board from an arbitrary legal ChessState. This is used
	# by Undo/rematch tooling and deliberately avoids replaying battle VFX.
	clear_selection()
	clear_last_move()
	if pieces_root == null:
		return
	for child in pieces_root.get_children():
		child.free()
	_pieces.clear()
	_piece_by_square.clear()

	var squares: Array = state.board.keys()
	squares.sort()
	for square_variant in squares:
		var square: StringName = square_variant
		var data: Dictionary = state.board[square]
		if data.is_empty():
			continue
		_spawn_piece(
			data.get("side", &"White"),
			data.get("type", &"Pawn"),
			square
		)

func remove_piece(piece: PieceView) -> void:
	if piece == null:
		return
	_piece_by_square.erase(piece.current_square)
	_pieces.erase(piece)
	piece.queue_free()

func clear_selection() -> void:
	if _selected_piece != null and is_instance_valid(_selected_piece):
		_selected_piece.set_selected(false)
	_selected_piece = null
	if selection_root == null:
		return
	for child in selection_root.get_children():
		child.queue_free()

func show_selection(square: StringName, moves: Array[Dictionary]) -> void:
	clear_selection()
	_selected_piece = get_piece_at(square)
	if _selected_piece != null:
		_selected_piece.set_selected(true)
	_add_square_overlay(square, Color(0.95, 0.78, 0.18, 0.42))
	for move in moves:
		var color := Color(0.95, 0.25, 0.25, 0.48) if move.get("capture", false) else Color(0.25, 0.82, 0.48, 0.38)
		_add_square_overlay(move["to"], color)

func get_socket(square: StringName) -> Marker3D:
	return _sockets.get(square) as Marker3D

func play_check_reaction(side: StringName) -> void:
	var king := find_piece(side, &"King")
	if king != null:
		await king.play_check_reaction()

func play_checkmate_presentation(winner_side: StringName, loser_side: StringName) -> void:
	var loser_king := find_piece(loser_side, &"King")
	var winner_king := find_piece(winner_side, &"King")
	if loser_king != null:
		await loser_king.play_defeat_pose()
	if winner_king != null:
		await winner_king.play_victory_pose()

func find_piece(p_side: StringName, p_type: StringName, occurrence: int = 0) -> PieceView:
	var found := 0
	for piece in _pieces:
		if piece.side == p_side and piece.piece_type == p_type:
			if found == occurrence:
				return piece
			found += 1
	return null

func set_demo_focus(attacker: PieceView, victim: PieceView, focused: bool) -> void:
	# During captures keep the victim army as background spectators, while
	# hiding non-participating attacker-side pieces that would sit between
	# the low battle camera and the action.
	for piece in _pieces:
		if not focused:
			piece.visible = true
		elif piece == attacker or piece == victim:
			piece.visible = true
		else:
			piece.visible = piece.side == victim.side

func set_battle_lighting(active: bool) -> void:
	if generated == null:
		return
	var lighting := generated.get_node_or_null("Lighting")
	if lighting == null:
		return
	var sun := lighting.get_node_or_null("SunWarm") as DirectionalLight3D
	var warm := lighting.get_node_or_null("WarmFill") as OmniLight3D
	var cool := lighting.get_node_or_null("CoolRim") as OmniLight3D
	var window := lighting.get_node_or_null("WindowSunFill") as OmniLight3D
	var stained_red := lighting.get_node_or_null("StainedRed") as OmniLight3D
	var stained_gold := lighting.get_node_or_null("StainedGold") as OmniLight3D
	var stained_blue := lighting.get_node_or_null("StainedBlue") as OmniLight3D
	var neutral := lighting.get_node_or_null("BattleNeutralFill") as OmniLight3D
	if sun:
		sun.light_energy = 0.74 if active else 0.96
		sun.light_color = Color("#f1eee9") if active else Color("#ffe0ad")
	if warm:
		warm.light_energy = 0.12 if active else 1.05
		warm.light_color = Color("#e8ddd2") if active else Color("#ffc789")
	if cool:
		cool.light_energy = 0.46 if active else 0.94
		cool.light_color = Color("#bbc5d7") if active else Color("#7f6fd2")
	if window:
		window.light_energy = 0.62 if active else 1.32
		window.light_color = Color("#eef1f4") if active else Color("#ffd895")
	if stained_red:
		stained_red.light_energy = 0.05 if active else 0.52
	if stained_gold:
		stained_gold.light_energy = 0.08 if active else 0.54
	if stained_blue:
		stained_blue.light_energy = 0.10 if active else 0.36
	if neutral:
		neutral.light_energy = 0.72 if active else 0.0

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#171214")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#d0bba7")
	env.ambient_light_energy = 0.27
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_agx_contrast = 1.24
	env.tonemap_agx_white = 8.0
	env.ssao_enabled = true
	env.ssao_radius = 1.25
	env.ssao_intensity = 1.38
	env.ssao_power = 1.18
	env.ssao_detail = 0.62
	env.glow_enabled = true
	env.glow_intensity = 0.20
	env.fog_enabled = true
	env.fog_density = 0.002
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		env.ssil_enabled = true
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.010
		env.volumetric_fog_length = 30.0
	world.environment = env
	generated.add_child(world)

func _build_cathedral() -> void:
	# D1 production environment: prefer the Blender-authored cathedral in real
	# rendering. Headless rules/smoke tests retain the lightweight procedural
	# fallback so gameplay logic never depends on GPU asset loading.
	if DisplayServer.get_name() != "headless" and _build_external_cathedral():
		return
	_build_cathedral_fallback()

func _build_external_cathedral() -> bool:
	if not ResourceLoader.exists(CATHEDRAL_ASSET_PATH):
		return false
	var packed := load(CATHEDRAL_ASSET_PATH) as PackedScene
	if packed == null:
		push_warning("Could not load production cathedral: %s" % CATHEDRAL_ASSET_PATH)
		return false
	var instance := packed.instantiate()
	if instance == null:
		push_warning("Could not instantiate production cathedral: %s" % CATHEDRAL_ASSET_PATH)
		return false
	instance.name = "CathedralProductionV1"
	generated.add_child(instance)
	_prepare_cathedral_material_cache()
	_apply_cathedral_material_overrides(instance)
	return true

func _build_cathedral_fallback() -> void:
	var root := Node3D.new()
	root.name = "Cathedral"
	generated.add_child(root)

	var stone := _mat(Color("#756b61"), 0.72, 0.0)
	var floor_mat := _mat(Color("#48413d"), 0.54, 0.0)
	var red := _mat(Color("#7b3434"), 0.62, 0.0)
	var gold := _mat(Color("#a9782f"), 0.26, 0.82)

	_box(root, "Floor", Vector3(22, 0.2, 28), Vector3(0, -0.1, 0), floor_mat)
	_box(root, "BackWall", Vector3(22, 16, 0.5), Vector3(0, 8, -14), stone)
	_box(root, "LeftWall", Vector3(0.5, 16, 28), Vector3(-11, 8, 0), stone)
	_box(root, "RightWall", Vector3(0.5, 16, 28), Vector3(11, 8, 0), stone)

	for side in [-1.0, 1.0]:
		for z in [-10.0, -5.0, 0.0, 5.0, 10.0]:
			_cylinder(root, "Column", 0.52, 10.0, Vector3(8.7 * side, 5.0, z), stone)

	for i in range(5):
		_box(root, "Step_%d" % i, Vector3(8.0 - i * 0.55, 0.25, 1.15),
			Vector3(0, 0.125 + i * 0.25, -10.2 - i * 0.56), stone)

	_box(root, "Altar", Vector3(5.8, 1.2, 2.0), Vector3(0, 1.5, -12.1), stone)
	_box(root, "Carpet", Vector3(2.2, 0.025, 8.0), Vector3(0, 0.02, -8.4), red)

	for x in [-5.7, 0.0, 5.7]:
		var pane_color := Color("#8a3550") if x < 0 else (Color("#d3a052") if x == 0.0 else Color("#415b9e"))
		var pane := _emissive(pane_color, 2.2)
		_box(root, "StainedGlass", Vector3(2.5 if x != 0.0 else 3.8, 5.2 if x != 0.0 else 6.4, 0.08),
			Vector3(x, 7.6, -13.70), pane)
		_box(root, "WindowFrameV", Vector3(0.10, 6.5, 0.14), Vector3(x, 7.6, -13.62), gold)

	_build_cathedral_details(root, stone, gold)

func _build_board() -> void:
	board_root = Node3D.new()
	board_root.name = "ChessBoard"
	generated.add_child(board_root)

	sockets_root = Node3D.new()
	sockets_root.name = "PieceSockets"
	generated.add_child(sockets_root)

	var cream := _marble_material(Color("#e7dfd0"), Color("#b9aea0"), 0.26)
	var wood := _wood_material(Color("#493024"), Color("#271a15"), 0.32)
	var gold := _mat(Color("#c99b48"), 0.24, 0.84)
	var base := _wood_material(Color("#3d281f"), Color("#211612"), 0.36)

	_box(board_root, "Base", Vector3(11.35, 0.34, 11.35), Vector3(0, 0.17, 0), base)
	_box(board_root, "GoldTrim", Vector3(10.55, 0.18, 10.55), Vector3(0, 0.32, 0), gold)

	var rail_mat := _wood_material(Color("#583526"), Color("#2e1d17"), 0.30)
	_box(board_root, "FrameNorth", Vector3(11.25, 0.34, 0.42), Vector3(0, 0.43, -5.42), rail_mat)
	_box(board_root, "FrameSouth", Vector3(11.25, 0.34, 0.42), Vector3(0, 0.43, 5.42), rail_mat)
	_box(board_root, "FrameWest", Vector3(0.42, 0.34, 10.45), Vector3(-5.42, 0.43, 0), rail_mat)
	_box(board_root, "FrameEast", Vector3(0.42, 0.34, 10.45), Vector3(5.42, 0.43, 0), rail_mat)

	# G2 board luxury/detail pass: thin inlays and hardware add edge density
	# around the play field without changing square geometry or click math.
	var dark_gold := _mat(Color("#8d6129"), 0.30, 0.78)
	_box(board_root, "InnerRailNorth", Vector3(10.02, 0.055, 0.055), Vector3(0, 0.505, -4.91), gold)
	_box(board_root, "InnerRailSouth", Vector3(10.02, 0.055, 0.055), Vector3(0, 0.505, 4.91), gold)
	_box(board_root, "InnerRailWest", Vector3(0.055, 0.055, 10.02), Vector3(-4.91, 0.505, 0), gold)
	_box(board_root, "InnerRailEast", Vector3(0.055, 0.055, 10.02), Vector3(4.91, 0.505, 0), gold)

	_box(board_root, "OuterInlayNorth", Vector3(10.72, 0.045, 0.075), Vector3(0, 0.585, -5.18), dark_gold)
	_box(board_root, "OuterInlaySouth", Vector3(10.72, 0.045, 0.075), Vector3(0, 0.585, 5.18), dark_gold)
	_box(board_root, "OuterInlayWest", Vector3(0.075, 0.045, 10.18), Vector3(-5.18, 0.585, 0), dark_gold)
	_box(board_root, "OuterInlayEast", Vector3(0.075, 0.045, 10.18), Vector3(5.18, 0.585, 0), dark_gold)

	for corner_idx in range(4):
		var sx := -1.0 if corner_idx in [0, 2] else 1.0
		var sz := -1.0 if corner_idx in [0, 1] else 1.0
		_cylinder(
			board_root,
			"CornerMedallion_%d" % corner_idx,
			0.18,
			0.07,
			Vector3(5.18 * sx, 0.61, 5.18 * sz),
			gold
		)

	_add_board_coordinate_labels()

	for rank_idx in range(8):
		for file_idx in range(8):
			var x := (float(file_idx) - 3.5) * CELL_SIZE
			var z := (3.5 - float(rank_idx)) * CELL_SIZE
			var square := StringName("%s%d" % [String.chr(65 + file_idx), rank_idx + 1])
			var material := cream if (file_idx + rank_idx) % 2 == 0 else wood
			_box(board_root, "Tile_%s" % String(square), Vector3(1.18, 0.08, 1.18),
				Vector3(x, BOARD_Y, z), material)
			var marker := Marker3D.new()
			marker.name = String(square)
			marker.position = Vector3(x, BOARD_Y + 0.08, z)
			sockets_root.add_child(marker)
			_sockets[square] = marker

func _add_board_coordinate_labels() -> void:
	var label_color := Color("#e0bd79")
	for file_idx in range(8):
		var label := Label3D.new()
		label.name = "FileLabel_%d" % file_idx
		label.text = String.chr(65 + file_idx)
		label.font_size = 64
		label.pixel_size = 0.006
		label.modulate = label_color
		label.outline_modulate = Color(0.05, 0.03, 0.02, 0.92)
		label.outline_size = 10
		label.rotation_degrees.x = -90.0
		label.position = Vector3((float(file_idx) - 3.5) * CELL_SIZE, 0.625, 5.18)
		board_root.add_child(label)

	for rank_idx in range(8):
		var label := Label3D.new()
		label.name = "RankLabel_%d" % rank_idx
		label.text = str(rank_idx + 1)
		label.font_size = 64
		label.pixel_size = 0.006
		label.modulate = label_color
		label.outline_modulate = Color(0.05, 0.03, 0.02, 0.92)
		label.outline_size = 10
		label.rotation_degrees.x = -90.0
		label.position = Vector3(5.18, 0.625, (3.5 - float(rank_idx)) * CELL_SIZE)
		board_root.add_child(label)


func _build_battle_stage() -> void:
	battle_stage = Node3D.new()
	battle_stage.name = "BattleStage"
	generated.add_child(battle_stage)

	var attacker := Marker3D.new()
	attacker.name = "AttackerAnchor"
	attacker.position = Vector3(-0.95, BOARD_Y + 0.08, 0)
	battle_stage.add_child(attacker)

	var victim := Marker3D.new()
	victim.name = "VictimAnchor"
	victim.position = Vector3(0.95, BOARD_Y + 0.08, 0)
	battle_stage.add_child(victim)

	var center := Marker3D.new()
	center.name = "ImpactAnchor"
	center.position = Vector3(0, BOARD_Y + 0.75, 0)
	battle_stage.add_child(center)

func _build_cameras() -> void:
	var root := Node3D.new()
	root.name = "Cameras"
	generated.add_child(root)

	gameplay_camera = Camera3D.new()
	gameplay_camera.name = "GameplayCamera"
	# User-approved gameplay composition: 3/4 side angle from the White-right
	# corner. Keep the complete board frame in view while still showing enough
	# cathedral depth to preserve the production environment.
	# 3/4 gameplay view from the open front-right entrance. The camera stays
	# outside the board footprint but enters through the cathedral opening,
	# avoiding side-wall occlusion while keeping the entire 8x8 board visible.
	# G1 composition refinement: keep the approved 3/4 side view but move
	# closer to the center of the open entrance so the near right column/capital
	# no longer occludes the board or HUD sightline.
	gameplay_camera.position = Vector3(7.8, 10.6, 16.8)
	gameplay_camera.fov = 45.5
	gameplay_camera.current = true
	root.add_child(gameplay_camera)
	gameplay_camera.look_at(Vector3(0, 0.72, -0.30), Vector3.UP)

	battle_camera = Camera3D.new()
	battle_camera.name = "BattleCamera"
	battle_camera.position = Vector3(0, 2.28, 4.95)
	battle_camera.fov = 40.5
	battle_camera.current = false
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		var battle_attributes := CameraAttributesPractical.new()
		battle_attributes.dof_blur_far_enabled = true
		battle_attributes.dof_blur_far_distance = 5.6
		battle_attributes.dof_blur_far_transition = 3.8
		battle_attributes.dof_blur_amount = 0.045
		battle_camera.attributes = battle_attributes
	root.add_child(battle_camera)
	battle_camera.look_at(Vector3(0, 0.92, -0.10), Vector3.UP)

func _build_lighting() -> void:
	var root := Node3D.new()
	root.name = "Lighting"
	generated.add_child(root)

	var sun := DirectionalLight3D.new()
	sun.name = "SunWarm"
	sun.light_color = Color("#ffe0ad")
	sun.light_energy = 0.96
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 36.0
	sun.directional_shadow_fade_start = 0.82
	sun.rotation_degrees = Vector3(-48, -38, 0)
	root.add_child(sun)

	var warm := OmniLight3D.new()
	warm.name = "WarmFill"
	warm.position = Vector3(-6.5, 6.8, -4.0)
	warm.light_color = Color("#ffc789")
	warm.light_energy = 1.05
	warm.omni_range = 15.0
	warm.shadow_enabled = true
	root.add_child(warm)

	var cool := OmniLight3D.new()
	cool.name = "CoolRim"
	cool.position = Vector3(6.5, 5.0, -2.0)
	cool.light_color = Color("#7f6fd2")
	cool.light_energy = 0.94
	cool.omni_range = 12.0
	root.add_child(cool)

	var window_key := OmniLight3D.new()
	window_key.name = "WindowSunFill"
	window_key.position = Vector3(-4.8, 7.8, -10.5)
	window_key.light_color = Color("#ffd895")
	window_key.light_energy = 1.32
	window_key.omni_range = 16.0
	window_key.shadow_enabled = true
	root.add_child(window_key)

	# D2 stained-glass light shaping. These are intentionally soft and low
	# energy: they tint architecture/contact shadows without recoloring pieces.
	var stained_red := OmniLight3D.new()
	stained_red.name = "StainedRed"
	stained_red.position = Vector3(-5.6, 5.4, -9.6)
	stained_red.light_color = Color("#cc4960")
	stained_red.light_energy = 0.52
	stained_red.omni_range = 9.5
	root.add_child(stained_red)

	var stained_gold := OmniLight3D.new()
	stained_gold.name = "StainedGold"
	stained_gold.position = Vector3(0.0, 6.0, -10.4)
	stained_gold.light_color = Color("#ffcf73")
	stained_gold.light_energy = 0.54
	stained_gold.omni_range = 10.5
	root.add_child(stained_gold)

	var stained_blue := OmniLight3D.new()
	stained_blue.name = "StainedBlue"
	stained_blue.position = Vector3(5.6, 5.0, -9.0)
	stained_blue.light_color = Color("#6e8fe0")
	stained_blue.light_energy = 0.36
	stained_blue.omni_range = 9.0
	root.add_child(stained_blue)

	# G2 cinematic-only neutral fill: raises battle readability while keeping the
	# normal gameplay cathedral mood untouched. Enabled by set_battle_lighting().
	var battle_neutral := OmniLight3D.new()
	battle_neutral.name = "BattleNeutralFill"
	battle_neutral.position = Vector3(0.0, 4.8, 5.8)
	battle_neutral.light_color = Color("#e9edf2")
	battle_neutral.light_energy = 0.0
	battle_neutral.omni_range = 13.5
	battle_neutral.shadow_enabled = false
	root.add_child(battle_neutral)

func _build_selection_root() -> void:
	selection_root = Node3D.new()
	selection_root.name = "SelectionOverlay"
	generated.add_child(selection_root)

func _build_last_move_root() -> void:
	last_move_root = Node3D.new()
	last_move_root.name = "LastMoveOverlay"
	generated.add_child(last_move_root)


func _build_danger_root() -> void:
	danger_root = Node3D.new()
	danger_root.name = "DangerOverlay"
	generated.add_child(danger_root)


func clear_danger() -> void:
	if danger_root == null:
		return
	for child in danger_root.get_children():
		child.queue_free()


func show_check_danger(square: StringName) -> void:
	clear_danger()
	if danger_root == null or square == &"":
		return
	_add_overlay_to(danger_root, square, Color(1.0, 0.12, 0.10, 0.34), 0.060, 0.94)
	var marker := get_socket(square)
	if marker == null:
		return
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = CELL_SIZE * 0.39
	ring_mesh.outer_radius = CELL_SIZE * 0.43
	ring_mesh.rings = 32
	ring_mesh.ring_segments = 8
	var ring := MeshInstance3D.new()
	ring.name = "CheckDangerRing"
	ring.mesh = ring_mesh
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.15, 0.08, 0.60)
	mat.emission_enabled = true
	mat.emission = Color("#ff3828")
	mat.emission_energy_multiplier = 2.4
	ring.material_override = mat
	ring.rotation_degrees.x = 90.0
	danger_root.add_child(ring)
	ring.global_position = marker.global_position + Vector3(0, 0.072, 0)


func clear_last_move() -> void:
	if last_move_root == null:
		return
	for child in last_move_root.get_children():
		child.queue_free()


func show_last_move(from_square: StringName, to_square: StringName) -> void:
	clear_last_move()
	if last_move_root == null:
		return
	_add_overlay_to(last_move_root, from_square, Color(0.27, 0.58, 0.92, 0.19), 0.045, 0.84)
	_add_overlay_to(last_move_root, to_square, Color(0.95, 0.72, 0.24, 0.25), 0.047, 0.84)


func _add_square_overlay(square: StringName, color: Color) -> void:
	_add_overlay_to(selection_root, square, color, 0.055, 0.90)


func _add_overlay_to(parent: Node3D, square: StringName, color: Color, y_offset: float, size_factor: float) -> void:
	if parent == null:
		return
	var marker := get_socket(square)
	if marker == null:
		return
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 1.15

	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL_SIZE * size_factor, 0.014, CELL_SIZE * size_factor)
	var overlay := MeshInstance3D.new()
	overlay.mesh = mesh
	overlay.material_override = mat
	parent.add_child(overlay)
	overlay.global_position = marker.global_position + Vector3(0, y_offset, 0)

func _build_pieces() -> void:
	pieces_root = Node3D.new()
	pieces_root.name = "Pieces"
	generated.add_child(pieces_root)
	_populate_pieces()

func _populate_pieces() -> void:
	var back_rank: Array[StringName] = [
		&"Rook", &"Knight", &"Bishop", &"Queen",
		&"King", &"Bishop", &"Knight", &"Rook"
	]

	for file_idx in range(8):
		var letter := String.chr(65 + file_idx)
		_spawn_piece(&"White", back_rank[file_idx], StringName("%s1" % letter))
		_spawn_piece(&"White", &"Pawn", StringName("%s2" % letter))
		_spawn_piece(&"Black", &"Pawn", StringName("%s7" % letter))
		_spawn_piece(&"Black", back_rank[file_idx], StringName("%s8" % letter))

func _spawn_piece(p_side: StringName, p_type: StringName, square: StringName) -> void:
	var marker := get_socket(square)
	var piece := PieceView.new()
	pieces_root.add_child(piece)
	piece.setup(p_type, p_side, square, marker.global_position)
	_pieces.append(piece)
	_piece_by_square[square] = piece

func _prepare_cathedral_material_cache() -> void:
	_cathedral_material_cache.clear()
	_cathedral_material_cache[&"glass_red"] = _cathedral_glass_material(Color("#d85f74"))
	_cathedral_material_cache[&"glass_gold"] = _cathedral_glass_material(Color("#e5b663"))
	_cathedral_material_cache[&"glass_blue"] = _cathedral_glass_material(Color("#6688ca"))
	_cathedral_material_cache[&"gold"] = _cathedral_gold_material()
	_cathedral_material_cache[&"cloth_red"] = _cathedral_cloth_material(Color("#6e2027"))
	_cathedral_material_cache[&"cloth_blue"] = _cathedral_cloth_material(Color("#263b62"))
	_cathedral_material_cache[&"flame"] = _cathedral_glass_material(Color("#ff9a3d"), 4.5)
	_cathedral_material_cache[&"wax"] = _mat(Color("#dfceb0"), 0.74, 0.0)
	_cathedral_material_cache[&"floor"] = _cathedral_stone_material(Color("#302a2b"), Color("#554846"), 0.58)
	_cathedral_material_cache[&"stone_dark"] = _cathedral_stone_material(Color("#383031"), Color("#5d5050"), 0.66)
	_cathedral_material_cache[&"stone"] = _cathedral_stone_material(Color("#766b60"), Color("#a19282"), 0.60)


func _apply_cathedral_material_overrides(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var n := String(mesh_instance.name)
		var key: StringName = &"stone"
		if n.contains("Glass"):
			key = &"glass_red"
			if n.contains("_1") or n.contains("Gold"):
				key = &"glass_gold"
			elif n.contains("_2") or n.contains("Blue"):
				key = &"glass_blue"
		elif n.contains("Gold") or n.contains("Trim") or n.contains("Frame") or n.contains("Cap") or n.contains("Halo") or n.contains("Bar") or n.contains("Band"):
			key = &"gold"
		elif n.contains("BannerWhite") or n.contains("Red"):
			key = &"cloth_red"
		elif n.contains("BannerBlack") or n.contains("Blue"):
			key = &"cloth_blue"
		elif n.contains("Flame"):
			key = &"flame"
		elif n.contains("Candle"):
			key = &"wax"
		elif n.contains("Floor"):
			key = &"floor"
		elif n.contains("StoneDark") or n.contains("Inset"):
			key = &"stone_dark"
		mesh_instance.material_override = _cathedral_material_cache.get(key)
	for child in node.get_children():
		_apply_cathedral_material_overrides(child)


func _cathedral_stone_material(base_color: Color, detail_color: Color, surface_roughness: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 base_color;
uniform vec3 detail_color;
uniform float surface_roughness = 0.60;
varying vec3 local_position;
void vertex() {
	local_position = VERTEX;
}
void fragment() {
	float broad = sin(local_position.x * 1.65 + local_position.y * 0.43 + local_position.z * 1.18);
	float fine_a = sin(local_position.x * 8.7 - local_position.z * 6.1 + local_position.y * 2.3);
	float fine_b = sin(local_position.x * 17.2 + local_position.z * 11.4);
	float detail = broad * 0.18 + fine_a * 0.08 + fine_b * 0.035;
	float speck = smoothstep(0.72, 0.96, abs(fine_a * 0.72 + fine_b * 0.28));
	ALBEDO = mix(base_color, detail_color, clamp(0.20 + detail + speck * 0.10, 0.0, 0.38));
	ROUGHNESS = clamp(surface_roughness + fine_b * 0.045, 0.38, 0.82);
	METALLIC = 0.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Vector3(base_color.r, base_color.g, base_color.b))
	material.set_shader_parameter("detail_color", Vector3(detail_color.r, detail_color.g, detail_color.b))
	material.set_shader_parameter("surface_roughness", surface_roughness)
	return material

func _cathedral_gold_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#b57a2d")
	material.metallic = 0.86
	material.roughness = 0.24
	return material

func _cathedral_cloth_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.0
	material.roughness = 0.72
	return material

func _cathedral_glass_material(color: Color, energy: float = 2.4) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.28)
	material.metallic = 0.0
	material.roughness = 0.18
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var mat := _mat(color, 0.16, 0.0)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat

func _box(parent: Node, node_name: String, size: Vector3, p: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = p
	mi.material_override = material
	parent.add_child(mi)
	return mi

func _cylinder(parent: Node, node_name: String, radius: float, height: float, p: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = p
	mi.material_override = material
	parent.add_child(mi)
	return mi

func _build_cathedral_details(root: Node3D, stone: Material, gold: Material) -> void:
	_build_arch(root, "CenterArch", Vector3(0, 4.8, -13.35), 4.9, 3.9, stone)
	_build_arch(root, "LeftArch", Vector3(-5.7, 4.7, -13.35), 3.0, 3.2, stone)
	_build_arch(root, "RightArch", Vector3(5.7, 4.7, -13.35), 3.0, 3.2, stone)
	var white_cloth := _mat(Color("#d8cfbb"), 0.66, 0.0)
	var black_cloth := _mat(Color("#281d36"), 0.60, 0.0)
	_build_banner(root, Vector3(-9.6, 6.6, -5.0), white_cloth, gold)
	_build_banner(root, Vector3(-9.6, 6.6, 3.2), white_cloth, gold)
	_build_banner(root, Vector3(9.6, 6.6, -5.0), black_cloth, gold)
	_build_banner(root, Vector3(9.6, 6.6, 3.2), black_cloth, gold)
	_build_statue(root, Vector3(-3.7, 1.0, -11.6), stone)
	_build_statue(root, Vector3(3.7, 1.0, -11.6), stone)

	# Large side-wall stained glass to match the approved cathedral reference.
	_build_side_window(root, Vector3(-10.72, 5.9, 5.2), Color("#e6b75a"), gold)
	_build_side_window(root, Vector3(-10.72, 5.9, 0.0), Color("#d97f88"), gold)
	_build_side_window(root, Vector3(-10.72, 5.9, -5.2), Color("#8dcfe4"), gold)

	# Back-wall heraldic banners remain visible in the gameplay camera.
	var red_banner := _mat(Color("#8f3f43"), 0.62, 0.0)
	var blue_banner := _mat(Color("#405f83"), 0.62, 0.0)
	_build_back_banner(root, Vector3(-5.1, 6.7, -13.58), red_banner, gold)
	_build_back_banner(root, Vector3(5.1, 6.7, -13.58), blue_banner, gold)

	for p in [Vector3(-6.2, 0, -8.0), Vector3(6.2, 0, -8.0), Vector3(-6.8, 0, 6.2), Vector3(6.8, 0, 6.2)]:
		_build_candles(root, p, gold)

func _build_arch(parent: Node3D, arch_name: String, center: Vector3, width: float, height: float, material: Material) -> void:
	var arch := Node3D.new()
	arch.name = arch_name
	arch.position = center
	parent.add_child(arch)
	var radius := width * 0.5
	_box(arch, "LeftPillar", Vector3(0.34, height, 0.34), Vector3(-radius, height * 0.5, 0), material)
	_box(arch, "RightPillar", Vector3(0.34, height, 0.34), Vector3(radius, height * 0.5, 0), material)
	var segments := 13
	for i in range(segments):
		var t := float(i) / float(segments - 1)
		var angle := lerpf(PI, 0.0, t)
		var segment := _box(arch, "Arch_%02d" % i, Vector3(width / float(segments) * 1.38, 0.34, 0.34), Vector3(cos(angle) * radius, height + sin(angle) * radius, 0), material)
		segment.rotation.z = -angle + PI * 0.5

func _build_banner(parent: Node3D, p: Vector3, cloth: Material, gold: Material) -> void:
	var root := Node3D.new()
	root.name = "TeamBanner"
	root.position = p
	parent.add_child(root)
	_box(root, "TopBar", Vector3(1.8, 0.10, 0.10), Vector3(0, 1.35, 0), gold)
	_box(root, "Cloth", Vector3(1.5, 2.45, 0.06), Vector3(0, 0, 0), cloth)

func _build_statue(parent: Node3D, p: Vector3, material: Material) -> void:
	var root := Node3D.new()
	root.name = "Statue"
	root.position = p
	parent.add_child(root)
	_box(root, "Pedestal", Vector3(1.15, 0.85, 1.15), Vector3(0, 0.425, 0), material)
	_cylinder(root, "Body", 0.30, 1.75, Vector3(0, 1.65, 0), material)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.32
	head_mesh.height = 0.64
	var head := MeshInstance3D.new()
	head.mesh = head_mesh
	head.material_override = material
	head.position = Vector3(0, 2.75, 0)
	root.add_child(head)

func _build_candles(parent: Node3D, p: Vector3, holder: Material) -> void:
	var root := Node3D.new()
	root.name = "CandleCluster"
	root.position = p
	parent.add_child(root)
	var wax := _mat(Color("#e7d8b3"), 0.72, 0.0)
	var flame := _emissive(Color("#ffad55"), 4.0)
	for i in range(5):
		var angle := TAU * float(i) / 5.0
		var cp := Vector3(cos(angle) * 0.22, 0.30 + (i % 2) * 0.06, sin(angle) * 0.22)
		_cylinder(root, "Candle", 0.045, 0.45 + (i % 2) * 0.10, cp, wax)
		var flame_mesh := SphereMesh.new()
		flame_mesh.radius = 0.05
		flame_mesh.height = 0.13
		var f := MeshInstance3D.new()
		f.mesh = flame_mesh
		f.material_override = flame
		f.position = cp + Vector3(0, 0.28, 0)
		root.add_child(f)
	_cylinder(root, "Holder", 0.34, 0.08, Vector3(0, 0.04, 0), holder)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.75, 0)
	light.light_color = Color("#ffb064")
	light.light_energy = 0.8
	light.omni_range = 2.8
	root.add_child(light)

func _marble_material(base_color: Color, vein_color: Color, surface_roughness: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 base_color;
uniform vec3 vein_color;
uniform float surface_roughness = 0.26;
varying vec3 local_position;
void vertex() {
	local_position = VERTEX;
}
void fragment() {
	float a = sin(local_position.x * 7.0 + local_position.z * 5.0 + sin(local_position.z * 3.5) * 1.4);
	float b = sin(local_position.x * 15.0 - local_position.z * 8.0);
	float v = abs(a * 0.78 + b * 0.22);
	float vein = smoothstep(0.72, 0.98, v);
	ALBEDO = mix(base_color, vein_color, vein * 0.36);
	ROUGHNESS = surface_roughness;
	METALLIC = 0.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Vector3(base_color.r, base_color.g, base_color.b))
	material.set_shader_parameter("vein_color", Vector3(vein_color.r, vein_color.g, vein_color.b))
	material.set_shader_parameter("surface_roughness", surface_roughness)
	return material

func _wood_material(base_color: Color, grain_color: Color, surface_roughness: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 base_color;
uniform vec3 grain_color;
uniform float surface_roughness = 0.30;
varying vec3 local_position;
void vertex() {
	local_position = VERTEX;
}
void fragment() {
	float wav = sin(local_position.x * 12.0 + sin(local_position.z * 4.0) * 2.2);
	float fine = sin(local_position.x * 31.0 + local_position.z * 2.0);
	float grain = smoothstep(0.10, 0.90, wav * 0.35 + fine * 0.15 + 0.50);
	ALBEDO = mix(base_color, grain_color, grain * 0.34);
	ROUGHNESS = surface_roughness;
	METALLIC = 0.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Vector3(base_color.r, base_color.g, base_color.b))
	material.set_shader_parameter("grain_color", Vector3(grain_color.r, grain_color.g, grain_color.b))
	material.set_shader_parameter("surface_roughness", surface_roughness)
	return material

func _build_side_window(parent: Node3D, p: Vector3, color: Color, frame_mat: Material) -> void:
	var glass := _emissive(color, 2.0)
	_box(parent, "SideGlass", Vector3(0.08, 4.8, 2.30), p, glass)
	_box(parent, "SideFrameTop", Vector3(0.14, 0.12, 2.55), p + Vector3(0.0, 2.42, 0.0), frame_mat)
	_box(parent, "SideFrameBottom", Vector3(0.14, 0.12, 2.55), p + Vector3(0.0, -2.42, 0.0), frame_mat)
	_box(parent, "SideFrameMid", Vector3(0.14, 4.95, 0.10), p, frame_mat)
	_box(parent, "SideFrameCross", Vector3(0.14, 0.10, 2.45), p + Vector3(0.0, 0.45, 0.0), frame_mat)

func _build_back_banner(parent: Node3D, p: Vector3, cloth: Material, gold: Material) -> void:
	var root := Node3D.new()
	root.name = "BackBanner"
	root.position = p
	parent.add_child(root)
	_box(root, "Bar", Vector3(2.1, 0.10, 0.10), Vector3(0, 1.55, 0), gold)
	_box(root, "Cloth", Vector3(1.75, 2.75, 0.06), Vector3(0, 0, 0), cloth)
	_box(root, "CrestV", Vector3(0.12, 0.80, 0.035), Vector3(0, 0.20, -0.05), gold)
	_box(root, "CrestH", Vector3(0.70, 0.12, 0.035), Vector3(0, 0.20, -0.05), gold)
