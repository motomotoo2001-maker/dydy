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
	_prepare_asset_lineup(arena, &"White")
	await process_frame
	await RenderingServer.frame_post_draw
	var white_lineup := get_root().get_texture().get_image()
	var white_lineup_error := white_lineup.save_png("res://asset_lineup_white.png")
	if white_lineup_error != OK:
		push_error("RENDER_CAPTURE_FAIL: white asset lineup save_png error %s" % white_lineup_error)
		quit(1)
		return

	_prepare_asset_lineup(arena, &"Black")
	await process_frame
	await RenderingServer.frame_post_draw
	var black_lineup := get_root().get_texture().get_image()
	var black_lineup_error := black_lineup.save_png("res://asset_lineup_black.png")
	if black_lineup_error != OK:
		push_error("RENDER_CAPTURE_FAIL: black asset lineup save_png error %s" % black_lineup_error)
		quit(1)
		return

	_prepare_asset_review(arena, &"White", &"Pawn")
	await process_frame
	await RenderingServer.frame_post_draw
	var pawn_review := get_root().get_texture().get_image()
	var pawn_review_error := pawn_review.save_png("res://asset_review_white_pawn.png")
	if pawn_review_error != OK:
		push_error("RENDER_CAPTURE_FAIL: white pawn review save_png error %s" % pawn_review_error)
		quit(1)
		return

	_prepare_asset_review(arena, &"White", &"Knight")
	await process_frame
	await RenderingServer.frame_post_draw
	var white_knight_review := get_root().get_texture().get_image()
	var white_knight_review_error := white_knight_review.save_png("res://asset_review_white_knight.png")
	if white_knight_review_error != OK:
		push_error("RENDER_CAPTURE_FAIL: white knight review save_png error %s" % white_knight_review_error)
		quit(1)
		return

	_prepare_asset_review(arena, &"Black", &"Knight")
	await process_frame
	await RenderingServer.frame_post_draw
	var black_knight_review := get_root().get_texture().get_image()
	var black_knight_review_error := black_knight_review.save_png("res://asset_review_black_knight.png")
	if black_knight_review_error != OK:
		push_error("RENDER_CAPTURE_FAIL: black knight review save_png error %s" % black_knight_review_error)
		quit(1)
		return

	_prepare_asset_review(arena, &"White", &"Bishop")
	await process_frame
	await RenderingServer.frame_post_draw
	var white_bishop_review := get_root().get_texture().get_image()
	var white_bishop_review_error := white_bishop_review.save_png("res://asset_review_white_bishop.png")
	if white_bishop_review_error != OK:
		push_error("RENDER_CAPTURE_FAIL: white bishop review save_png error %s" % white_bishop_review_error)
		quit(1)
		return

	_prepare_asset_review(arena, &"Black", &"Bishop")
	await process_frame
	await RenderingServer.frame_post_draw
	var black_bishop_review := get_root().get_texture().get_image()
	var black_bishop_review_error := black_bishop_review.save_png("res://asset_review_black_bishop.png")
	if black_bishop_review_error != OK:
		push_error("RENDER_CAPTURE_FAIL: black bishop review save_png error %s" % black_bishop_review_error)
		quit(1)
		return

	_prepare_asset_review(arena, &"White", &"Rook")
	await process_frame
	await RenderingServer.frame_post_draw
	var white_rook_review := get_root().get_texture().get_image()
	var white_rook_review_error := white_rook_review.save_png("res://asset_review_white_rook.png")
	if white_rook_review_error != OK:
		push_error("RENDER_CAPTURE_FAIL: white rook review save_png error %s" % white_rook_review_error)
		quit(1)
		return

	_prepare_asset_review(arena, &"Black", &"Rook")
	await process_frame
	await RenderingServer.frame_post_draw
	var black_rook_review := get_root().get_texture().get_image()
	var black_rook_review_error := black_rook_review.save_png("res://asset_review_black_rook.png")
	if black_rook_review_error != OK:
		push_error("RENDER_CAPTURE_FAIL: black rook review save_png error %s" % black_rook_review_error)
		quit(1)
		return

	print("RENDER_CAPTURE_PASS gameplay=", image.get_width(), "x", image.get_height(), " captures=", CAPTURES.size(), " lineups=2 reviews=7")
	root.queue_free()
	await process_frame
	quit(0)


func _prepare_asset_lineup(arena: ArenaBuilder, side: StringName) -> void:
	var types: Array[StringName] = [&"Pawn", &"Knight", &"Bishop", &"Rook", &"Queen", &"King"]
	for piece in arena.get_all_pieces():
		piece.visible = false

	for index in range(types.size()):
		var x := (float(index) - 2.5) * 1.48
		var piece := arena.find_piece(side, types[index])
		if piece:
			piece.visible = true
			piece.reset_visual()
			piece.global_position = Vector3(x, 0.54, 0.0)
			piece.rotation_degrees = Vector3.ZERO

	arena.gameplay_camera.current = false
	arena.battle_camera.current = true
	arena.battle_camera.position = Vector3(0, 2.65, -8.8)
	arena.battle_camera.fov = 42.0
	arena.battle_camera.look_at(Vector3(0, 1.02, 0), Vector3.UP)


func _prepare_asset_review(arena: ArenaBuilder, side: StringName, piece_type: StringName) -> void:
	for piece in arena.get_all_pieces():
		piece.visible = false

	var piece := arena.find_piece(side, piece_type)
	if piece:
		piece.visible = true
		piece.reset_visual()
		piece.global_position = Vector3(0, 0.54, 0)
		piece.rotation_degrees = Vector3.ZERO

	arena.gameplay_camera.current = false
	arena.battle_camera.current = true
	arena.battle_camera.position = Vector3(2.8, 2.1, -4.6)
	arena.battle_camera.fov = 34.0
	arena.battle_camera.look_at(Vector3(0, 1.35, 0), Vector3.UP)
