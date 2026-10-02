extends Node3D

@onready var arena = $ArenaBuilder
@onready var battle_director = $BattleDirector
@onready var chess_controller = $ChessController

const DEMO_KEYS := {
	KEY_1: &"pawn_toe_stab",
	KEY_2: &"knight_double_kick",
	KEY_3: &"bishop_ram",
	KEY_4: &"rook_crush",
	KEY_5: &"queen_transform",
	KEY_6: &"king_trapdoor",
}

func _ready() -> void:
	arena.build()
	battle_director.setup(arena)
	chess_controller.setup(arena, battle_director)
	print("Battle Chess Revival ready. Press 1-6 for capture demos.")

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	if DEMO_KEYS.has(event.keycode) and not battle_director.busy:
		battle_director.play_signature(DEMO_KEYS[event.keycode])
