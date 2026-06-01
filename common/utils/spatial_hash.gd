class_name SpatialHash
extends RefCounted
## 空间哈希网格
## 用于高效的碰撞检测，替代 Godot 物理引擎

var _cell_size: float
var _grid: Dictionary = {}  # Dictionary[Vector2i, Array[Node2D]]


func _init(cell_size: float = 64.0) -> void:
	_cell_size = cell_size


func clear() -> void:
	_grid.clear()


func insert(node: Node2D) -> void:
	var cell := _get_cell(node.global_position)
	if not _grid.has(cell):
		_grid[cell] = []
	_grid[cell].append(node)


func query_radius(center: Vector2, radius: float) -> Array[Node2D]:
	var results: Array[Node2D] = []
	var radius_sq := radius * radius
	var min_cell := _get_cell(center - Vector2(radius, radius))
	var max_cell := _get_cell(center + Vector2(radius, radius))

	for x: int in range(min_cell.x, max_cell.x + 1):
		for y: int in range(min_cell.y, max_cell.y + 1):
			var cell := Vector2i(x, y)
			if _grid.has(cell):
				for node: Node2D in _grid[cell]:
					if center.distance_squared_to(node.global_position) <= radius_sq:
						results.append(node)
	return results


func query_nearest(center: Vector2, radius: float) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist_sq := radius * radius
	var min_cell := _get_cell(center - Vector2(radius, radius))
	var max_cell := _get_cell(center + Vector2(radius, radius))

	for x: int in range(min_cell.x, max_cell.x + 1):
		for y: int in range(min_cell.y, max_cell.y + 1):
			var cell := Vector2i(x, y)
			if _grid.has(cell):
				for node: Node2D in _grid[cell]:
					var dist_sq := center.distance_squared_to(node.global_position)
					if dist_sq < nearest_dist_sq:
						nearest_dist_sq = dist_sq
						nearest = node
	return nearest


func _get_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(pos.x / _cell_size),
		floori(pos.y / _cell_size)
	)
