class_name ChessController
extends Node

var arena: ArenaBuilder
var battle_director: BattleDirector
var state := ChessState.new()
var ai := ChessAI.new()
var selected_square: StringName = &""
var selected_moves: Array[Dictionary] = []
var input_locked := false
var ai_enabled := true
var status_label: Label
var help_label: Label

func setup(p_arena: ArenaBuilder, p_battle_director: BattleDirector) -> void:
	arena = p_arena
	battle_director = p_battle_director
	_build_hud()
	_refresh_hud()

func _unhandled_input(event: InputEvent) -> void:
	if arena == null or input_locked or battle_director.busy:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			restart_game()
			return
		if event.keycode == KEY_A:
			ai_enabled = not ai_enabled
			_refresh_hud()
			return
	if ai_enabled and state.turn == ChessState.BLACK:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var square := _screen_to_square(event.position)
		if square != &"":
			_handle_square_click(square)

func _handle_square_click(square: StringName) -> void:
	var piece := state.get_piece(square)
	if selected_square == &"":
		if not piece.is_empty() and piece["side"] == state.turn:
			_select(square)
		return
	if not piece.is_empty() and piece["side"] == state.turn:
		_select(square)
		return
	for move in selected_moves:
		if move["to"] == square:
			_clear_selection()
			await _execute_move(move, true)
			return
	_clear_selection()

func _select(square: StringName) -> void:
	selected_square = square
	selected_moves = state.legal_moves_from(square)
	arena.show_selection(selected_square, selected_moves)

func _clear_selection() -> void:
	selected_square = &""
	selected_moves.clear()
	arena.clear_selection()

func _execute_move(move: Dictionary, allow_ai_reply: bool) -> void:
	input_locked = true
	var from_square: StringName = move["from"]
	var to_square: StringName = move["to"]
	var attacker := arena.get_piece_at(from_square)
	var captured_square := state.captured_square_for(move)
	var victim := arena.get_piece_at(captured_square) if move.get("capture", false) else null
	if attacker == null:
		push_error("No visual piece at %s" % String(from_square))
		input_locked = false
		return

	var castle_kind: StringName = move.get("castle", &"")
	var original_type := attacker.piece_type
	if victim != null:
		await battle_director.play_board_capture(attacker, victim)
		arena.remove_piece(victim)

	state.make_move(move)
	if victim == null:
		await arena.animate_piece_move(attacker, to_square)
	else:
		arena.move_piece(attacker, to_square)
	if castle_kind != &"":
		_move_castle_rook(attacker.side, castle_kind)

	var resulting_piece := state.get_piece(to_square)
	if original_type == &"Pawn" and not resulting_piece.is_empty() and resulting_piece["type"] != &"Pawn":
		attacker.change_type(resulting_piece["type"])

	_refresh_hud()
	var status := state.get_game_status()
	if status == &"check":
		await arena.play_check_reaction(state.turn)
	elif status == &"checkmate":
		var winner_side := ChessState.BLACK if state.turn == ChessState.WHITE else ChessState.WHITE
		await arena.play_checkmate_presentation(winner_side, state.turn)
	input_locked = false
	if allow_ai_reply and ai_enabled and state.turn == ChessState.BLACK and status in [&"ongoing", &"check"]:
		input_locked = true
		await get_tree().create_timer(0.35).timeout
		var reply := ai.choose_move(state)
		input_locked = false
		if not reply.is_empty():
			await _execute_move(reply, false)

func _move_castle_rook(side: StringName, kind: StringName) -> void:
	var from_square: StringName
	var to_square: StringName
	if side == ChessState.WHITE:
		from_square = &"H1" if kind == &"king" else &"A1"
		to_square = &"F1" if kind == &"king" else &"D1"
	else:
		from_square = &"H8" if kind == &"king" else &"A8"
		to_square = &"F8" if kind == &"king" else &"D8"
	var rook := arena.get_piece_at(from_square)
	if rook != null:
		arena.move_piece(rook, to_square)

func _screen_to_square(screen_position: Vector2) -> StringName:
	var camera := arena.gameplay_camera
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	if absf(direction.y) < 0.0001:
		return &""
	var t := (ArenaBuilder.BOARD_Y + 0.08 - origin.y) / direction.y
	if t <= 0.0:
		return &""
	var p := origin + direction * t
	var half := ArenaBuilder.CELL_SIZE * 4.0
	if p.x < -half or p.x >= half or p.z < -half or p.z >= half:
		return &""
	var file_idx := int(floor((p.x + half) / ArenaBuilder.CELL_SIZE))
	var rank_idx := int(floor((half - p.z) / ArenaBuilder.CELL_SIZE))
	if file_idx < 0 or file_idx > 7 or rank_idx < 0 or rank_idx > 7:
		return &""
	return StringName("%s%d" % [String.chr(65 + file_idx), rank_idx + 1])

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	var panel := ColorRect.new()
	panel.color = Color(0.04, 0.035, 0.05, 0.82)
	panel.position = Vector2(18, 18)
	panel.size = Vector2(470, 86)
	hud.add_child(panel)
	status_label = Label.new()
	status_label.position = Vector2(18, 10)
	status_label.size = Vector2(430, 32)
	status_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(status_label)
	help_label = Label.new()
	help_label.position = Vector2(18, 44)
	help_label.size = Vector2(440, 32)
	help_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(help_label)

func restart_game() -> void:
	if input_locked or battle_director.busy:
		return
	state.reset()
	arena.reset_pieces()
	_clear_selection()
	_refresh_hud()

func _refresh_hud() -> void:
	if status_label == null:
		return
	if help_label != null:
		help_label.text = "ЛКМ: ход • 1–6: демо • R: новая игра • A: AI %s" % ("ON" if ai_enabled else "OFF")
	var status := state.get_game_status()
	var side_text := "Белые" if state.turn == ChessState.WHITE else "Чёрные"
	match status:
		&"check":
			status_label.text = "%s ходят — ШАХ" % side_text
		&"checkmate":
			var winner := "Чёрные" if state.turn == ChessState.WHITE else "Белые"
			status_label.text = "МАТ — победили %s" % winner
		&"stalemate":
			status_label.text = "ПАТ — ничья"
		&"draw_50_move":
			status_label.text = "Ничья — правило 50 ходов"
		&"draw_insufficient":
			status_label.text = "Ничья — недостаточно материала"
		_:
			status_label.text = "%s ходят" % side_text
