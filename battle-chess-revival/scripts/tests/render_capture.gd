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
	director.time_scale = 0.42

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

	print("RENDER_CAPTURE_PASS gameplay=", image.get_width(), "x", image.get_height(), " captures=", CAPTURES.size())
	root.queue_free()
	await process_frame
	quit(0)
