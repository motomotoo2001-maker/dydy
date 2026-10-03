extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("AI_STRATEGY_FAIL: " + message)
	quit(2)

func _run() -> void:
	var ai := ChessAI.new()

	# Difficulty contract.
	ai.set_difficulty(ChessAI.Difficulty.EASY)
	if ai.search_depth() != 1:
		_fail("easy depth is not 1")
		return
	ai.set_difficulty(ChessAI.Difficulty.NORMAL)
	if ai.search_depth() != 2:
		_fail("normal depth is not 2")
		return
	ai.set_difficulty(ChessAI.Difficulty.HARD)
	if ai.search_depth() != 3:
		_fail("hard depth is not 3")
		return

	# Deterministic legal move from the initial position. Normal difficulty is
	# used here so CI validates determinism without turning the opening test into
	# a performance benchmark.
	ai.set_difficulty(ChessAI.Difficulty.NORMAL)
	var initial := ChessState.new()
	initial.turn = ChessState.BLACK
	var first := ai.choose_move(initial)
	var second := ai.choose_move(initial)
	if first.is_empty() or second.is_empty():
		_fail("AI returned no opening move")
		return
	if first != second:
		_fail("AI is not deterministic")
		return
	var legal := false
	for move in initial.all_legal_moves():
		if move == first:
			legal = true
			break
	if not legal:
		_fail("AI returned an illegal opening move")
		return

	# Black has Qg2# in one: Kg3, Qh3 vs Kg1.
	var mate := ChessState.new(false)
	mate.board = {
		&"G1": {"side": ChessState.WHITE, "type": &"King", "has_moved": true},
		&"G3": {"side": ChessState.BLACK, "type": &"King", "has_moved": true},
		&"H3": {"side": ChessState.BLACK, "type": &"Queen", "has_moved": true},
	}
	mate.turn = ChessState.BLACK
	mate.castling_rights = {"K": false, "Q": false, "k": false, "q": false}
	mate.en_passant_square = &""
	mate.halfmove_clock = 0
	mate.fullmove_number = 20

	ai.set_difficulty(ChessAI.Difficulty.HARD)
	var mating_move := ai.choose_move(mate)
	if mating_move.is_empty():
		_fail("AI missed available move in mate position")
		return
	if mating_move.get("from", &"") != &"H3" or mating_move.get("to", &"") != &"G2":
		_fail("AI missed Qg2#; chose %s-%s" % [mating_move.get("from", &""), mating_move.get("to", &"")])
		return
	var after := mate.preview_move(mating_move)
	if after.get_game_status() != &"checkmate":
		_fail("selected tactical move is not checkmate")
		return

	print("AI_STRATEGY_PASS opening=", first, " mate=", mating_move, " nodes=", ai.nodes_searched)
	quit(0)
