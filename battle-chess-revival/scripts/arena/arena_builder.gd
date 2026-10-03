class_name ArenaBuilder
extends Node3D

const CELL_SIZE := 1.20
const BOARD_Y := 0.38
const CATHEDRAL_ASSET_PATH := "res://assets/models/cathedral_production_v1.glb"

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
var _selected_piece: PieceView

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
	await piece.begin_move_presentation()
	if piece.piece_type == &"Knight":
		var midpoint := (piece.global_position + target) * 0.5
		midpoint.y += 0.62
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "global_position", midpoint, 0.18)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(piece, "global_position", target, 0.18)
		await tween.finished
	else:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(piece, "global_position", target, 0.28)
		await tween.finished
	await piece.end_move_presentation()

func reset_pieces() -> void:
	clear_selection()
	if pieces_root == null:
		return
	for child in pieces_root.get_children():
		child.free()
	_pieces.clear()
	_piece_by_square.clear()
	_populate_pieces()

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
	if sun:
		sun.light_energy = 0.50 if active else 0.92
	if warm:
		warm.light_energy = 0.28 if active else 0.92
	if cool:
		cool.light_energy = 0.82 if active else 1.05
	if window:
		window.light_energy = 0.30 if active else 1.20

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#171214")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c6b7aa")
	env.ambient_light_energy = 0.25
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
	gameplay_camera.position = Vector3(0, 8.55, 13.15)
	gameplay_camera.fov = 39.5
	gameplay_camera.current = true
	root.add_child(gameplay_camera)
	gameplay_camera.look_at(Vector3(0, 0.95, -0.55), Vector3.UP)

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
	sun.light_color = Color("#ffe7bd")
	sun.light_energy = 0.92
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 36.0
	sun.directional_shadow_fade_start = 0.82
	sun.rotation_degrees = Vector3(-48, -38, 0)
	root.add_child(sun)

	var warm := OmniLight3D.new()
	warm.name = "WarmFill"
	warm.position = Vector3(-6.5, 6.8, -4.0)
	warm.light_color = Color("#f6c898")
	warm.light_energy = 0.92
	warm.omni_range = 15.0
	warm.shadow_enabled = true
	root.add_child(warm)

	var cool := OmniLight3D.new()
	cool.name = "CoolRim"
	cool.position = Vector3(6.5, 5.0, -2.0)
	cool.light_color = Color("#755cff")
	cool.light_energy = 1.05
	cool.omni_range = 12.0
	root.add_child(cool)

	var window_key := OmniLight3D.new()
	window_key.name = "WindowSunFill"
	window_key.position = Vector3(-4.8, 7.8, -10.5)
	window_key.light_color = Color("#ffe2ac")
	window_key.light_energy = 1.20
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
	stained_gold.light_energy = 0.48
	stained_gold.omni_range = 10.5
	root.add_child(stained_gold)

	var stained_blue := OmniLight3D.new()
	stained_blue.name = "StainedBlue"
	stained_blue.position = Vector3(5.6, 5.0, -9.0)
	stained_blue.light_color = Color("#6e8fe0")
	stained_blue.light_energy = 0.42
	stained_blue.omni_range = 9.0
	root.add_child(stained_blue)

func _build_selection_root() -> void:
	selection_root = Node3D.new()
	selection_root.name = "SelectionOverlay"
	generated.add_child(selection_root)

func _add_square_overlay(square: StringName, color: Color) -> void:
	var marker := get_socket(square)
	if marker == null:
		return
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 1.3

	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL_SIZE * 0.90, 0.018, CELL_SIZE * 0.90)
	var overlay := MeshInstance3D.new()
	overlay.mesh = mesh
	overlay.material_override = mat
	selection_root.add_child(overlay)
	overlay.global_position = marker.global_position + Vector3(0, 0.055, 0)

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

func _apply_cathedral_material_overrides(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var n := String(mesh_instance.name)
		if n.contains("Glass"):
			var glass_color := Color("#d85f74")
			if n.contains("_1") or n.contains("Gold"):
				glass_color = Color("#e5b663")
			elif n.contains("_2") or n.contains("Blue"):
				glass_color = Color("#6688ca")
			mesh_instance.material_override = _cathedral_glass_material(glass_color)
		elif n.contains("Gold") or n.contains("Trim") or n.contains("Frame") or n.contains("Cap") or n.contains("Halo") or n.contains("Bar") or n.contains("Band"):
			mesh_instance.material_override = _cathedral_gold_material()
		elif n.contains("BannerWhite") or n.contains("Red"):
			mesh_instance.material_override = _cathedral_cloth_material(Color("#6e2027"))
		elif n.contains("BannerBlack") or n.contains("Blue"):
			mesh_instance.material_override = _cathedral_cloth_material(Color("#263b62"))
		elif n.contains("Flame"):
			mesh_instance.material_override = _cathedral_glass_material(Color("#ff9a3d"), 4.5)
		elif n.contains("Candle"):
			mesh_instance.material_override = _mat(Color("#dfceb0"), 0.74, 0.0)
		elif n.contains("Floor"):
			mesh_instance.material_override = _cathedral_stone_material(Color("#302a2b"), Color("#554846"), 0.58)
		elif n.contains("StoneDark") or n.contains("Inset"):
			mesh_instance.material_override = _cathedral_stone_material(Color("#383031"), Color("#5d5050"), 0.66)
		else:
			mesh_instance.material_override = _cathedral_stone_material(Color("#766b60"), Color("#a19282"), 0.60)
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
