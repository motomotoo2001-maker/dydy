extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("PAWN_REVIEW_FAIL: main scene missing")
		quit(1)
		return
	var root := packed.instantiate()
	get_root().add_child(root)
	for i in range(18):
		await process_frame
	await RenderingServer.frame_post_draw

	var arena := root.get_node("ArenaBuilder") as ArenaBuilder
	for piece in arena.get_all_pieces():
		piece.visible = false

	var white := arena.find_piece(&"White", &"Pawn")
	var black := arena.find_piece(&"Black", &"Pawn")
	if white == null or black == null:
		push_error("PAWN_REVIEW_FAIL: pawn missing")
		quit(1)
		return

	white.visible = true
	white.reset_visual()
	white.global_position = Vector3(-0.95, 0.54, 0.0)
	white.rotation_degrees = Vector3.ZERO
	black.visible = true
	black.reset_visual()
	black.global_position = Vector3(0.95, 0.54, 0.0)
	black.rotation_degrees = Vector3.ZERO

	arena.gameplay_camera.current = false
	arena.battle_camera.current = true
	arena.battle_camera.position = Vector3(0.0, 2.15, -5.7)
	arena.battle_camera.fov = 35.0
	arena.battle_camera.look_at(Vector3(0, 1.45, 0), Vector3.UP)
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw

	var image := get_root().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("PAWN_REVIEW_FAIL: empty image")
		quit(1)
		return
	var err := image.save_png("res://asset_review_pawns_production_v2.png")
	if err != OK:
		push_error("PAWN_REVIEW_FAIL: save error %s" % err)
		quit(1)
		return
	print("PAWN_REVIEW_PASS ", image.get_width(), "x", image.get_height())
	root.queue_free()
	await process_frame
	quit(0)
