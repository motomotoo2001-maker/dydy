extends SceneTree

const PATH := "res://assets/models/cathedral_production_v1.glb"
const REQUIRED_NAMES := [
	"CathedralProductionV1",
	"NaveFloor",
	"BackWallLower",
	"AltarTable",
	"CenterArch_PillarL",
	"Column_L_0_Shaft",
	"VaultRib_2",
	"NaveRidge",
	"BackGlass_1",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(PATH) as PackedScene
	if packed == null:
		push_error("CATHEDRAL_ASSET_FAIL missing PackedScene")
		quit(2)
		return
	var root := packed.instantiate()
	get_root().add_child(root)
	var meshes := 0
	_count_meshes(root, meshes)
	# GDScript integers are copied on call, so use direct recursive count helper.
	meshes = _mesh_count(root)
	if meshes < 100:
		push_error("CATHEDRAL_ASSET_FAIL too few meshes=%d" % meshes)
		quit(2)
		return
	for required in REQUIRED_NAMES:
		if not _has_named_node(root, required):
			push_error("CATHEDRAL_ASSET_FAIL missing node=%s" % required)
			quit(2)
			return
	print("CATHEDRAL_ASSET_PASS meshes=", meshes)
	root.queue_free()
	await process_frame
	quit(0)

func _mesh_count(node: Node) -> int:
	var total := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		total += _mesh_count(child)
	return total

func _count_meshes(_node: Node, _count: int) -> void:
	pass

func _has_named_node(node: Node, target: String) -> bool:
	if String(node.name) == target:
		return true
	for child in node.get_children():
		if _has_named_node(child, target):
			return true
	return false
