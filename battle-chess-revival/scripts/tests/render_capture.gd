extends SceneTree

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

	for i in range(8):
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
	director.time_scale = 0.45
	director.play_signature(&"pawn_toe_stab")
	await create_timer(0.22).timeout
	await RenderingServer.frame_post_draw

	var battle_image := get_root().get_texture().get_image()
	var battle_error := battle_image.save_png("res://battle_reference.png")
	if battle_error != OK:
		push_error("RENDER_CAPTURE_FAIL: battle save_png error %s" % battle_error)
		quit(1)
		return

	while director.busy:
		await process_frame

	print("RENDER_CAPTURE_PASS gameplay=", image.get_width(), "x", image.get_height(), " battle=", battle_image.get_width(), "x", battle_image.get_height())
	root.queue_free()
	await process_frame
	quit(0)
