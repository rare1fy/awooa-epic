class_name WeightedRandom
extends RefCounted
## 加权随机选择器
## 用于招募池、掉落表等需要权重的随机选择

var _items: Array = []
var _weights: Array[float] = []
var _total_weight: float = 0.0


func add_item(item: Variant, weight: float) -> void:
	_items.append(item)
	_weights.append(weight)
	_total_weight += weight


func pick() -> Variant:
	if _items.is_empty():
		return null
	var roll := randf() * _total_weight
	var cumulative: float = 0.0
	for i: int in _items.size():
		cumulative += _weights[i]
		if roll <= cumulative:
			return _items[i]
	return _items[_items.size() - 1]


func pick_multiple(count: int, allow_duplicates: bool = false) -> Array:
	if allow_duplicates:
		var results: Array = []
		for i: int in count:
			results.append(pick())
		return results

	# 不允许重复：临时移除已选项
	var results: Array = []
	var temp_items := _items.duplicate()
	var temp_weights := _weights.duplicate()
	var temp_total := _total_weight

	for i: int in mini(count, temp_items.size()):
		var roll := randf() * temp_total
		var cumulative: float = 0.0
		for j: int in temp_items.size():
			cumulative += temp_weights[j]
			if roll <= cumulative:
				results.append(temp_items[j])
				temp_total -= temp_weights[j]
				temp_items.remove_at(j)
				temp_weights.remove_at(j)
				break
	return results


func clear() -> void:
	_items.clear()
	_weights.clear()
	_total_weight = 0.0
