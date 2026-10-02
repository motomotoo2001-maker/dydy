extends SceneTree

const CAPTURES := [
	[&"pawn_toe_stab", "capture_pawn.png"],
	[&"knight_double_kick", "capture_knight.png"],
	[&"bishop_ram", "capture_bishop.png"],
	[&"rook_crush", "capture_rook.png"],
	[&"queen_transform", "capture_queen.png"],
	[&"king_trapdoor", "capture_king.png"]
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("RENDER_CAPTURE_FAIL: main scene missing")
		quit(1)
		return

	var root := packed.instantiate()
	get_root().add_child(root)

	for i in range(10):
		await process_frame
	await RenderingServer.frame_post_draw

	var image := get_root().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("RENDER_CAPTURE_FAIL: empty viewport image")
		quit(1)
		return

	var error := image.save_png("res://gameplay_reference.png")
	if error != OK:
		push_error("RENDER_CAPTURE_FAIL: gameplay save_png error %s" % error)
		quit(1)
		return

	var director := root.get_node("BattleDirector") as BattleDirector
	director.time_scale = 0.30

	for index in range(CAPTURES.size()):
		var id: StringName = CAPTURES[index][0]
		var file_name: String = CAPTURES[index][1]
		director.play_signature(id)
		await director.capture_impact
		await process_frame
		await RenderingServer.frame_post_draw

		var impact_image := get_root().get_texture().get_image()
		if impact_image == null or impact_image.is_empty():
			push_error("RENDER_CAPTURE_FAIL: empty impact image for %s" % String(id))
			quit(1)
			return
		var save_error := impact_image.save_png("res://%s" % file_name)
		if save_error != OK:
			push_error("RENDER_CAPTURE_FAIL: %s save_png error %s" % [file_name, save_error])
			quit(1)
			return
		if index == 0:
			impact_image.save_png("res://battle_reference.png")

		while director.busy:
			await process_frame
		await process_frame

	var arena := root.get_node("ArenaBuilder") as ArenaBuilder
	_prepare_asset_lineup(arena)
	await process_frame
	await RenderingServer.frame_post_draw
	var lineup_image := get_root().get_texture().get_image()
	var lineup_error := lineup_image.save_png("res://asset_lineup.png")
	if lineup_error != OK:
		push_error("RENDER_CAPTURE_FAIL: asset lineup save_png error %s" % lineup_error)
		quit(1)
		return

	print("RENDER_CAPTURE_PASS gameplay=", image.get_width(), "x", image.get_height(), " captures=", CAPTURES.size(), " lineup=asset_lineup.png")
	root.queue_free()
	await process_frame
	quit(0)


func _prepare_asset_lineup(arena: ArenaBuilder) -> void:
	var types: Array[StringName] = [&"Pawn", &"Knight", &"Bishop", &"Rook", &"Queen", &"King"]
	for piece in arena.get_all_pieces():
		piece.visible = false

	for index in range(types.size()):
		var x := (float(index) - 2.5) * 1.55
		var white := arena.find_piece(&"White", types[index])
		var black := arena.find_piece(&"Black", types[index])
		if white:
			white.visible = true
			white.reset_visual()
			white.global_position = Vector3(x, 0.54, 0.72)
			white.rotation_degrees = Vector3(0, 0, 0)
		if black:
			black.visible = true
			black.reset_visual()
			black.global_position = Vector3(x, 0.54, -0.72)
			black.rotation_degrees = Vector3(0, 0, 0)

	arena.gameplay_camera.current = false
	arena.battle_camera.current = true
	arena.battle_camera.position = Vector3(0, 3.35, -11.2)
	arena.battle_camera.fov = 43.0
	arena.battle_camera.look_at(Vector3(0, 1.05, 0), Vector3.UP)
