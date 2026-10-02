class_name BattleDirector
extends Node3D

signal capture_started(id: StringName)
signal capture_impact(id: StringName)
signal capture_finished(id: StringName)

var busy := false
var time_scale := 1.0

var arena: ArenaBuilder
var registry := CaptureRegistry.new()

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

	attacker.global_position = arena.battle_stage.get_node("AttackerAnchor").global_position
	victim.global_position = arena.battle_stage.get_node("VictimAnchor").global_position
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
	await _animate_part_prefix(attacker, "Knife", Vector3(0, 0, 32), Vector3.ZERO, 0.14)
	await _tween(attacker.visual_root, "position", Vector3(0, -0.10, 0), 0.18)
	await _animate_part_prefix(attacker, "Spear", Vector3(0, 0, 30), Vector3.ZERO, 0.08)
	await _animate_part_prefix(attacker, "Knife", Vector3(0, 0, -38), Vector3.ZERO, 0.08)
	await _tween(attacker.visual_root, "position", Vector3(0.38, -0.04, 0), 0.11)

	capture_impact.emit(data.id)
	_flash(victim.foot_target.global_position, Color("#ffd35c"), 0.26)
	_comic_text("BAM!", victim.battle_target.global_position + Vector3(0, 0.65, 0), Color("#ffd84f"))
	await _parallel(victim.visual_root, {
		"scale": Vector3(1.18, 0.82, 1.18),
		"position": Vector3(0, 0.22, 0)
	}, 0.10)

	await _tween(victim.visual_root, "position", Vector3(0.10, 0.70, 0), 0.16)
	await _tween(victim.visual_root, "position", Vector3(-0.10, 0.12, 0), 0.14)
	await _tween(victim.visual_root, "position", Vector3(0.10, 0.82, 0), 0.16)
	await _tween(victim.visual_root, "position", Vector3(0, 5.8, 0), 0.28)

	await _tween(attacker.visual_root, "rotation_degrees:z", -10.0, 0.10)
	await _tween(attacker.visual_root, "rotation_degrees:z", 0.0, 0.10)
	await _wait(0.10)

func _knight_double_kick(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	await _tween(attacker.visual_root, "rotation_degrees:y", 180.0, 0.30)
	await _parallel(attacker.visual_root, {
		"position": Vector3(0, 0.20, 0),
		"rotation_degrees:x": -7.0
	}, 0.14)
	await _animate_part_prefix(attacker, "Leg_", Vector3(-38, 0, 0), Vector3.ZERO, 0.11)
	await _animate_part_prefix(attacker, "Hoof_", Vector3(-28, 0, 0), Vector3.ZERO, 0.11)

	_flash(victim.battle_target.global_position, Color("#f4d29a"), 0.18)
	await _animate_part_prefix(attacker, "Leg_", Vector3(62, 0, 0), Vector3.ZERO, 0.07)
	await _animate_part_prefix(attacker, "Hoof_", Vector3(48, 0, 0), Vector3.ZERO, 0.07)
	await _parallel(victim.visual_root, {
		"scale": Vector3(1.35, 0.75, 1.05),
		"position": Vector3(0.18, 0.08, 0)
	}, 0.08)

	capture_impact.emit(data.id)
	await _animate_part_prefix(attacker, "Leg_", Vector3(-52, 0, 0), Vector3.ZERO, 0.065)
	await _animate_part_prefix(attacker, "Hoof_", Vector3(-40, 0, 0), Vector3.ZERO, 0.065)
	await _animate_part_prefix(attacker, "Leg_", Vector3(70, 0, 0), Vector3.ZERO, 0.065)
	await _animate_part_prefix(attacker, "Hoof_", Vector3(55, 0, 0), Vector3.ZERO, 0.065)
	_flash(victim.battle_target.global_position, Color("#fff0c2"), 0.28)
	_comic_text("KICK!", victim.battle_target.global_position + Vector3(0, 0.7, 0), Color("#ffb953"))
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
	await _animate_part_prefix(attacker, "Trunk", Vector3(-22, 0, 0), Vector3.ZERO, 0.16)
	await _animate_part_prefix(attacker, "Staff", Vector3(0, 0, -18), Vector3.ZERO, 0.16)
	await _parallel(attacker.visual_root, {
		"rotation_degrees:z": -42.0,
		"scale": Vector3(1.0, 0.92, 1.0)
	}, 0.30)

	for i in range(3):
		_dust(attacker.global_position + Vector3(0, 0.08, 0))
		await _tween(attacker.visual_root, "position:x", -0.08 if i % 2 == 0 else 0.08, 0.07)

	await _wait(0.10)

	var charge_target := victim.global_position + Vector3(1.55, 0, 0)
	var charge := create_tween().set_parallel()
	charge.tween_property(attacker, "global_position", charge_target, _d(0.23))
	charge.tween_property(attacker.visual_root, "scale", Vector3(1.12, 0.88, 1.0), _d(0.23))
	await charge.finished

	capture_impact.emit(data.id)
	_flash(victim.battle_target.global_position, Color("#ffcb75"), 0.36)
	_comic_text("WHOOSH!", victim.battle_target.global_position + Vector3(0, 0.8, 0), Color("#f0b65e"))
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
	await _animate_part_prefix(attacker, "Arm_", Vector3(0, 0, 26), Vector3.ZERO, 0.14)
	await _animate_part_prefix(attacker, "Fist_", Vector3(0, 0, 32), Vector3.ZERO, 0.14)
	await _tween(attacker.visual_root, "scale", Vector3(1.20, 0.58, 1.20), 0.22)
	await _parallel(attacker.visual_root, {
		"scale": Vector3(0.90, 1.18, 0.90),
		"position": Vector3(0, 6.5, 0)
	}, 0.20)

	var shadow := _shadow(victim.global_position)
	await _tween(shadow, "scale", Vector3(2.8, 1.0, 2.8), 0.42)
	await _tween(victim.visual_root, "rotation_degrees:x", -10.0, 0.08)

	await _tween(attacker.visual_root, "position", Vector3.ZERO, 0.14)
	capture_impact.emit(data.id)
	_flash(victim.battle_target.global_position, Color("#f1d1a2"), 0.42)
	_comic_text("SPLOTCH!", victim.battle_target.global_position + Vector3(0, 0.8, 0), Color("#f3d8a6"))
	_dust(victim.global_position)
	_dust(victim.global_position + Vector3(0.35, 0, 0.15))
	_dust(victim.global_position + Vector3(-0.35, 0, -0.15))

	await _tween(victim.visual_root, "scale", Vector3(1.80, 0.04, 1.80), 0.08)
	await _tween(attacker.visual_root, "position", Vector3(0, 0.25, 0), 0.10)
	await _tween(attacker.visual_root, "position", Vector3.ZERO, 0.12)
	shadow.queue_free()
	await _wait(0.12)

func _queen_transform(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	await _animate_part_prefix(attacker, "Staff", Vector3(0, 0, 28), Vector3.ZERO, 0.16)
	await _tween(attacker.visual_root, "rotation_degrees:z", 12.0, 0.18)
	var orb := _orb(victim.global_position + Vector3(0, 1.45, 0), Color("#a854ff"), 0.12)
	await _tween(orb, "scale", Vector3.ONE * 3.5, 0.42)
	await _wait(0.18)

	var smoke := _orb(victim.global_position + Vector3(0, 0.75, 0), Color("#7a3db4"), 0.45)
	await _tween(smoke, "scale", Vector3.ONE * 3.0, 0.30)

	capture_impact.emit(data.id)
	_comic_text("POOF!", victim.battle_target.global_position + Vector3(0, 0.8, 0), Color("#c979ff"))
	victim.visible = false
	var replacement := _spawn_magic_result(victim.piece_type, victim.global_position)
	await _tween(smoke, "scale", Vector3.ONE * 0.15, 0.30)
	smoke.queue_free()
	orb.queue_free()

	await _play_magic_aftermath(replacement, victim.piece_type)

	await _tween(attacker.visual_root, "rotation_degrees:z", 0.0, 0.18)

func _king_trapdoor(attacker: PieceView, victim: PieceView, data: CaptureAnimationData) -> void:
	await _animate_part_prefix(attacker, "Arm_", Vector3(0, 0, -18), Vector3.ZERO, 0.12)
	await _animate_part_prefix(attacker, "Scepter", Vector3(0, 0, -14), Vector3.ZERO, 0.12)
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
