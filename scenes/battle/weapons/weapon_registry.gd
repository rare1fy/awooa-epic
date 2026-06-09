class_name WeaponRegistry
extends RefCounted
## 武器注册表（静态缓存）
## 首次访问时从 WeaponDB 构建全部武器/进化/被动，按 id 建索引供全局查询

static var _all: Dictionary = {}            ## id -> WeaponData（含进化）
static var _pool_weapons: Array[WeaponData] = []  ## 可出现在升级池的武器
static var _pool_passives: Array[WeaponData] = []  ## 可出现在升级池的被动
static var _built: bool = false


static func _ensure_built() -> void:
	if _built:
		return
	_built = true
	for w: WeaponData in WeaponDB.build_weapons():
		_all[w.id] = w
		_pool_weapons.append(w)
	for e: WeaponData in WeaponDB.build_evolutions():
		_all[e.id] = e
	for p: WeaponData in WeaponDB.build_passives():
		_all[p.id] = p
		_pool_passives.append(p)


static func get_weapon(id: StringName) -> WeaponData:
	_ensure_built()
	return _all.get(id, null)


static func get_pool_weapons() -> Array[WeaponData]:
	_ensure_built()
	return _pool_weapons


static func get_pool_passives() -> Array[WeaponData]:
	_ensure_built()
	return _pool_passives
