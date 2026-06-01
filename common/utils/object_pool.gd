class_name ObjectPool
extends RefCounted
## 通用对象池
## 用于子弹、敌人、拾取物等高频创建/销毁的对象

var _scene: PackedScene
var _pool: Array[Node] = []
var _parent: Node


func _init(scene: PackedScene, parent: Node, preload_count: int = 0) -> void:
	_scene = scene
	_parent = parent
	for i: int in preload_count:
		var instance := _scene.instantiate()
		instance.set_process(false)
		instance.set_physics_process(false)
		instance.visible = false
		_parent.add_child(instance)
		_pool.append(instance)


func acquire() -> Node:
	var instance: Node
	if _pool.size() > 0:
		instance = _pool.pop_back()
	else:
		instance = _scene.instantiate()
		_parent.add_child(instance)
	instance.set_process(true)
	instance.set_physics_process(true)
	instance.visible = true
	return instance


func release(instance: Node) -> void:
	instance.set_process(false)
	instance.set_physics_process(false)
	instance.visible = false
	_pool.append(instance)


func get_active_count() -> int:
	var total: int = _parent.get_child_count()
	return total - _pool.size()
