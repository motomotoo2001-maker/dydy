class_name CaptureAnimationData
extends Resource

@export var id: StringName
@export var attacker_type: StringName
@export var victim_type: StringName
@export var duration: float = 2.0
@export var impact_time: float = 0.8
@export var camera_profile: StringName = &"BattleClose"
@export var result_kind: StringName = &"remove"
@export var replacement_scene: PackedScene
