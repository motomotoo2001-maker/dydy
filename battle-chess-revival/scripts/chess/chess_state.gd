class_name ChessState
extends RefCounted

const WHITE: StringName = &"White"
const BLACK: StringName = &"Black"

var board: Dictionary = {}
var turn: StringName = WHITE
var castling_rights := {"K": true, "Q": true, "k": true, "q": true}
var en_passant_square: StringName = &""
var halfmove_clock := 0
var fullmove_number := 1
var position_history: Array[String] = []

func _init(setup_position: bool = true) -> void:
	if setup_position:
		reset()

func reset() -> void:
	board.clear()
	turn = WHITE
	castling_rights = {"K": true, "Q": true, "k": true, "q": true}
	en_passant_square = &""
	halfmove_clock = 0
	fullmove_number = 1
	var back: Array[StringName] = [&"Rook", &"Knight", &"Bishop", &"Queen", &"King", &"Bishop", &"Knight", &"Rook"]
	for file_idx in range(8):
		var file := String.chr(65 + file_idx)
		board[StringName("%s1" % file)] = _piece(WHITE, back[file_idx])
		board[StringName("%s2" % file)] = _piece(WHITE, &"Pawn")
		board[StringName("%s7" % file)] = _piece(BLACK, &"Pawn")
		board[StringName("%s8" % file)] = _piece(BLACK, back[file_idx])
	position_history.clear()
	position_history.append(_position_key())

func clone() -> ChessState:
	var copy := ChessState.new(false)
	copy.board = board.duplicate(true)
	copy.turn = turn
	copy.castling_rights = castling_rights.duplicate(true)
	copy.en_passant_square = en_passant_square
	copy.halfmove_clock = halfmove_clock
	copy.fullmove_number = fullmove_number
	copy.position_history = position_history.duplicate()
	return copy

func preview_move(move: Dictionary) -> ChessState:
	var copy := clone()
	copy._apply_move_unchecked(move)
	return copy

func get_piece(square: StringName) -> Dictionary:
	return board[square] if board.has(square) else {}

func has_piece(square: StringName) -> bool:
	return board.has(square)

func find_legal_move(from_square: StringName, to_square: StringName) -> Dictionary:
	for move in legal_moves_from(from_square):
		if move["to"] == to_square:
			return move
	return {}

func try_move(from_square: StringName, to_square: StringName) -> bool:
	var move := find_legal_move(from_square, to_square)
	if move.is_empty():
		return false
	make_move(move)
	return true

func make_move(move: Dictionary) -> void:
	_apply_move_unchecked(move)

func legal_moves_from(square: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var piece := get_piece(square)
	if piece.is_empty() or piece["side"] != turn:
		return result
	for move in _pseudo_moves(square, piece, true):
		if not _would_leave_king_in_check(move, piece["side"]):
			result.append(move)
	return result

func all_legal_moves(side: StringName = &"") -> Array[Dictionary]:
	var wanted := turn if side == &"" else side
	var result: Array[Dictionary] = []
	for square in board.keys():
		var piece: Dictionary = board[square]
		if piece["side"] != wanted:
			continue
		for move in _pseudo_moves(square, piece, true):
			if not _would_leave_king_in_check(move, wanted):
				result.append(move)
	return result

func is_in_check(side: StringName) -> bool:
	var king_square := _find_king(side)
	return king_square != &"" and is_square_attacked(king_square, _opposite(side))

func get_king_square(side: StringName) -> StringName:
	return _find_king(side)

func is_square_attacked(square: StringName, by_side: StringName) -> bool:
	var target := square_to_coord(square)
	var pawn_source_dy := -1 if by_side == WHITE else 1
	for dx in [-1, 1]:
		var src := target + Vector2i(dx, pawn_source_dy)
		if _inside(src):
			var p := get_piece(coord_to_square(src))
			if not p.is_empty() and p["side"] == by_side and p["type"] == &"Pawn":
				return true

	for offset in [Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2), Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)]:
		var src: Vector2i = target + offset
		if _inside(src):
			var p := get_piece(coord_to_square(src))
			if not p.is_empty() and p["side"] == by_side and p["type"] == &"Knight":
				return true

	if _ray_attacked(target, by_side, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)], [&"Rook", &"Queen"]):
		return true
	if _ray_attacked(target, by_side, [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)], [&"Bishop", &"Queen"]):
		return true

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var src := target + Vector2i(dx, dy)
			if _inside(src):
				var p := get_piece(coord_to_square(src))
				if not p.is_empty() and p["side"] == by_side and p["type"] == &"King":
					return true
	return false

func get_game_status() -> StringName:
	var moves := all_legal_moves(turn)
	if moves.is_empty():
		return &"checkmate" if is_in_check(turn) else &"stalemate"
	if is_in_check(turn):
		return &"check"
	if halfmove_clock >= 100:
		return &"draw_50_move"
	if _repetition_count() >= 3:
		return &"draw_repetition"
	if _insufficient_material():
		return &"draw_insufficient"
	return &"ongoing"

func square_to_coord(square: StringName) -> Vector2i:
	var s := String(square)
	if s.length() < 2:
		return Vector2i(-1, -1)
	return Vector2i(s.unicode_at(0) - 65, int(s.substr(1)) - 1)

func coord_to_square(coord: Vector2i) -> StringName:
	if not _inside(coord):
		return &""
	return StringName("%s%d" % [String.chr(65 + coord.x), coord.y + 1])

func captured_square_for(move: Dictionary) -> StringName:
	return move["captured_square"] if move.has("captured_square") else move["to"]

func _piece(side: StringName, type: StringName) -> Dictionary:
	return {"side": side, "type": type, "has_moved": false}

func _pseudo_moves(square: StringName, piece: Dictionary, include_castling: bool) -> Array[Dictionary]:
	match piece["type"]:
		&"Pawn":
			return _pawn_moves(square, piece)
		&"Knight":
			return _jump_moves(square, piece, [Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2), Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)])
		&"Bishop":
			return _slide_moves(square, piece, [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)])
		&"Rook":
			return _slide_moves(square, piece, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)])
		&"Queen":
			return _slide_moves(square, piece, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)])
		&"King":
			var result := _jump_moves(square, piece, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)])
			if include_castling:
				result.append_array(_castle_moves(square, piece))
			return result
	return []

func _pawn_moves(square: StringName, piece: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var from := square_to_coord(square)
	var side: StringName = piece["side"]
	var dir := 1 if side == WHITE else -1
	var start_rank := 1 if side == WHITE else 6
	var promotion_rank := 7 if side == WHITE else 0
	var one := from + Vector2i(0, dir)
	if _inside(one) and not board.has(coord_to_square(one)):
		var move := _move(square, coord_to_square(one))
		if one.y == promotion_rank:
			_append_promotion_variants(result, move)
		else:
			result.append(move)
		var two := from + Vector2i(0, dir * 2)
		if from.y == start_rank and not board.has(coord_to_square(two)):
			result.append(_move(square, coord_to_square(two)))

	for dx in [-1, 1]:
		var target := from + Vector2i(dx, dir)
		if not _inside(target):
			continue
		var target_square := coord_to_square(target)
		var occupant := get_piece(target_square)
		if not occupant.is_empty() and occupant["side"] != side and occupant["type"] != &"King":
			var capture := _move(square, target_square)
			capture["capture"] = true
			if target.y == promotion_rank:
				_append_promotion_variants(result, capture)
			else:
				result.append(capture)
		elif target_square == en_passant_square:
			var captured_square := coord_to_square(from + Vector2i(dx, 0))
			var captured_piece := get_piece(captured_square)
			if not captured_piece.is_empty() and captured_piece["side"] != side and captured_piece["type"] == &"Pawn":
				var ep := _move(square, target_square)
				ep["capture"] = true
				ep["en_passant"] = true
				ep["captured_square"] = captured_square
				result.append(ep)
	return result

func _append_promotion_variants(result: Array[Dictionary], base_move: Dictionary) -> void:
	# Queen remains first to preserve the old find_legal_move()/AI default when
	# no explicit promotion choice is requested.
	for promotion_type in [&"Queen", &"Rook", &"Bishop", &"Knight"]:
		var promoted := base_move.duplicate(true)
		promoted["promotion"] = promotion_type
		result.append(promoted)


func _jump_moves(square: StringName, piece: Dictionary, offsets: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var from := square_to_coord(square)
	for offset in offsets:
		var target: Vector2i = from + offset
		if not _inside(target):
			continue
		var target_square := coord_to_square(target)
		var occupant := get_piece(target_square)
		if occupant.is_empty():
			result.append(_move(square, target_square))
		elif occupant["side"] != piece["side"] and occupant["type"] != &"King":
			var capture := _move(square, target_square)
			capture["capture"] = true
			result.append(capture)
	return result

func _slide_moves(square: StringName, piece: Dictionary, directions: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var from := square_to_coord(square)
	for direction in directions:
		var target: Vector2i = from + direction
		while _inside(target):
			var target_square := coord_to_square(target)
			var occupant := get_piece(target_square)
			if occupant.is_empty():
				result.append(_move(square, target_square))
			else:
				if occupant["side"] != piece["side"] and occupant["type"] != &"King":
					var capture := _move(square, target_square)
					capture["capture"] = true
					result.append(capture)
				break
			target += direction
	return result

func _castle_moves(square: StringName, piece: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var side: StringName = piece["side"]
	if is_in_check(side):
		return result
	if side == WHITE and square == &"E1":
		if castling_rights["K"] and _can_castle(&"H1", [&"F1", &"G1"], [&"F1", &"G1"], BLACK):
			var move := _move(&"E1", &"G1")
			move["castle"] = &"king"
			result.append(move)
		if castling_rights["Q"] and _can_castle(&"A1", [&"D1", &"C1", &"B1"], [&"D1", &"C1"], BLACK):
			var move := _move(&"E1", &"C1")
			move["castle"] = &"queen"
			result.append(move)
	elif side == BLACK and square == &"E8":
		if castling_rights["k"] and _can_castle(&"H8", [&"F8", &"G8"], [&"F8", &"G8"], WHITE):
			var move := _move(&"E8", &"G8")
			move["castle"] = &"king"
			result.append(move)
		if castling_rights["q"] and _can_castle(&"A8", [&"D8", &"C8", &"B8"], [&"D8", &"C8"], WHITE):
			var move := _move(&"E8", &"C8")
			move["castle"] = &"queen"
			result.append(move)
	return result

func _can_castle(rook_square: StringName, empty_squares: Array, safe_squares: Array, enemy: StringName) -> bool:
	var rook := get_piece(rook_square)
	if rook.is_empty() or rook["type"] != &"Rook" or rook.get("side", &"") == enemy:
		return false
	for square in empty_squares:
		if board.has(square):
			return false
	for square in safe_squares:
		if is_square_attacked(square, enemy):
			return false
	return true

func _move(from_square: StringName, to_square: StringName) -> Dictionary:
	return {"from": from_square, "to": to_square, "capture": false}

func _would_leave_king_in_check(move: Dictionary, side: StringName) -> bool:
	var copy := clone()
	copy._apply_move_unchecked(move)
	return copy.is_in_check(side)

func _apply_move_unchecked(move: Dictionary) -> void:
	var from_square: StringName = move["from"]
	var to_square: StringName = move["to"]
	if not board.has(from_square):
		return
	var moving: Dictionary = board[from_square].duplicate(true)
	var original_type: StringName = moving["type"]
	var moving_side: StringName = moving["side"]
	var captured_square := captured_square_for(move)
	var captured: Dictionary = get_piece(captured_square).duplicate(true) if board.has(captured_square) else {}
	_update_castling_rights(from_square, moving, captured_square, captured)
	if move.get("capture", false):
		board.erase(captured_square)
	board.erase(from_square)
	moving["has_moved"] = true
	if move.has("promotion"):
		moving["type"] = move["promotion"]
	board[to_square] = moving
	if move.has("castle"):
		_apply_castle_rook(moving_side, move["castle"])
	en_passant_square = &""
	if original_type == &"Pawn":
		var a := square_to_coord(from_square)
		var b := square_to_coord(to_square)
		if abs(b.y - a.y) == 2:
			en_passant_square = coord_to_square(Vector2i(a.x, int((a.y + b.y) / 2)))
	if original_type == &"Pawn" or not captured.is_empty():
		halfmove_clock = 0
	else:
		halfmove_clock += 1
	if moving_side == BLACK:
		fullmove_number += 1
	turn = _opposite(turn)
	position_history.append(_position_key())

func _apply_castle_rook(side: StringName, kind: StringName) -> void:
	var rook_from: StringName
	var rook_to: StringName
	if side == WHITE:
		rook_from = &"H1" if kind == &"king" else &"A1"
		rook_to = &"F1" if kind == &"king" else &"D1"
	else:
		rook_from = &"H8" if kind == &"king" else &"A8"
		rook_to = &"F8" if kind == &"king" else &"D8"
	if board.has(rook_from):
		var rook: Dictionary = board[rook_from].duplicate(true)
		rook["has_moved"] = true
		board.erase(rook_from)
		board[rook_to] = rook

func _update_castling_rights(from_square: StringName, moving: Dictionary, captured_square: StringName, captured: Dictionary) -> void:
	if moving["type"] == &"King":
		if moving["side"] == WHITE:
			castling_rights["K"] = false
			castling_rights["Q"] = false
		else:
			castling_rights["k"] = false
			castling_rights["q"] = false
	if moving["type"] == &"Rook":
		_disable_rook_right(from_square)
	if not captured.is_empty() and captured["type"] == &"Rook":
		_disable_rook_right(captured_square)

func _disable_rook_right(square: StringName) -> void:
	match square:
		&"H1": castling_rights["K"] = false
		&"A1": castling_rights["Q"] = false
		&"H8": castling_rights["k"] = false
		&"A8": castling_rights["q"] = false

func _ray_attacked(target: Vector2i, by_side: StringName, directions: Array, attackers: Array) -> bool:
	for direction in directions:
		var cursor: Vector2i = target + direction
		while _inside(cursor):
			var p := get_piece(coord_to_square(cursor))
			if not p.is_empty():
				if p["side"] == by_side and p["type"] in attackers:
					return true
				break
			cursor += direction
	return false

func _find_king(side: StringName) -> StringName:
	for square in board.keys():
		var p: Dictionary = board[square]
		if p["side"] == side and p["type"] == &"King":
			return square
	return &""

func _inside(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < 8 and coord.y >= 0 and coord.y < 8

func _opposite(side: StringName) -> StringName:
	return BLACK if side == WHITE else WHITE

func _repetition_count() -> int:
	var key := _position_key()
	var count := 0
	for historic in position_history:
		if historic == key:
			count += 1
	return count


func _position_key() -> String:
	var squares: Array = board.keys()
	squares.sort()
	var parts: Array[String] = []
	for square_variant in squares:
		var square: StringName = square_variant
		var piece: Dictionary = board[square]
		parts.append("%s:%s:%s" % [
			String(square),
			String(piece.get("side", &"")),
			String(piece.get("type", &""))
		])
	var castle := ""
	for right in ["K", "Q", "k", "q"]:
		if castling_rights.get(right, false):
			castle += right
	if castle.is_empty():
		castle = "-"
	return "%s|%s|%s|%s" % [
		String(turn),
		castle,
		String(en_passant_square) if en_passant_square != &"" else "-",
		";".join(parts)
	]


func _insufficient_material() -> bool:
	var minors: Array[Dictionary] = []
	for square in board.keys():
		var p: Dictionary = board[square]
		var type: StringName = p.get("type", &"")
		if type == &"King":
			continue
		if type in [&"Pawn", &"Rook", &"Queen"]:
			return false
		minors.append({"type": type, "square": square})

	if minors.is_empty():
		return true
	if minors.size() == 1 and minors[0]["type"] in [&"Bishop", &"Knight"]:
		return true

	# Any number of bishops confined to the same square colour cannot create a
	# mating net without pawns/rooks/queens/knights.
	var all_bishops := true
	var bishop_color := -1
	for item in minors:
		if item["type"] != &"Bishop":
			all_bishops = false
			break
		var coord := square_to_coord(item["square"])
		var color := (coord.x + coord.y) & 1
		if bishop_color < 0:
			bishop_color = color
		elif bishop_color != color:
			return false
	return all_bishops

