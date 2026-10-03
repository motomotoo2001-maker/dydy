extends SceneTree

const REQUIRED_RESOURCES := [
	"res://assets/models/white_pawn_production_v1.glb",
	"res://assets/models/black_pawn_production_v1.glb",
	"res://assets/models/white_knight_rigged_v1.glb",
	"res://assets/models/black_knight_rigged_v1.glb",
	"res://assets/models/white_bishop_rigged_v1.glb",
	"res://assets/models/black_bishop_rigged_v1.glb",
	"res://assets/models/white_rook_rigged_v1.glb",
	"res://assets/models/black_rook_rigged_v1.glb",
	"res://assets/models/white_queen_rigged_v1.glb",
	"res://assets/models/black_queen_rigged_v1.glb",
	"res://assets/models/white_king_rigged_v1.glb",
	"res://assets/models/black_king_rigged_v1.glb",
	"res://assets/models/cathedral_production_v1.glb",
	"res://assets/audio/cathedral_ambience.wav",
	"res://assets/audio/ui_select.wav",
	"res://assets/audio/move.wav",
	"res://assets/audio/check.wav",
	"res://assets/audio/checkmate.wav",
	"res://assets/audio/impact_pawn.wav",
	"res://assets/audio/impact_knight.wav",
	"res://assets/audio/impact_bishop.wav",
	"res://assets/audio/impact_rook.wav",
	"res://assets/audio/impact_queen.wav",
	"res://assets/audio/impact_king.wav",
]

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("RELEASE_AUDIT_FAIL: " + message)
	quit(2)

func _run() -> void:
	for path in REQUIRED_RESOURCES:
		if not ResourceLoader.exists(path):
			_fail("missing production resource: %s" % path)
			return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene missing")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var arena := scene.get_node_or_null("ArenaBuilder") as ArenaBuilder
	var audio := scene.get_node_or_null("AudioDirector") as AudioDirector
	var controller := scene.get_node_or_null("ChessController") as ChessController
	if arena == null or audio == null or controller == null:
		_fail("main runtime components missing")
		return

	if arena.get_square_count() != 64 or arena.get_piece_count() != 32:
		_fail("board contract failed squares=%d pieces=%d" % [arena.get_square_count(), arena.get_piece_count()])
		return
	if audio.asset_count() != 11:
		_fail("audio contract failed assets=%d" % audio.asset_count())
		return
	if arena.gameplay_camera.position.x < 5.0:
		_fail("gameplay camera is no longer a 3/4 side view")
		return

	var viewport_size := root.get_viewport().get_visible_rect().size
	var half_board := 5.72
	var corners := [
		Vector3(-half_board, ArenaBuilder.BOARD_Y + 0.10, -half_board),
		Vector3(half_board, ArenaBuilder.BOARD_Y + 0.10, -half_board),
		Vector3(-half_board, ArenaBuilder.BOARD_Y + 0.10, half_board),
		Vector3(half_board, ArenaBuilder.BOARD_Y + 0.10, half_board),
	]
	var min_margin := 8.0
	for corner in corners:
		if arena.gameplay_camera.is_position_behind(corner):
			_fail("board corner is behind gameplay camera: %s" % corner)
			return
		var screen := arena.gameplay_camera.unproject_position(corner)
		if screen.x < min_margin or screen.x > viewport_size.x - min_margin or screen.y < min_margin or screen.y > viewport_size.y - min_margin:
			_fail("board corner outside viewport: world=%s screen=%s viewport=%s" % [corner, screen, viewport_size])
			return

	var cathedral := arena.generated.get_node_or_null("CathedralProductionV1")
	if cathedral == null:
		_fail("production cathedral not instantiated")
		return
	var unique_materials: Dictionary = {}
	var cathedral_meshes := _collect_materials(cathedral, unique_materials)
	if cathedral_meshes < 100:
		_fail("cathedral mesh density regressed: %d" % cathedral_meshes)
		return
	if unique_materials.size() > 11:
		_fail("cathedral material cache regressed unique=%d" % unique_materials.size())
		return
	if unique_materials.size() < 6:
		_fail("cathedral material classification too low unique=%d" % unique_materials.size())
		return

	for node_name in ["TurnPanel", "HintPanel", "PauseOverlay", "EndgameOverlay", "RematchButton"]:
		if controller.find_child(node_name, true, false) == null:
			_fail("required UX node missing: %s" % node_name)
			return

	print("RELEASE_AUDIT_PASS squares=64 pieces=32 audio=11 cathedral_meshes=", cathedral_meshes,
		" shared_materials=", unique_materials.size(), " viewport=", viewport_size,
		" camera=", arena.gameplay_camera.position)
	scene.queue_free()
	await process_frame
	quit(0)

func _collect_materials(node: Node, unique_materials: Dictionary) -> int:
	var count := 0
	if node is MeshInstance3D:
		count += 1
		var mesh := node as MeshInstance3D
		if mesh.material_override != null:
			unique_materials[mesh.material_override.get_instance_id()] = true
	for child in node.get_children():
		count += _collect_materials(child, unique_materials)
	return count
