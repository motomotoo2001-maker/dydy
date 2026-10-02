class_name ChessAI
extends RefCounted

const VALUES := {"Pawn": 1, "Knight": 3, "Bishop": 3, "Rook": 5, "Queen": 9, "King": 100}

func choose_move(state: ChessState) -> Dictionary:
	var moves := state.all_legal_moves()
	if moves.is_empty():
		return {}
	var best := moves[0]
	var best_score := -100000.0
	for move in moves:
		var score := _score_move(state, move)
		if score > best_score:
			best = move
			best_score = score
	return best

func _score_move(state: ChessState, move: Dictionary) -> float:
	var score := 0.0
	if move.get("capture", false):
		var captured := state.get_piece(state.captured_square_for(move))
		if not captured.is_empty():
			score += float(VALUES.get(String(captured["type"]), 0)) * 10.0
	if move.has("promotion"):
		score += 75.0
	var preview := state.preview_move(move)
	var status := preview.get_game_status()
	if status == &"checkmate":
		score += 10000.0
	elif status == &"check":
		score += 4.0
	var c := state.square_to_coord(move["to"])
	score += 1.5 - (absf(float(c.x) - 3.5) + absf(float(c.y) - 3.5)) * 0.12
	return score
