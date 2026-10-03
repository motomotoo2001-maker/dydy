extends SceneTree

const ASSETS := [
	["res://assets/models/white_pawn_production_v1.glb", "White"],
	["res://assets/models/black_pawn_production_v1.glb", "Black"],
]
const REQUIRED_ANIMS := ["Idle", "Selected", "Move", "Hit", "Victory", "Defeat", "ToeStab"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for spec in ASSETS:
		var path: String = spec[0]
		var side: String = spec[1]
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("PAWN_RIG_FAIL %s missing PackedScene %s" % [side, path])
			quit(2)
			return
		var root := packed.instantiate()
		get_root().add_child(root)
		var skeleton := _find_type(root, "Skeleton3D") as Skeleton3D
		if skeleton == null or skeleton.get_bone_count() < 13:
			push_error("PAWN_RIG_FAIL %s Skeleton3D missing/too small" % side)
			quit(2)
			return
		var player := _find_type(root, "AnimationPlayer") as AnimationPlayer
		if player == null:
			push_error("PAWN_RIG_FAIL %s AnimationPlayer missing" % side)
			quit(2)
			return
		var names: Array[String] = []
		for library_name in player.get_animation_library_list():
			var library := player.get_animation_library(library_name)
			if library == null:
				continue
			for animation_name in library.get_animation_list():
				names.append(String(animation_name))
		for required in REQUIRED_ANIMS:
			var found := false
			for available in names:
				if available == required or available.ends_with("/" + required) or available.contains(required):
					found = true
					break
			if not found:
				push_error("PAWN_RIG_FAIL %s missing animation %s available=%s" % [side, required, names])
				quit(2)
				return
		print("PAWN_RIG_OK side=", side, " bones=", skeleton.get_bone_count(), " animations=", names)
		root.queue_free()
		await process_frame
	print("PAWN_RIG_PASS")
	quit(0)

func _find_type(node: Node, class_name_text: String) -> Node:
	if node.is_class(class_name_text):
		return node
	for child in node.get_children():
		var found := _find_type(child, class_name_text)
		if found != null:
			return found
	return null
