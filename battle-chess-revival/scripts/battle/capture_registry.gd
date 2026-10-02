class_name CaptureRegistry
extends RefCounted

var _items: Dictionary = {}

func _init() -> void:
	_add(&"pawn_toe_stab", &"Pawn", &"Pawn", 2.35, 0.72, &"BattleClose", &"remove")
	_add(&"knight_double_kick", &"Knight", &"Knight", 2.55, 0.94, &"BattleSide", &"remove")
	_add(&"bishop_ram", &"Bishop", &"Pawn", 2.35, 0.96, &"BattleWide", &"remove")
	_add(&"rook_crush", &"Rook", &"Pawn", 2.35, 1.24, &"BattleLow", &"remove")
	_add(&"queen_transform", &"Queen", &"Knight", 3.10, 1.55, &"BattleClose", &"duck")
	_add(&"king_trapdoor", &"King", &"Bishop", 2.65, 1.15, &"BattleClose", &"trapdoor")

func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key in _items.keys():
		out.append(key as StringName)
	out.sort()
	return out

func size() -> int:
	return _items.size()

func get_data(id: StringName) -> CaptureAnimationData:
	return _items.get(id) as CaptureAnimationData

func signature_for_attacker(attacker_type: StringName) -> StringName:
	match attacker_type:
		&"Pawn": return &"pawn_toe_stab"
		&"Knight": return &"knight_double_kick"
		&"Bishop": return &"bishop_ram"
		&"Rook": return &"rook_crush"
		&"Queen": return &"queen_transform"
		&"King": return &"king_trapdoor"
	return &""

func _add(
	id: StringName,
	attacker: StringName,
	victim: StringName,
	duration: float,
	impact_time: float,
	camera_profile: StringName,
	result_kind: StringName
) -> void:
	var data := CaptureAnimationData.new()
	data.id = id
	data.attacker_type = attacker
	data.victim_type = victim
	data.duration = duration
	data.impact_time = impact_time
	data.camera_profile = camera_profile
	data.result_kind = result_kind
	_items[id] = data
