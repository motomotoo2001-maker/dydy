class_name AudioDirector
extends Node

const AUDIO_PATHS := {
	&"ambient": "res://assets/audio/cathedral_ambience.wav",
	&"select": "res://assets/audio/ui_select.wav",
	&"move": "res://assets/audio/move.wav",
	&"check": "res://assets/audio/check.wav",
	&"checkmate": "res://assets/audio/checkmate.wav",
	&"pawn": "res://assets/audio/impact_pawn.wav",
	&"knight": "res://assets/audio/impact_knight.wav",
	&"bishop": "res://assets/audio/impact_bishop.wav",
	&"rook": "res://assets/audio/impact_rook.wav",
	&"queen": "res://assets/audio/impact_queen.wav",
	&"king": "res://assets/audio/impact_king.wav",
}

const CAPTURE_SOUND := {
	&"pawn_toe_stab": &"pawn",
	&"knight_double_kick": &"knight",
	&"bishop_ram": &"bishop",
	&"rook_crush": &"rook",
	&"queen_transform": &"queen",
	&"king_trapdoor": &"king",
}

var ambience_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cursor := 0

func prepare() -> void:
	_ensure_bus(&"Ambience", -8.0)
	_ensure_bus(&"SFX", -2.5)
	if ambience_player == null:
		ambience_player = AudioStreamPlayer.new()
		ambience_player.name = "CathedralAmbience"
		ambience_player.bus = &"Ambience"
		ambience_player.volume_db = -5.0
		ambience_player.finished.connect(_restart_ambience)
		add_child(ambience_player)
	if _sfx_players.is_empty():
		for i in range(8):
			var player := AudioStreamPlayer.new()
			player.name = "SFX_%02d" % i
			player.bus = &"SFX"
			add_child(player)
			_sfx_players.append(player)
	_start_ambience()

func bind(controller: ChessController, battle: BattleDirector) -> void:
	if controller != null:
		if not controller.piece_selected.is_connected(_on_piece_selected):
			controller.piece_selected.connect(_on_piece_selected)
		if not controller.move_committed.is_connected(_on_move_committed):
			controller.move_committed.connect(_on_move_committed)
		if not controller.game_status_changed.is_connected(_on_game_status_changed):
			controller.game_status_changed.connect(_on_game_status_changed)
		if not controller.game_restarted.is_connected(_on_game_restarted):
			controller.game_restarted.connect(_on_game_restarted)
	if battle != null and not battle.capture_impact.is_connected(_on_capture_impact):
		battle.capture_impact.connect(_on_capture_impact)

func asset_count() -> int:
	var count := 0
	for key in AUDIO_PATHS:
		if ResourceLoader.exists(AUDIO_PATHS[key]):
			count += 1
	return count

func has_asset(key: StringName) -> bool:
	return AUDIO_PATHS.has(key) and ResourceLoader.exists(AUDIO_PATHS[key])

func capture_sound_key(id: StringName) -> StringName:
	return CAPTURE_SOUND.get(id, &"")

func _ensure_bus(bus_name: StringName, default_db: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, &"Master")
		AudioServer.set_bus_volume_db(index, default_db)

func _start_ambience() -> void:
	if ambience_player == null or not has_asset(&"ambient"):
		return
	if ambience_player.stream == null:
		ambience_player.stream = load(AUDIO_PATHS[&"ambient"])
	if not ambience_player.playing:
		ambience_player.play()

func _restart_ambience() -> void:
	if ambience_player != null and ambience_player.stream != null:
		ambience_player.play()

func _play_key(key: StringName, volume_db: float = 0.0, pitch: float = 1.0) -> bool:
	if not has_asset(key) or _sfx_players.is_empty():
		return false
	var chosen: AudioStreamPlayer = null
	for player in _sfx_players:
		if not player.playing:
			chosen = player
			break
	if chosen == null:
		chosen = _sfx_players[_sfx_cursor % _sfx_players.size()]
		_sfx_cursor += 1
		chosen.stop()
	chosen.stream = load(AUDIO_PATHS[key])
	chosen.volume_db = volume_db
	chosen.pitch_scale = pitch
	chosen.play()
	return true

func _on_piece_selected(_piece_type: StringName) -> void:
	_play_key(&"select", -6.0, 1.0)

func _on_move_committed(_piece_type: StringName, capture: bool) -> void:
	if not capture:
		_play_key(&"move", -4.5, 1.0)

func _on_game_status_changed(status: StringName) -> void:
	if status == &"check":
		_play_key(&"check", -2.0, 1.0)
	elif status == &"checkmate":
		_play_key(&"checkmate", 0.0, 1.0)

func _on_game_restarted() -> void:
	_play_key(&"select", -8.0, 0.82)

func _on_capture_impact(id: StringName) -> void:
	var key := capture_sound_key(id)
	if key == &"":
		return
	var pitch := 1.0
	match key:
		&"pawn": pitch = 1.10
		&"knight": pitch = 0.94
		&"bishop": pitch = 1.02
		&"rook": pitch = 0.84
		&"queen": pitch = 1.08
		&"king": pitch = 0.80
	_play_key(key, 1.0, pitch)
