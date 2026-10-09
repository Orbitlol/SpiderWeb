extends RefCounted
class_name ObjectPool

var _scene: PackedScene
var _free: Array[Node] = []
var _make: Callable


func _init(scene: PackedScene = null, maker: Callable = Callable()) -> void:
	_scene = scene
	_make = maker


func acquire(parent: Node) -> Node:
	var node: Node
	if _free.is_empty():
		if _scene:
			node = _scene.instantiate()
		else:
			node = _make.call()
	else:
		node = _free.pop_back()
	if node.get_parent() == null:
		parent.add_child(node)
	node.show()
	node.process_mode = Node.PROCESS_MODE_INHERIT
	return node


func release(node: Node) -> void:
	if node == null:
		return
	node.hide()
	if node.get_parent():
		node.get_parent().remove_child(node)
	_free.append(node)
