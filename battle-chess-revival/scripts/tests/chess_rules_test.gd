extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var state := ChessState.new()
	_check(state.all_legal_moves().size() == 20, "initial position has 20 legal moves")
	_check(state.try_move(&"E2", &"E4"), "e2-e4 legal")
	_check(state.turn == ChessState.BLACK, "turn changes to black")
	_check(state.try_move(&"A7", &"A6"), "a7-a6 legal")
	_check(state.try_move(&"E4", &"E5"), "e4-e5 legal")
	_check(state.try_move(&"D7", &"D5"), "d7-d5 legal")
	var ep := state.find_legal_move(&"E5", &"D6")
	_check(not ep.is_empty() and ep.get("en_passant", false), "en passant generated")
	state.make_move(ep)
	_check(not state.has_piece(&"D5") and state.has_piece(&"D6"), "en passant removes passed pawn")

	var castle := ChessState.new()
	_check(castle.try_move(&"E2", &"E4"), "castle setup e2-e4")
	_check(castle.try_move(&"E7", &"E5"), "castle setup e7-e5")
	_check(castle.try_move(&"G1", &"F3"), "castle setup g1-f3")
	_check(castle.try_move(&"B8", &"C6"), "castle setup b8-c6")
	_check(castle.try_move(&"F1", &"C4"), "castle setup f1-c4")
	_check(castle.try_move(&"G8", &"F6"), "castle setup g8-f6")
	var castle_move := castle.find_legal_move(&"E1", &"G1")
	_check(not castle_move.is_empty() and castle_move.get("castle", &"") == &"king", "white king-side castling generated")
	castle.make_move(castle_move)
	_check(castle.get_piece(&"G1").get("type", &"") == &"King", "king lands on g1")
	_check(castle.get_piece(&"F1").get("type", &"") == &"Rook", "rook lands on f1")

	var repetition := ChessState.new()
	for cycle in range(2):
		_check(repetition.try_move(&"G1", &"F3"), "repetition white knight out %d" % cycle)
		_check(repetition.try_move(&"G8", &"F6"), "repetition black knight out %d" % cycle)
		_check(repetition.try_move(&"F3", &"G1"), "repetition white knight home %d" % cycle)
		_check(repetition.try_move(&"F6", &"G8"), "repetition black knight home %d" % cycle)
	_check(repetition.get_game_status() == &"draw_repetition", "threefold repetition detected")

	var mate := ChessState.new()
	_check(mate.try_move(&"F2", &"F3"), "fool mate f2-f3")
	_check(mate.try_move(&"E7", &"E5"), "fool mate e7-e5")
	_check(mate.try_move(&"G2", &"G4"), "fool mate g2-g4")
	_check(mate.try_move(&"D8", &"H4"), "fool mate d8-h4")
	_check(mate.get_game_status() == &"checkmate", "fool's mate detected")
	_check(mate.turn == ChessState.WHITE, "white is checkmated")

	if failures == 0:
		print("CHESS_RULES_PASS")
		quit(0)
	else:
		print("CHESS_RULES_FAIL count=", failures)
		quit(1)
