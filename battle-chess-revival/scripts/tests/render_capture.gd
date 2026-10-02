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
		push_error("RENDER_CAPTURE_FAIL: save_png error %s" % error)
		quit(1)
		return

	print("RENDER_CAPTURE_PASS size=", image.get_width(), "x", image.get_height())
	root.queue_free()
	await process_frame
	quit(0)
