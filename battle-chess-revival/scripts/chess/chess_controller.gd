class_name ChessController
extends Node

signal piece_selected(piece_type: StringName)
signal move_committed(piece_type: StringName, capture: bool)
signal game_status_changed(status: StringName)
signal game_restarted

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
var side_chip: Label
var state_badge: Label
var alert_panel: PanelContainer
var alert_label: Label
var pause_overlay: Control
var volume_slider: HSlider
var ambience_slider: HSlider
var sfx_slider: HSlider
var hud_layer: CanvasLayer

func setup(p_arena: ArenaBuilder, p_battle_director: BattleDirector) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	arena = p_arena
	battle_director = p_battle_director
	_build_hud()
	_refresh_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause()
			get_viewport().set_input_as_handled()
			return

	if get_tree().paused:
		return
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
	var selected_piece := state.get_piece(square)
	if not selected_piece.is_empty():
		piece_selected.emit(selected_piece.get("type", &""))

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

	move_committed.emit(original_type, victim != null)
	_refresh_hud()
	var status := state.get_game_status()
	game_status_changed.emit(status)
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
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	hud_layer.layer = 20
	hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud_layer)

	# Compact turn card: small footprint, high contrast, production styling.
	var turn_panel := PanelContainer.new()
	turn_panel.name = "TurnPanel"
	turn_panel.position = Vector2(20, 18)
	turn_panel.size = Vector2(342, 76)
	turn_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.045, 0.05, 0.92), Color(0.64, 0.45, 0.20, 0.90), 12, 1))
	hud_layer.add_child(turn_panel)

	var turn_margin := MarginContainer.new()
	turn_margin.add_theme_constant_override("margin_left", 14)
	turn_margin.add_theme_constant_override("margin_right", 14)
	turn_margin.add_theme_constant_override("margin_top", 10)
	turn_margin.add_theme_constant_override("margin_bottom", 9)
	turn_panel.add_child(turn_margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	turn_margin.add_child(row)

	side_chip = Label.new()
	side_chip.name = "SideChip"
	side_chip.custom_minimum_size = Vector2(48, 48)
	side_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	side_chip.add_theme_font_size_override("font_size", 26)
	side_chip.add_theme_color_override("font_color", Color("#241d1b"))
	side_chip.add_theme_stylebox_override("normal", _panel_style(Color("#e9dfce"), Color("#c3974c"), 10, 1))
	row.add_child(side_chip)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 1)
	row.add_child(text_column)

	status_label = Label.new()
	status_label.name = "TurnStatus"
	status_label.add_theme_font_size_override("font_size", 19)
	status_label.add_theme_color_override("font_color", Color("#fff2dc"))
	text_column.add_child(status_label)

	state_badge = Label.new()
	state_badge.name = "StateBadge"
	state_badge.add_theme_font_size_override("font_size", 11)
	state_badge.add_theme_color_override("font_color", Color("#c8b69d"))
	text_column.add_child(state_badge)

	# Help is detached from the turn card so the board stays visible.
	var hint_panel := PanelContainer.new()
	hint_panel.name = "HintPanel"
	hint_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_panel.position = Vector2(-360, -58)
	hint_panel.size = Vector2(340, 38)
	hint_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.03, 0.04, 0.74), Color(0.38, 0.31, 0.25, 0.72), 9, 1))
	hud_layer.add_child(hint_panel)
	help_label = Label.new()
	help_label.name = "HelpLabel"
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	help_label.add_theme_font_size_override("font_size", 11)
	help_label.add_theme_color_override("font_color", Color("#dbcdb9"))
	hint_panel.add_child(help_label)

	# Check / mate presentation.
	alert_panel = PanelContainer.new()
	alert_panel.name = "AlertPanel"
	alert_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	alert_panel.position = Vector2(-145, 116)
	alert_panel.size = Vector2(290, 54)
	alert_panel.visible = false
	alert_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.26, 0.035, 0.035, 0.94), Color("#e5aa4e"), 12, 2))
	hud_layer.add_child(alert_panel)
	alert_label = Label.new()
	alert_label.name = "AlertLabel"
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_size_override("font_size", 23)
	alert_label.add_theme_color_override("font_color", Color("#fff0cf"))
	alert_panel.add_child(alert_label)

	_build_pause_overlay()


func _build_pause_overlay() -> void:
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	hud_layer.add_child(pause_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.012, 0.018, 0.74)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.add_child(dim)

	var card := PanelContainer.new()
	card.name = "SettingsCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-205, -220)
	card.size = Vector2(410, 440)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.055, 0.065, 0.98), Color("#b7833e"), 16, 2))
	pause_overlay.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title := Label.new()
	title.text = "BATTLE CHESS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#f4ddaf"))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "ПАУЗА • НАСТРОЙКИ"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#9e8b77"))
	column.add_child(subtitle)

	var separator := HSeparator.new()
	column.add_child(separator)

	volume_slider = _add_volume_slider(column, "Общая громкость", &"Master", "MasterVolume")
	ambience_slider = _add_volume_slider(column, "Окружение", &"Ambience", "AmbienceVolume")
	sfx_slider = _add_volume_slider(column, "Эффекты", &"SFX", "SFXVolume")

	var resume := Button.new()
	resume.name = "ResumeButton"
	resume.text = "ПРОДОЛЖИТЬ"
	resume.custom_minimum_size.y = 42
	resume.pressed.connect(_toggle_pause)
	column.add_child(resume)

	var restart := Button.new()
	restart.name = "RestartButton"
	restart.text = "НОВАЯ ИГРА"
	restart.custom_minimum_size.y = 42
	restart.pressed.connect(_restart_from_pause)
	column.add_child(restart)

	var tip := Label.new()
	tip.text = "Esc — закрыть  •  R — новая игра  •  A — AI"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 11)
	tip.add_theme_color_override("font_color", Color("#9e8b77"))
	column.add_child(tip)


func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.36)
	style.shadow_size = 7
	return style


func _toggle_pause() -> void:
	if pause_overlay == null:
		return
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_overlay.visible = paused


func _restart_from_pause() -> void:
	get_tree().paused = false
	if pause_overlay != null:
		pause_overlay.visible = false
	restart_game()


func _add_volume_slider(column: VBoxContainer, title_text: String, bus_name: StringName, node_name: String) -> HSlider:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 13)
	column.add_child(title)

	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = _current_bus_volume_linear(bus_name)
	slider.value_changed.connect(_on_bus_volume_changed.bind(bus_name))
	column.add_child(slider)
	return slider


func _on_bus_volume_changed(value: float, bus_name: StringName) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.001)))
	AudioServer.set_bus_mute(bus, value <= 0.001)


func _current_bus_volume_linear(bus_name: StringName) -> float:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return 1.0
	if AudioServer.is_bus_mute(bus):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus)), 0.0, 1.0)


func restart_game() -> void:
	if input_locked or battle_director.busy:
		return
	state.reset()
	arena.reset_pieces()
	_clear_selection()
	_refresh_hud()
	game_restarted.emit()

func _refresh_hud() -> void:
	if status_label == null:
		return

	var status := state.get_game_status()
	var white_turn := state.turn == ChessState.WHITE
	var side_text := "Белые" if white_turn else "Чёрные"
	if side_chip != null:
		side_chip.text = "♙" if white_turn else "♟"
		side_chip.add_theme_color_override("font_color", Color("#241d1b") if white_turn else Color("#f4e8d7"))
		side_chip.add_theme_stylebox_override(
			"normal",
			_panel_style(
				Color("#e9dfce") if white_turn else Color("#28232b"),
				Color("#c3974c") if white_turn else Color("#8c6372"),
				10,
				1
			)
		)

	if help_label != null:
		help_label.text = "ЛКМ ход  •  Esc меню  •  R новая игра  •  A AI %s" % ("ON" if ai_enabled else "OFF")

	if state_badge != null:
		state_badge.text = "AI: %s   •   %s" % [("ON" if ai_enabled else "OFF"), _material_summary()]

	if alert_panel != null:
		alert_panel.visible = status in [&"check", &"checkmate"]
		if alert_label != null:
			alert_label.text = "ШАХ" if status == &"check" else "МАТ"

	match status:
		&"check":
			status_label.text = "%s ходят  •  ШАХ" % side_text
		&"checkmate":
			var winner := "Чёрные" if white_turn else "Белые"
			status_label.text = "Победа: %s" % winner
		&"stalemate":
			status_label.text = "ПАТ  •  ничья"
		&"draw_50_move":
			status_label.text = "НИЧЬЯ  •  50 ходов"
		&"draw_insufficient":
			status_label.text = "НИЧЬЯ  •  материал"
		_:
			status_label.text = "%s ходят" % side_text


func _material_summary() -> String:
	var white_count := 0
	var black_count := 0
	for square in state.board.keys():
		var piece: Dictionary = state.board[square]
		if piece.is_empty():
			continue
		if piece.get("side", &"") == ChessState.WHITE:
			white_count += 1
		elif piece.get("side", &"") == ChessState.BLACK:
			black_count += 1
	return "%d : %d" % [white_count, black_count]

