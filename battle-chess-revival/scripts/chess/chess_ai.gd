class_name ChessAI
extends RefCounted

enum Difficulty {
	EASY,
	NORMAL,
	HARD,
}

const PIECE_VALUES := {
	&"Pawn": 100.0,
	&"Knight": 320.0,
	&"Bishop": 335.0,
	&"Rook": 500.0,
	&"Queen": 900.0,
	&"King": 20000.0,
}
const MATE_SCORE := 100000.0
const INF := 1000000.0

var difficulty := Difficulty.NORMAL
var nodes_searched := 0

func set_difficulty(value: int) -> void:
	difficulty = clampi(value, Difficulty.EASY, Difficulty.HARD)

func difficulty_label() -> String:
	match difficulty:
		Difficulty.EASY:
			return "Лёгкий"
		Difficulty.HARD:
			return "Сложный"
		_:
			return "Обычный"

func search_depth() -> int:
	match difficulty:
		Difficulty.EASY:
			return 1
		Difficulty.HARD:
			return 3
		_:
			return 2

func choose_move(state: ChessState) -> Dictionary:
	var moves := _ordered_moves(state)
	if moves.is_empty():
		return {}

	nodes_searched = 0
	var root_side: StringName = state.turn
	var depth := search_depth()
	var best_move: Dictionary = moves[0]
	var best_score := -INF
	var alpha := -INF
	var beta := INF

	for move in moves:
		var preview := state.preview_move(move)
		var score := _minimax(preview, depth - 1, alpha, beta, root_side, 1)
		# Keep deterministic ordering on exact ties.
		if score > best_score:
			best_score = score
			best_move = move
		alpha = maxf(alpha, best_score)

	return best_move

func _minimax(state: ChessState, depth: int, alpha_in: float, beta_in: float, root_side: StringName, ply: int) -> float:
	nodes_searched += 1
	var status := state.get_game_status()
	if status == &"checkmate":
		# Side to move has been mated.
		return (-MATE_SCORE + float(ply)) if state.turn == root_side else (MATE_SCORE - float(ply))
	if status in [&"stalemate", &"draw_50_move", &"draw_insufficient"]:
		return 0.0
	if depth <= 0:
		return _evaluate_position(state, root_side)

	var moves := _ordered_moves(state)
	if moves.is_empty():
		return _evaluate_position(state, root_side)

	var alpha := alpha_in
	var beta := beta_in
	if state.turn == root_side:
		var best := -INF
		for move in moves:
			var score := _minimax(state.preview_move(move), depth - 1, alpha, beta, root_side, ply + 1)
			best = maxf(best, score)
			alpha = maxf(alpha, best)
			if beta <= alpha:
				break
		return best

	var best := INF
	for move in moves:
		var score := _minimax(state.preview_move(move), depth - 1, alpha, beta, root_side, ply + 1)
		best = minf(best, score)
		beta = minf(beta, best)
		if beta <= alpha:
			break
	return best

func _evaluate_position(state: ChessState, root_side: StringName) -> float:
	var score := 0.0
	var root_bishops := 0
	var enemy_bishops := 0
	var enemy_side := ChessState.BLACK if root_side == ChessState.WHITE else ChessState.WHITE

	for square in state.board.keys():
		var piece: Dictionary = state.board[square]
		var side: StringName = piece.get("side", &"")
		var type: StringName = piece.get("type", &"")
		var sign := 1.0 if side == root_side else -1.0
		var value: float = float(PIECE_VALUES.get(type, 0.0))
		var coord := state.square_to_coord(square)
		score += sign * value
		score += sign * _positional_bonus(type, side, coord)
		if type == &"Bishop":
			if side == root_side:
				root_bishops += 1
			else:
				enemy_bishops += 1

	if root_bishops >= 2:
		score += 24.0
	if enemy_bishops >= 2:
		score -= 24.0

	if state.is_in_check(root_side):
		score -= 32.0
	if state.is_in_check(enemy_side):
		score += 32.0

	return score

func _positional_bonus(type: StringName, side: StringName, coord: Vector2i) -> float:
	var dx := absf(float(coord.x) - 3.5)
	var dy := absf(float(coord.y) - 3.5)
	var center := maxf(0.0, 3.5 - (dx + dy) * 0.5)
	match type:
		&"Pawn":
			var advance := float(coord.y) if side == ChessState.WHITE else float(7 - coord.y)
			var center_file := maxf(0.0, 2.5 - dx)
			return advance * 7.0 + center_file * 3.0
		&"Knight":
			return center * 11.0
		&"Bishop":
			return center * 7.0
		&"Rook":
			return center * 2.0
		&"Queen":
			return center * 2.5
		&"King":
			# Prefer the back/near-back ranks while major material is normally present.
			var home_distance := float(coord.y) if side == ChessState.WHITE else float(7 - coord.y)
			return -home_distance * 2.0
	return 0.0

func _ordered_moves(state: ChessState) -> Array[Dictionary]:
	var moves := state.all_legal_moves()
	moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa := _move_order_score(state, a)
		var sb := _move_order_score(state, b)
		if not is_equal_approx(sa, sb):
			return sa > sb
		return _move_key(a) < _move_key(b)
	)
	return moves

func _move_order_score(state: ChessState, move: Dictionary) -> float:
	var score := 0.0
	if move.get("capture", false):
		var captured := state.get_piece(state.captured_square_for(move))
		var attacker := state.get_piece(move["from"])
		if not captured.is_empty():
			score += float(PIECE_VALUES.get(captured.get("type", &""), 0.0)) * 10.0
		if not attacker.is_empty():
			score -= float(PIECE_VALUES.get(attacker.get("type", &""), 0.0))
	if move.has("promotion"):
		score += 9000.0
	if move.has("castle"):
		score += 180.0

	var preview := state.preview_move(move)
	var status := preview.get_game_status()
	if status == &"checkmate":
		score += MATE_SCORE
	elif status == &"check":
		score += 320.0

	var c := state.square_to_coord(move["to"])
	score += maxf(0.0, 3.5 - (absf(float(c.x) - 3.5) + absf(float(c.y) - 3.5)) * 0.5) * 4.0
	return score

func _move_key(move: Dictionary) -> String:
	return "%s-%s-%s" % [
		String(move.get("from", &"")),
		String(move.get("to", &"")),
		String(move.get("promotion", &"")),
	]
