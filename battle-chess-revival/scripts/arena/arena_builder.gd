class_name ArenaBuilder
extends Node3D

const CELL_SIZE := 1.20
const BOARD_Y := 0.38

var generated: Node3D
var board_root: Node3D
var sockets_root: Node3D
var pieces_root: Node3D
var battle_stage: Node3D
var gameplay_camera: Camera3D
var battle_camera: Camera3D

var _pieces: Array[PieceView] = []
var _sockets: Dictionary = {}

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

func get_square_count() -> int:
	return _sockets.size()

func get_piece_count() -> int:
	return _pieces.size()

func get_all_pieces() -> Array[PieceView]:
	return _pieces

func get_socket(square: StringName) -> Marker3D:
	return _sockets.get(square) as Marker3D

func find_piece(p_side: StringName, p_type: StringName, occurrence: int = 0) -> PieceView:
	var found := 0
	for piece in _pieces:
		if piece.side == p_side and piece.piece_type == p_type:
			if found == occurrence:
				return piece
			found += 1
	return null

func set_demo_focus(attacker: PieceView, victim: PieceView, focused: bool) -> void:
	for piece in _pieces:
		if piece == attacker or piece == victim:
			piece.visible = true
		else:
			piece.visible = not focused

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#171317")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b9a48f")
	env.ambient_light_energy = 0.34
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.35
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
	var root := Node3D.new()
	root.name = "Cathedral"
	generated.add_child(root)

	var stone := _mat(Color("#625b55"), 0.72, 0.0)
	var floor_mat := _mat(Color("#302d2c"), 0.48, 0.0)
	var red := _mat(Color("#5b1f26"), 0.62, 0.0)
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

func _build_board() -> void:
	board_root = Node3D.new()
	board_root.name = "ChessBoard"
	generated.add_child(board_root)

	sockets_root = Node3D.new()
	sockets_root.name = "PieceSockets"
	generated.add_child(sockets_root)

	var cream := _mat(Color("#ddcfb3"), 0.24, 0.0)
	var green := _mat(Color("#184838"), 0.22, 0.0)
	var gold := _mat(Color("#b98632"), 0.20, 0.92)
	var base := _mat(Color("#211916"), 0.46, 0.0)

	_box(board_root, "Base", Vector3(10.9, 0.30, 10.9), Vector3(0, 0.15, 0), base)
	_box(board_root, "GoldFrame", Vector3(10.45, 0.18, 10.45), Vector3(0, 0.31, 0), gold)

	for rank_idx in range(8):
		for file_idx in range(8):
			var x := (float(file_idx) - 3.5) * CELL_SIZE
			var z := (3.5 - float(rank_idx)) * CELL_SIZE
			var square := StringName("%s%d" % [String.chr(65 + file_idx), rank_idx + 1])
			var material := cream if (file_idx + rank_idx) % 2 == 0 else green
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
	gameplay_camera.position = Vector3(0, 10.5, 12.5)
	gameplay_camera.fov = 32.0
	gameplay_camera.current = true
	root.add_child(gameplay_camera)
	gameplay_camera.look_at(Vector3(0, 0.65, 0), Vector3.UP)

	battle_camera = Camera3D.new()
	battle_camera.name = "BattleCamera"
	battle_camera.position = Vector3(0, 2.55, 5.4)
	battle_camera.fov = 38.0
	battle_camera.current = false
	root.add_child(battle_camera)
	battle_camera.look_at(Vector3(0, 0.85, 0), Vector3.UP)

func _build_lighting() -> void:
	var root := Node3D.new()
	root.name = "Lighting"
	generated.add_child(root)

	var sun := DirectionalLight3D.new()
	sun.name = "SunWarm"
	sun.light_color = Color("#ffd4a0")
	sun.light_energy = 1.45
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48, -38, 0)
	root.add_child(sun)

	var warm := OmniLight3D.new()
	warm.name = "WarmFill"
	warm.position = Vector3(-6.5, 6.8, -4.0)
	warm.light_color = Color("#ffb76f")
	warm.light_energy = 5.5
	warm.omni_range = 15.0
	root.add_child(warm)

	var cool := OmniLight3D.new()
	cool.name = "CoolRim"
	cool.position = Vector3(6.5, 5.0, -2.0)
	cool.light_color = Color("#755cff")
	cool.light_energy = 3.4
	cool.omni_range = 12.0
	root.add_child(cool)

func _build_pieces() -> void:
	pieces_root = Node3D.new()
	pieces_root.name = "Pieces"
	generated.add_child(pieces_root)

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
