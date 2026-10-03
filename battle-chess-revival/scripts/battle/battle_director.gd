class_name BattleDirector
extends Node3D

signal capture_started(id: StringName)
signal capture_impact(id: StringName)
signal capture_finished(id: StringName)

var busy := false
var time_scale := 1.0

var arena: ArenaBuilder
var registry := CaptureRegistry.new()
var _camera_rest_position := Vector3.ZERO
var _camera_rest_rotation := Vector3.ZERO

func setup(p_arena: ArenaBuilder) -> void:
	arena = p_arena

func signature_ids() -> Array[StringName]:
	return registry.ids()

func registry_size() -> int:
	return registry.size()

func play_signature(id: StringName) -> void:
	if busy or arena == null:
		return
	var data := registry.get_data(id)
	if data == null:
		push_warning("Unknown capture signature: %s" % String(id))
		return
	var attacker := arena.find_piece(&"White", data.attacker_type)
	var victim := arena.find_piece(&"Black", data.victim_type)
	if attacker == null or victim == null:
		push_error("Missing demo pieces for %s" % String(id))
		return
	await _run_capture(id, attacker, victim, true)

func play_board_capture(attacker: PieceView, victim: PieceView) -> void:
	if busy or arena == null or attacker == null or victim == null:
		return
	var id := registry.signature_for_attacker(attacker.piece_type)
	if id == &"":
		push_warning("No signature capture for attacker %s" % String(attacker.piece_type))
		return
	await _run_capture(id, attacker, victim, false)

func _run_capture(id: StringName, attacker: PieceView, victim: PieceView, restore_after: bool) -> void:
	var data := registry.get_data(id)
	if data == null:
		return

	busy = true
	capture_started.emit(id)

	var attacker_transform := attacker.global_transform
	var victim_transform := victim.global_transform

	arena.set_demo_focus(attacker, victim, true)
	attacker.reset_visual()
	victim.reset_visual()
	attacker.set_battle_animation_active(true)
	victim.set_battle_animation_active(true)

	var attacker_anchor := arena.battle_stage.get_node("AttackerAnchor") as Marker3D
	var victim_anchor := arena.battle_stage.get_node("VictimAnchor") as Marker3D
	var stage_center := (attacker_anchor.global_position + victim_anchor.global_position) * 0.5
	var separation := _capture_separation(id)
	attacker.global_position = stage_center + Vector3(-separation * 0.5, 0, 0)
	victim.global_position = stage_center + Vector3(separation * 0.5, 0, 0)
	attacker.look_at(victim.global_position, Vector3.UP)
	victim.look_at(attacker.global_position, Vector3.UP)

	arena.gameplay_camera.current = false
	arena.set_battle_lighting(true)
	_set_battle_camera(data.camera_profile)
	arena.battle_camera.current = true

	match id:
		&"pawn_toe_stab":
			await _pawn_toe_stab(attacker, victim, data)
		&"knight_double_kick":
			await _knight_double_kick(attacker, victim, data)
		&"bishop_ram":
			await _bishop_ram(attacker, victim, data)
		&"rook_crush":
			await _rook_crush(attacker, victim, data)
		&"queen_transform":
			await _queen_transform(attacker, victim, data)
		&"king_trapdoor":
			await _king_trapdoor(attacker, victim, data)

	if restore_after:
		attacker.global_transform = attacker_transform
		victim.global_transform = victim_transform
		attacker.reset_visual()
		victim.reset_visual()
		arena.set_demo_focus(attacker, victim, false)
	else:
		attacker.reset_visual()
		victim.reset_visual()
		for piece in arena.get_all_pieces():
			piece.visible = piece != victim

	attacker.set_battle_animation_active(false)
	victim.set_battle_animation_active(false)
	arena.battle_camera.current = false
	arena.set_battle_lighting(false)
	arena.gameplay_camera.current = true
	busy = false
	capture_finished.emit(id)

func _pawn_toe_stab(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	await _animate_part_prefix(attacker, "Spear", Vector3(0, 0, -24), Vector3.ZERO, 0.14)
	await _animate_part_prefix(attacker, "Concept_Plume", Vector3(0, 0, -12), Vector3.ZERO, 0.14)
	await _animate_part_prefix(attacker, "V3_Plume", Vector3(0, 0, -18), Vector3.ZERO, 0.14)
	await _animate_part_prefix(attacker, "Production_Plume", Vector3(0, 0, -18), Vector3.ZERO, 0.14)
	await _animate_part_prefix(attacker, "Shield", Vector3(0, -8, -12), Vector3.ZERO, 0.14)
	await _animate_part_prefix(attacker, "Knife", Vector3(0, 0, 32), Vector3.ZERO, 0.14)
	await _tween(attacker.visual_root, "position", Vector3(0, -0.10, 0), 0.18)
	await _animate_part_prefix(attacker, "Spear", Vector3(0, 0, 58), Vector3.ZERO, 0.08)
	await _animate_part_prefix(attacker, "Knife", Vector3(0, 0, -58), Vector3.ZERO, 0.08)
	await _parallel(attacker.visual_root, {
		"position": Vector3(0, -0.06, -0.48),
		"rotation_degrees:x": -12.0
	}, 0.11)

	_camera_punch(0.10)
	_impact_burst(victim.foot_target.global_position + Vector3(0.10, 0.28, 0.28), Color("#ffd35c"), 1.15)
	_flash(victim.foot_target.global_position, Color("#ffd35c"), 0.26)
	_comic_text("BAM!", victim.battle_target.global_position + Vector3(0, 0.65, 0), Color("#ffd84f"))
	victim.play_hit_pose()
	capture_impact.emit(data.id)
	await _parallel(victim.visual_root, {
		"scale": Vector3(1.18, 0.82, 1.18),
		"position": Vector3(0, 0.22, 0)
	}, 0.10)
	await _parallel(attacker.visual_root, {
		"position": Vector3(0, -0.02, -0.12),
		"rotation_degrees:x": 0.0
	}, 0.10)

	await _tween(victim.visual_root, "position", Vector3(0.10, 0.70, 0), 0.16)
	await _tween(victim.visual_root, "position", Vector3(-0.10, 0.12, 0), 0.14)
	await _tween(victim.visual_root, "position", Vector3(0.10, 0.82, 0), 0.16)
	await _tween(victim.visual_root, "position", Vector3(0, 5.8, 0), 0.28)

	await _tween(attacker.visual_root, "rotation_degrees:z", -10.0, 0.10)
	await _tween(attacker.visual_root, "rotation_degrees:z", 0.0, 0.10)
	await _wait(0.10)

func _knight_double_kick(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	if attacker.has_authored_animation(&"DoubleKick"):
		await _knight_double_kick_authored(attacker, victim, data)
		return
	await _knight_double_kick_fallback(attacker, victim, data)

func _knight_double_kick_authored(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	# The rig clip handles horse/rider mechanics. BattleDirector keeps spatial
	# staging, victim reaction, camera punch and impact VFX deterministic.
	await _tween(attacker.visual_root, "rotation_degrees:y", 180.0, 0.24)
	var playback_speed := 1.15
	var clip_length := attacker.authored_animation_length(&"DoubleKick") / playback_speed
	if clip_length <= 0.0:
		clip_length = 1.20
	attacker.play_authored_animation(&"DoubleKick", playback_speed, 0.05)

	# Rear-hoof contact is authored near frame 21 of the 36-frame clip.
	await _wait(clip_length * 0.57)
	_camera_punch(0.18)
	_impact_burst(victim.battle_target.global_position, Color("#ffcc72"), 1.20)
	_flash(victim.battle_target.global_position, Color("#fff0c2"), 0.30)
	_comic_text("KICK!", victim.battle_target.global_position + Vector3(0, 0.7, 0), Color("#ffb953"))
	victim.play_hit_pose()
	capture_impact.emit(data.id)
	# Brief hit-stop keeps both characters readable at contact and gives the
	# camera/VFX one beat before the victim is launched.
	await _wait(0.14)

	await _parallel(victim.visual_root, {
		"scale": Vector3(1.58, 0.64, 0.96),
		"position": Vector3(0.48, 0.20, 0),
		"rotation_degrees:y": 120.0
	}, 0.10)

	var fly := create_tween().set_parallel()
	fly.tween_property(victim.visual_root, "position", Vector3(4.3, 1.25, 0), _d(0.48))
	fly.tween_property(victim.visual_root, "rotation_degrees:y", 1080.0, _d(0.48))
	await fly.finished

	var remaining := maxf(clip_length * 0.43 - 0.58, 0.02)
	await _wait(remaining)
	attacker.stop_authored_animation()
	await _tween(attacker.visual_root, "rotation_degrees:y", 360.0, 0.26)
	await _tween(attacker.visual_root, "position", Vector3.ZERO, 0.12)
	await _wait(0.08)

func _knight_double_kick_fallback(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	await _tween(attacker.visual_root, "rotation_degrees:y", 180.0, 0.30)
	await _parallel(attacker.visual_root, {
		"position": Vector3(0, 0.20, 0),
		"rotation_degrees:x": -7.0
	}, 0.14)
	await _animate_part_prefix(attacker, "RiderTorso", Vector3(-12, 0, 0), Vector3.ZERO, 0.11)
	await _animate_part_prefix(attacker, "HorseHead", Vector3(12, 0, 0), Vector3.ZERO, 0.11)
	await _animate_part_prefix(attacker, "V3_RiderCape", Vector3(-10, 0, 0), Vector3.ZERO, 0.11)
	await _animate_part_prefix(attacker, "Leg_", Vector3(-38, 0, 0), Vector3.ZERO, 0.11)
	await _animate_part_prefix(attacker, "Hoof_", Vector3(-28, 0, 0), Vector3.ZERO, 0.11)

	_flash(victim.battle_target.global_position, Color("#f4d29a"), 0.18)
	await _animate_part_prefix(attacker, "Leg_", Vector3(62, 0, 0), Vector3.ZERO, 0.07)
	await _animate_part_prefix(attacker, "Hoof_", Vector3(48, 0, 0), Vector3.ZERO, 0.07)
	await _parallel(victim.visual_root, {
		"scale": Vector3(1.35, 0.75, 1.05),
		"position": Vector3(0.18, 0.08, 0)
	}, 0.08)

	_camera_punch(0.16)
	_impact_burst(victim.battle_target.global_position, Color("#ffcc72"), 1.15)
	_flash(victim.battle_target.global_position, Color("#fff0c2"), 0.28)
	_comic_text("KICK!", victim.battle_target.global_position + Vector3(0, 0.7, 0), Color("#ffb953"))
	victim.play_hit_pose()
	capture_impact.emit(data.id)
	await _animate_part_prefix(attacker, "Leg_", Vector3(-52, 0, 0), Vector3.ZERO, 0.065)
	await _animate_part_prefix(attacker, "Hoof_", Vector3(-40, 0, 0), Vector3.ZERO, 0.065)
	await _animate_part_prefix(attacker, "Leg_", Vector3(70, 0, 0), Vector3.ZERO, 0.065)
	await _animate_part_prefix(attacker, "Hoof_", Vector3(55, 0, 0), Vector3.ZERO, 0.065)
	await _parallel(victim.visual_root, {
		"scale": Vector3(1.62, 0.62, 0.94),
		"position": Vector3(0.55, 0.22, 0),
		"rotation_degrees:y": 120.0
	}, 0.10)

	var fly := create_tween().set_parallel()
	fly.tween_property(victim.visual_root, "position", Vector3(4.3, 1.25, 0), _d(0.48))
	fly.tween_property(victim.visual_root, "rotation_degrees:y", 1080.0, _d(0.48))
	await fly.finished

	await _tween(attacker.visual_root, "rotation_degrees:y", 360.0, 0.30)
	await _tween(attacker.visual_root, "position", Vector3.ZERO, 0.14)
	await _wait(0.10)

func _bishop_ram(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	if attacker.has_authored_animation(&"RamCharge"):
		await _bishop_ram_authored(attacker, victim, data)
		return
	await _bishop_ram_fallback(attacker, victim, data)

func _bishop_ram_authored(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	# Bone animation owns the Bishop body/head/trunk/staff/cape pose while this
	# director keeps world-space charge travel, impact timing and victim physics.
	var playback_speed := 1.10
	var clip_length := attacker.authored_animation_length(&"RamCharge") / playback_speed
	if clip_length <= 0.0:
		clip_length = 1.55
	attacker.play_authored_animation(&"RamCharge", playback_speed, 0.05)

	# Wind-up: body folds forward, trunk extends and the staff rolls back.
	for i in range(3):
		_dust(attacker.global_position + Vector3(0, 0.08, 0))
		await _wait(clip_length * 0.055)

	var charge_target := victim.global_position + Vector3(0.52, 0, 0)
	var charge := create_tween().set_parallel()
	charge.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	charge.tween_property(attacker, "global_position", charge_target, _d(clip_length * 0.24))
	charge.tween_property(attacker.visual_root, "scale", Vector3(1.08, 0.92, 1.04), _d(clip_length * 0.24))
	await charge.finished

	# Frame ~18/40 is the authored trunk/body impact pose.
	_camera_punch(0.22)
	_impact_burst(victim.battle_target.global_position, Color("#ffcb75"), 1.40)
	_stone_debris(victim.global_position, Color("#c9b38f"), 10)
	_shockwave(victim.global_position, Color("#c99b62"), 0.90)
	_flash(victim.battle_target.global_position, Color("#ffcb75"), 0.38)
	_comic_text("WHOOSH!", victim.battle_target.global_position + Vector3(0, 0.8, 0), Color("#f0b65e"))
	victim.play_hit_pose()
	capture_impact.emit(data.id)
	_skid_mark(attacker.global_position - Vector3(1.2, 0.36, 0))
	# Short hit-stop keeps both silhouettes readable at the authored contact pose.
	await _wait(0.12)

	var blast := create_tween().set_parallel()
	blast.tween_property(victim.visual_root, "position", Vector3(4.0, 1.0, 0), _d(0.32))
	blast.tween_property(victim.visual_root, "scale", Vector3(0.35, 0.35, 0.35), _d(0.32))
	blast.tween_property(victim.visual_root, "rotation_degrees:z", -420.0, _d(0.32))
	await blast.finished

	var remaining := maxf(clip_length * 0.42 - 0.44, 0.04)
	await _wait(remaining)
	attacker.stop_authored_animation()
	var settle := create_tween().set_parallel()
	settle.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle.tween_property(attacker.visual_root, "scale", Vector3.ONE, _d(0.16))
	settle.tween_property(attacker.visual_root, "rotation_degrees", Vector3.ZERO, _d(0.16))
	await settle.finished

func _bishop_ram_fallback(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	await _animate_part_prefix(attacker, "Trunk", Vector3(-24, 0, 0), Vector3.ZERO, 0.16)
	await _animate_part_prefix(attacker, "V3_TrunkTip", Vector3(-28, 0, 0), Vector3(0, -0.02, -0.05), 0.16)
	await _animate_part_prefix(attacker, "Staff", Vector3(0, 0, -22), Vector3.ZERO, 0.16)
	await _animate_part_prefix(attacker, "V3_CapeLayer", Vector3(-12, 0, 0), Vector3(0, 0.03, 0.08), 0.16)
	await _parallel(attacker.visual_root, {
		"rotation_degrees:z": -42.0,
		"scale": Vector3(1.0, 0.92, 1.0)
	}, 0.30)

	for i in range(3):
		_dust(attacker.global_position + Vector3(0, 0.08, 0))
		await _tween(attacker.visual_root, "position:x", -0.08 if i % 2 == 0 else 0.08, 0.07)

	await _wait(0.10)

	var charge_target := victim.global_position + Vector3(0.52, 0, 0)
	var charge := create_tween().set_parallel()
	charge.tween_property(attacker, "global_position", charge_target, _d(0.23))
	charge.tween_property(attacker.visual_root, "scale", Vector3(1.12, 0.88, 1.0), _d(0.23))
	await charge.finished

	_camera_punch(0.20)
	_impact_burst(victim.battle_target.global_position, Color("#ffcb75"), 1.35)
	_stone_debris(victim.global_position, Color("#c9b38f"), 9)
	_shockwave(victim.global_position, Color("#c99b62"), 0.85)
	_flash(victim.battle_target.global_position, Color("#ffcb75"), 0.36)
	_comic_text("WHOOSH!", victim.battle_target.global_position + Vector3(0, 0.8, 0), Color("#f0b65e"))
	victim.play_hit_pose()
	capture_impact.emit(data.id)
	_skid_mark(attacker.global_position - Vector3(1.2, 0.36, 0))

	var blast := create_tween().set_parallel()
	blast.tween_property(victim.visual_root, "position", Vector3(4.0, 1.0, 0), _d(0.32))
	blast.tween_property(victim.visual_root, "scale", Vector3(0.35, 0.35, 0.35), _d(0.32))
	blast.tween_property(victim.visual_root, "rotation_degrees:z", -420.0, _d(0.32))
	await blast.finished

	await _tween(attacker.visual_root, "rotation_degrees:z", 0.0, 0.24)
	await _tween(attacker.visual_root, "rotation_degrees:y", 18.0, 0.10)
	await _tween(attacker.visual_root, "rotation_degrees:y", 0.0, 0.10)

func _rook_crush(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	if attacker.has_authored_animation(&"JumpCrush"):
		await _rook_crush_authored(attacker, victim, data)
		return
	await _rook_crush_fallback(attacker, victim, data)

func _rook_crush_authored(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	# Skeleton animation owns compression, arm/fist wind-up and slam pose.
	# BattleDirector keeps world-space jump, shadow, victim squash and VFX timing.
	var playback_speed := 1.12
	var clip_length := attacker.authored_animation_length(&"JumpCrush") / playback_speed
	if clip_length <= 0.0:
		clip_length = 1.45
	attacker.play_authored_animation(&"JumpCrush", playback_speed, 0.05)

	# Compress, then launch above the target while the authored body stretches.
	await _wait(clip_length * 0.15)
	var launch := create_tween().set_parallel()
	launch.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	launch.tween_property(attacker, "global_position", victim.global_position + Vector3(0, 6.5, 0), _d(clip_length * 0.20))
	await launch.finished

	var shadow := _shadow(victim.global_position)
	await _tween(shadow, "scale", Vector3(2.8, 1.0, 2.8), clip_length * 0.18)
	await _tween(victim.visual_root, "rotation_degrees:x", -10.0, 0.06)

	# Frame ~27/42 is the authored slam/contact pose.
	var drop := create_tween()
	drop.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_property(attacker, "global_position", victim.global_position, _d(clip_length * 0.15))
	await drop.finished

	_camera_punch(0.30)
	_impact_burst(victim.battle_target.global_position, Color("#f1d1a2"), 1.70)
	_shockwave(victim.global_position, Color("#d0b28a"), 1.18)
	_flash(victim.battle_target.global_position, Color("#f1d1a2"), 0.44)
	_comic_text("SPLOTCH!", victim.battle_target.global_position + Vector3(0, 0.8, 0), Color("#f3d8a6"))
	victim.play_hit_pose()
	capture_impact.emit(data.id)
	_dust(victim.global_position)
	_dust(victim.global_position + Vector3(0.35, 0, 0.15))
	_dust(victim.global_position + Vector3(-0.35, 0, -0.15))
	_stone_debris(victim.global_position, Color("#8d725f"), 12)
	await _wait(0.12)

	await _tween(victim.visual_root, "scale", Vector3(1.80, 0.04, 1.80), 0.08)
	await _tween(attacker.visual_root, "position", Vector3(0, 0.22, 0), 0.09)
	await _tween(attacker.visual_root, "position", Vector3.ZERO, 0.11)
	shadow.queue_free()

	var remaining := maxf(clip_length * 0.32 - 0.30, 0.04)
	await _wait(remaining)
	attacker.stop_authored_animation()
	await _wait(0.06)

func _rook_crush_fallback(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	await _animate_part_prefix(attacker, "Arm_", Vector3(0, 0, 28), Vector3.ZERO, 0.14)
	await _animate_part_prefix(attacker, "Fist_", Vector3(0, 0, 36), Vector3.ZERO, 0.14)
	await _animate_part_prefix(attacker, "V3_FistKnuckle", Vector3(0, 0, 40), Vector3.ZERO, 0.14)
	await _animate_part_prefix(attacker, "V3_TabardPoint", Vector3(-10, 0, 0), Vector3(0, 0.03, 0.06), 0.14)
	await _tween(attacker.visual_root, "scale", Vector3(1.20, 0.58, 1.20), 0.22)
	await _parallel(attacker.visual_root, {
		"scale": Vector3(0.90, 1.18, 0.90),
		"position": Vector3(0, 6.5, 0)
	}, 0.20)

	var travel := create_tween()
	travel.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(attacker, "global_position", victim.global_position, _d(0.18))
	await travel.finished

	var shadow := _shadow(victim.global_position)
	await _tween(shadow, "scale", Vector3(2.8, 1.0, 2.8), 0.42)
	await _tween(victim.visual_root, "rotation_degrees:x", -10.0, 0.08)

	await _tween(attacker.visual_root, "position", Vector3.ZERO, 0.14)
	_camera_punch(0.28)
	_impact_burst(victim.battle_target.global_position, Color("#f1d1a2"), 1.65)
	_shockwave(victim.global_position, Color("#d0b28a"), 1.15)
	_flash(victim.battle_target.global_position, Color("#f1d1a2"), 0.42)
	_comic_text("SPLOTCH!", victim.battle_target.global_position + Vector3(0, 0.8, 0), Color("#f3d8a6"))
	victim.play_hit_pose()
	capture_impact.emit(data.id)
	_dust(victim.global_position)
	_dust(victim.global_position + Vector3(0.35, 0, 0.15))
	_dust(victim.global_position + Vector3(-0.35, 0, -0.15))
	_stone_debris(victim.global_position, Color("#8d725f"), 12)

	await _tween(victim.visual_root, "scale", Vector3(1.80, 0.04, 1.80), 0.08)
	await _tween(attacker.visual_root, "position", Vector3(0, 0.25, 0), 0.10)
	await _tween(attacker.visual_root, "position", Vector3.ZERO, 0.12)
	shadow.queue_free()
	await _wait(0.12)

func _queen_transform(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	if attacker.has_authored_animation(&"TransformSpell"):
		await _queen_transform_authored(attacker, victim, data)
		return
	await _queen_transform_fallback(attacker, victim, data)

func _queen_transform_authored(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	# AnimationPlayer owns Queen body/head/hair/cape/staff/orb choreography.
	# This director keeps target magic, replacement spawning and impact VFX deterministic.
	var playback_speed := 1.08
	var clip_length := attacker.authored_animation_length(&"TransformSpell") / playback_speed
	if clip_length <= 0.0:
		clip_length = 1.55
	attacker.play_authored_animation(&"TransformSpell", playback_speed, 0.05)

	# Wind-up: staff sweeps back and the authored orb grows.
	await _wait(clip_length * 0.18)
	var orb := _orb(victim.global_position + Vector3(0, 1.45, 0), Color("#a854ff"), 0.12)
	await _tween(orb, "scale", Vector3.ONE * 3.5, minf(0.36, clip_length * 0.24))
	await _wait(maxf(clip_length * 0.08, 0.08))

	# Cast/contact pose is around frame 22/44.
	var smoke := _orb(victim.global_position + Vector3(0, 0.75, 0), Color("#7a3db4"), 0.45)
	_magic_hearts(victim.global_position + Vector3(0, 0.85, 0), Color("#f35ac8"))
	await _tween(smoke, "scale", Vector3.ONE * 3.0, 0.24)

	_camera_punch(0.10)
	_impact_burst(victim.battle_target.global_position, Color("#b862ff"), 1.10)
	_flash(victim.battle_target.global_position, Color("#e0a8ff"), 0.24)
	_comic_text("POOF!", victim.battle_target.global_position + Vector3(0, 0.8, 0), Color("#c979ff"))
	victim.play_hit_pose()
	capture_impact.emit(data.id)
	await _wait(0.10)

	victim.visible = false
	var replacement := _spawn_magic_result(victim.piece_type, victim.global_position)
	await _tween(smoke, "scale", Vector3.ONE * 0.15, 0.28)
	smoke.queue_free()
	orb.queue_free()

	await _play_magic_aftermath(replacement, victim.piece_type)
	var remaining := maxf(clip_length * 0.28 - 0.35, 0.04)
	await _wait(remaining)
	attacker.stop_authored_animation()

func _queen_transform_fallback(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	await _animate_part_prefix(attacker, "Staff", Vector3(0, 0, 34), Vector3.ZERO, 0.16)
	await _animate_part_prefix(attacker, "V3_HairCurl", Vector3(-8, 0, 0), Vector3(0, 0.03, 0.03), 0.16)
	await _animate_part_prefix(attacker, "V3_Cape", Vector3(-14, 0, 0), Vector3(0, 0.04, 0.08), 0.16)
	await _tween(attacker.visual_root, "rotation_degrees:z", 14.0, 0.18)
	var orb := _orb(victim.global_position + Vector3(0, 1.45, 0), Color("#a854ff"), 0.12)
	await _tween(orb, "scale", Vector3.ONE * 3.5, 0.42)
	await _wait(0.18)

	var smoke := _orb(victim.global_position + Vector3(0, 0.75, 0), Color("#7a3db4"), 0.45)
	_magic_hearts(victim.global_position + Vector3(0, 0.85, 0), Color("#f35ac8"))
	await _tween(smoke, "scale", Vector3.ONE * 3.0, 0.30)

	_camera_punch(0.08)
	_impact_burst(victim.battle_target.global_position, Color("#b862ff"), 1.05)
	_comic_text("POOF!", victim.battle_target.global_position + Vector3(0, 0.8, 0), Color("#c979ff"))
	victim.play_hit_pose()
	capture_impact.emit(data.id)
	victim.visible = false
	var replacement := _spawn_magic_result(victim.piece_type, victim.global_position)
	await _tween(smoke, "scale", Vector3.ONE * 0.15, 0.30)
	smoke.queue_free()
	orb.queue_free()

	await _play_magic_aftermath(replacement, victim.piece_type)
	await _tween(attacker.visual_root, "rotation_degrees:z", 0.0, 0.18)

func _king_trapdoor(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	await _animate_part_prefix(attacker, "Arm_", Vector3(0, 0, -22), Vector3.ZERO, 0.12)
	await _animate_part_prefix(attacker, "Scepter", Vector3(0, 0, -18), Vector3.ZERO, 0.12)
	await _animate_part_prefix(attacker, "V3_CoatPanel", Vector3(0, 0, -4), Vector3(0, 0.02, 0.02), 0.12)
	var remote := _remote(attacker.global_position + Vector3(0.32, 0.92, 0))
	await _tween(attacker.visual_root, "rotation_degrees:z", -8.0, 0.20)
	await _wait(0.16)
	_flash(remote.global_position + Vector3(0, 0.12, 0), Color("#ff3333"), 0.16)
	_comic_text("CLICK!", remote.global_position + Vector3(0, 0.45, 0), Color("#ff5b4d"))

	var trap := _trapdoor(victim.global_position - Vector3(0, 0.35, 0))
	var left: Node3D = trap.get_node("Left")
	var right: Node3D = trap.get_node("Right")
	var open := create_tween().set_parallel()
	open.tween_property(left, "position:x", -0.72, _d(0.18))
	open.tween_property(right, "position:x", 0.72, _d(0.18))
	await open.finished

	_camera_punch(0.09)
	_shockwave(victim.global_position, Color("#7b5a48"), 0.65)
	_comic_text("CLACK!", victim.battle_target.global_position + Vector3(0, 0.55, 0), Color("#d6a578"))
	victim.play_hit_pose()
	capture_impact.emit(data.id)
	await _parallel(victim.visual_root, {
		"position": Vector3(0, -5.0, 0),
		"scale": Vector3(0.72, 0.72, 0.72)
	}, 0.38)

	_flash(victim.global_position - Vector3(0, 1.6, 0), Color("#d5b07a"), 0.20)
	await _wait(0.16)

	var close := create_tween().set_parallel()
	close.tween_property(left, "position:x", -0.34, _d(0.16))
	close.tween_property(right, "position:x", 0.34, _d(0.16))
	await close.finished
	trap.queue_free()
	remote.queue_free()

	await _tween(attacker.visual_root, "rotation_degrees:z", 6.0, 0.10)
	await _tween(attacker.visual_root, "rotation_degrees:z", 0.0, 0.12)


func _stone_debris(p: Vector3, color: Color, count: int = 8) -> void:
	for i in range(count):
		var mesh := BoxMesh.new()
		var s := 0.05 + 0.018 * float(i % 4)
		mesh.size = Vector3(s, s * 0.8, s * 1.15)
		var piece := MeshInstance3D.new()
		piece.mesh = mesh
		piece.material_override = _fx_material(color.darkened(0.04 * float(i % 3)), 0.0)
		add_child(piece)
		piece.global_position = p + Vector3(0, 0.12, 0)
		var angle := TAU * float(i) / float(maxi(count, 1))
		var target := piece.position + Vector3(cos(angle) * (0.45 + 0.06 * i), 0.28 + 0.035 * float(i % 5), sin(angle) * (0.45 + 0.06 * i))
		var tween := create_tween().set_parallel()
		tween.tween_property(piece, "position", target, 0.28)
		tween.tween_property(piece, "rotation_degrees", Vector3(120 + i * 17, 80 + i * 23, 160 + i * 11), 0.28)
		await get_tree().create_timer(0.30).timeout
		if is_instance_valid(piece):
			piece.queue_free()

func _magic_hearts(p: Vector3, color: Color) -> void:
	for i in range(5):
		var heart := Node3D.new()
		heart.name = "MagicHeart_%02d" % i
		add_child(heart)
		heart.global_position = p
		var mat := _fx_material(color.lightened(0.06 * float(i)), 3.6)

		for side in [-1.0, 1.0]:
			var lobe_mesh := SphereMesh.new()
			lobe_mesh.radius = 0.065
			lobe_mesh.height = 0.13
			var lobe := MeshInstance3D.new()
			lobe.mesh = lobe_mesh
			lobe.material_override = mat
			lobe.position = Vector3(0.045 * side, 0.045, 0)
			heart.add_child(lobe)

		var point_mesh := CylinderMesh.new()
		point_mesh.top_radius = 0.0
		point_mesh.bottom_radius = 0.075
		point_mesh.height = 0.13
		var point := MeshInstance3D.new()
		point.mesh = point_mesh
		point.material_override = mat
		point.position = Vector3(0, -0.035, 0)
		point.rotation_degrees.z = 180.0
		heart.add_child(point)

		var a := -0.75 + 0.38 * float(i)
		var target := heart.position + Vector3(sin(a) * (0.55 + i * 0.08), 0.65 + i * 0.11, cos(a) * 0.18)
		var tween := create_tween().set_parallel()
		tween.tween_property(heart, "position", target, 0.42)
		tween.tween_property(heart, "scale", Vector3.ONE * (1.0 + i * 0.10), 0.42)
		tween.tween_property(heart, "rotation_degrees:z", -18.0 + i * 9.0, 0.42)
		await get_tree().create_timer(0.46).timeout
		if is_instance_valid(heart):
			heart.queue_free()

func _animate_part_prefix(
	piece: PieceView,
	prefix: String,
	rotation_offset: Vector3,
	position_offset: Vector3,
	seconds: float
) -> void:
	if piece == null:
		return
	var parts := piece.get_visual_parts(prefix)
	if parts.is_empty():
		return
	var tween := create_tween().set_parallel()
	for part in parts:
		var rest_rotation := piece.get_part_rest_rotation(part)
		var rest_position := piece.get_part_rest_position(part)
		tween.tween_property(part, "rotation_degrees", rest_rotation + rotation_offset, _d(seconds))
		if position_offset != Vector3.ZERO:
			tween.tween_property(part, "position", rest_position + position_offset, _d(seconds))
	await tween.finished


func _camera_punch(strength: float = 0.12) -> void:
	if arena == null or arena.battle_camera == null:
		return
	var camera := arena.battle_camera
	camera.position = _camera_rest_position + Vector3(strength * 0.55, strength * 0.28, -strength)
	camera.rotation_degrees = _camera_rest_rotation + Vector3(-strength * 18.0, strength * 11.0, strength * 8.0)
	var tween := create_tween().set_parallel()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "position", _camera_rest_position, _d(0.12))
	tween.tween_property(camera, "rotation_degrees", _camera_rest_rotation, _d(0.12))

func _impact_burst(p: Vector3, color: Color, size: float = 1.0) -> void:
	var root := Node3D.new()
	root.name = "ImpactBurst"
	add_child(root)
	root.global_position = p

	var center_mesh := SphereMesh.new()
	center_mesh.radius = 0.12 * size
	center_mesh.height = 0.24 * size
	var center := MeshInstance3D.new()
	center.name = "Core"
	center.mesh = center_mesh
	center.material_override = _fx_material(color, 5.0)
	root.add_child(center)

	for i in range(10):
		var ray_mesh := BoxMesh.new()
		ray_mesh.size = Vector3(0.42 * size, 0.055 * size, 0.035 * size)
		var ray := MeshInstance3D.new()
		ray.name = "Ray_%02d" % i
		ray.mesh = ray_mesh
		ray.material_override = _fx_material(color.lightened(0.12), 3.2)
		ray.rotation_degrees.z = float(i) * 36.0
		var angle := TAU * float(i) / 10.0
		ray.position = Vector3(cos(angle) * 0.22 * size, sin(angle) * 0.22 * size, 0)
		root.add_child(ray)

	for i in range(6):
		var spark_mesh := SphereMesh.new()
		spark_mesh.radius = 0.035 * size
		spark_mesh.height = 0.07 * size
		var spark := MeshInstance3D.new()
		spark.mesh = spark_mesh
		spark.material_override = _fx_material(color.lightened(0.22), 4.0)
		root.add_child(spark)
		var angle := TAU * float(i) / 6.0 + 0.22
		var target := Vector3(cos(angle) * 0.85 * size, sin(angle) * 0.55 * size, 0)
		var spark_tween := create_tween()
		spark_tween.tween_property(spark, "position", target, 0.20)

	root.scale = Vector3.ONE * 0.35
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "scale", Vector3.ONE * 1.15, 0.09)
	tween.tween_property(root, "scale", Vector3.ONE * 0.10, 0.18)
	tween.tween_callback(root.queue_free)

func _shockwave(p: Vector3, color: Color, radius: float = 1.0) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.22 * radius
	mesh.outer_radius = 0.28 * radius
	mesh.rings = 24
	mesh.ring_segments = 8
	var ring := MeshInstance3D.new()
	ring.name = "Shockwave"
	ring.mesh = mesh
	ring.material_override = _fx_material(color, 2.5)
	add_child(ring)
	ring.global_position = p + Vector3(0, 0.04, 0)
	ring.rotation_degrees.x = 90.0
	ring.scale = Vector3.ONE * 0.25
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector3.ONE * 3.3, 0.24)
	tween.tween_callback(ring.queue_free)

func _tween(object: Object, property: NodePath, value: Variant, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(object, property, value, _d(seconds))
	await tween.finished

func _parallel(object: Object, props: Dictionary, seconds: float) -> void:
	var tween := create_tween().set_parallel()
	for property in props.keys():
		tween.tween_property(object, NodePath(String(property)), props[property], _d(seconds))
	await tween.finished

func _wait(seconds: float) -> void:
	await get_tree().create_timer(_d(seconds)).timeout

func _d(seconds: float) -> float:
	return maxf(seconds * time_scale, 0.001)

func _fx_material(color: Color, emission: float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.22
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	return mat

func _flash(p: Vector3, color: Color, size: float) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _fx_material(color, 3.5)
	add_child(node)
	node.global_position = p
	var tween := create_tween()
	tween.tween_property(node, "scale", Vector3.ONE * 1.8, _d(0.10))
	tween.tween_callback(node.queue_free)

func _dust(p: Vector3) -> void:
	for i in range(5):
		var mesh := SphereMesh.new()
		mesh.radius = 0.07
		mesh.height = 0.14
		var node := MeshInstance3D.new()
		node.mesh = mesh
		node.material_override = _fx_material(Color("#bca78d"), 0.0)
		add_child(node)
		node.global_position = p + Vector3(0, 0.12, 0)
		var angle := TAU * float(i) / 5.0
		var target := node.position + Vector3(cos(angle) * 0.55, 0.22, sin(angle) * 0.55)
		var tween := create_tween()
		tween.tween_property(node, "position", target, _d(0.22))
		tween.tween_callback(node.queue_free)

func _shadow(p: Vector3) -> Node3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.28
	mesh.height = 0.018
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _fx_material(Color("#161116"), 0.0)
	add_child(node)
	node.global_position = p - Vector3(0, 0.34, 0)
	node.scale = Vector3(0.3, 1.0, 0.3)
	return node

func _skid_mark(p: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.1, 0.012, 0.18)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _fx_material(Color("#1b1715"), 0.0)
	add_child(node)
	node.global_position = p
	var tween := create_tween()
	tween.tween_interval(_d(0.7))
	tween.tween_callback(node.queue_free)

func _orb(p: Vector3, color: Color, radius: float) -> Node3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _fx_material(color, 4.0)
	add_child(node)
	node.global_position = p
	return node

func _spawn_magic_result(victim_type: StringName, p: Vector3) -> Node3D:
	match victim_type:
		&"Bishop":
			return _spawn_ash_pile(p)
		&"Rook":
			return _spawn_jelly(p)
		&"King":
			return _spawn_crowned_frog(p)
	return _spawn_duck(p)

func _play_magic_aftermath(node: Node3D, victim_type: StringName) -> void:
	if node == null:
		return
	match victim_type:
		&"Bishop":
			await _tween(node, "scale", Vector3(1.25, 0.55, 1.25), 0.22)
			await _wait(0.18)
		&"Rook":
			await _tween(node, "scale", Vector3(1.35, 0.55, 1.35), 0.20)
			await _tween(node, "scale", Vector3(1.55, 0.28, 1.55), 0.20)
		&"King":
			await _tween(node, "position:y", node.position.y + 0.55, 0.14)
			await _tween(node, "position:x", node.position.x + 3.8, 0.48)
		_:
			await _tween(node, "rotation_degrees:z", 10.0, 0.08)
			await _tween(node, "rotation_degrees:z", -10.0, 0.08)
			await _tween(node, "rotation_degrees:z", 0.0, 0.08)
			await _tween(node, "position:x", node.position.x + 4.2, 0.52)
	node.queue_free()

func _spawn_duck(p: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "RubberDuck"
	add_child(root)
	root.global_position = p

	var yellow := _fx_material(Color("#ffd34d"), 0.4)
	var orange := _fx_material(Color("#ff8a2b"), 0.2)

	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.28
	body_mesh.height = 0.56
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = yellow
	body.position = Vector3(0, 0.30, 0)
	root.add_child(body)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.18
	head_mesh.height = 0.36
	var head := MeshInstance3D.new()
	head.mesh = head_mesh
	head.material_override = yellow
	head.position = Vector3(0.18, 0.58, 0)
	root.add_child(head)

	var beak_mesh := BoxMesh.new()
	beak_mesh.size = Vector3(0.20, 0.08, 0.14)
	var beak := MeshInstance3D.new()
	beak.mesh = beak_mesh
	beak.material_override = orange
	beak.position = Vector3(0.36, 0.57, 0)
	root.add_child(beak)

	return root

func _remote(p: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "KingRemote"
	add_child(root)
	root.global_position = p

	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.22, 0.32, 0.10)
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = _fx_material(Color("#2b2b2b"), 0.0)
	root.add_child(body)

	var button_mesh := SphereMesh.new()
	button_mesh.radius = 0.06
	button_mesh.height = 0.12
	var button := MeshInstance3D.new()
	button.mesh = button_mesh
	button.material_override = _fx_material(Color("#d82f2f"), 1.2)
	button.position = Vector3(0, 0.09, 0.07)
	root.add_child(button)

	return root

func _trapdoor(p: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "TrapdoorEffect"
	add_child(root)
	root.global_position = p

	var dark := _fx_material(Color("#171216"), 0.0)
	for pair in [["Left", -0.34], ["Right", 0.34]]:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.64, 0.04, 1.05)
		var panel := MeshInstance3D.new()
		panel.name = pair[0]
		panel.mesh = mesh
		panel.material_override = dark
		panel.position = Vector3(pair[1], 0, 0)
		root.add_child(panel)

	return root

func _spawn_ash_pile(p: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "AshPile"
	add_child(root)
	root.global_position = p
	var ash := _fx_material(Color("#554f50"), 0.0)
	for i in range(5):
		var mesh := SphereMesh.new()
		mesh.radius = 0.16 + i * 0.025
		mesh.height = 0.16
		var lump := MeshInstance3D.new()
		lump.mesh = mesh
		lump.material_override = ash
		lump.position = Vector3((i - 2) * 0.13, 0.08, sin(float(i)) * 0.10)
		root.add_child(lump)
	return root

func _spawn_jelly(p: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "PinkJelly"
	add_child(root)
	root.global_position = p
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.62, 0.62, 0.62)
	var cube := MeshInstance3D.new()
	cube.mesh = mesh
	cube.material_override = _fx_material(Color("#f06aa7"), 0.8)
	cube.position = Vector3(0, 0.31, 0)
	root.add_child(cube)
	return root

func _spawn_crowned_frog(p: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "CrownedFrog"
	add_child(root)
	root.global_position = p
	var green := _fx_material(Color("#64b85b"), 0.2)
	var gold := _fx_material(Color("#d7a73d"), 0.7)

	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.25
	body_mesh.height = 0.38
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = green
	body.position = Vector3(0, 0.22, 0)
	root.add_child(body)

	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 0.13
	crown_mesh.bottom_radius = 0.18
	crown_mesh.height = 0.18
	var crown := MeshInstance3D.new()
	crown.mesh = crown_mesh
	crown.material_override = gold
	crown.position = Vector3(0, 0.52, 0)
	root.add_child(crown)
	return root


func _capture_separation(id: StringName) -> float:
	match id:
		&"pawn_toe_stab":
			return 1.18
		&"knight_double_kick":
			return 1.48
		&"bishop_ram":
			return 2.05
		&"rook_crush":
			return 1.70
		&"queen_transform":
			return 1.80
		&"king_trapdoor":
			return 1.82
	return 1.90

func _set_battle_camera(profile: StringName) -> void:
	match profile:
		&"BattleSide":
			arena.battle_camera.position = Vector3(4.4, 2.0, 2.5)
		&"BattleWide":
			arena.battle_camera.position = Vector3(0, 3.2, 6.2)
		&"BattleLow":
			arena.battle_camera.position = Vector3(0, 1.45, 5.0)
		_:
			arena.battle_camera.position = Vector3(2.20, 1.90, 6.20)
	arena.battle_camera.fov = 45.0
	arena.battle_camera.look_at(Vector3(0, 0.86, -0.20), Vector3.UP)
	_camera_rest_position = arena.battle_camera.position
	_camera_rest_rotation = arena.battle_camera.rotation_degrees

func _comic_text(text_value: String, p: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.font_size = 64
	label.outline_size = 12
	label.modulate = color
	label.scale = Vector3.ONE * 0.012
	add_child(label)
	label.global_position = p
	var tween := create_tween().set_parallel()
	tween.tween_property(label, "scale", Vector3.ONE * 0.020, _d(0.10))
	tween.tween_property(label, "position:y", label.position.y + 0.45, _d(0.28))
	await get_tree().create_timer(_d(0.34)).timeout
	if is_instance_valid(label):
		label.queue_free()
