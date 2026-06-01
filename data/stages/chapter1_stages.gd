class_name Chapter1Stages
extends RefCounted
## 第一章「深海觉醒」关卡配置工厂
## 4关：教学 → 渐进 → 压力 → Boss关

static func get_stage(stage_index: int) -> StageData:
	match stage_index:
		1: return _stage_1_1()
		2: return _stage_1_2()
		3: return _stage_1_3()
		4: return _stage_1_4()
		_: return _stage_1_1()


## 1-1 初遇民兵（教学关，8分钟，只有冲锋兵）
static func _stage_1_1() -> StageData:
	var data := StageData.new()
	data.chapter = 1
	data.stage = 1
	data.duration_seconds = 480.0  # 8分钟
	data.map_theme = &"deep_sea"
	data.boss_times = [480.0]  # 只有最终Boss
	data.swarm_times = [300.0]  # 5分钟一次尸潮（给玩家更多发育时间）
	data.swarm_duration = 12.0  # 尸潮短一些
	data.base_spawn_interval = 2.0  # 刷怪更慢
	data.min_spawn_interval = 0.6  # 最快也不太密
	data.star2_hp_percent = 0.5
	data.star3_hp_percent = 0.8
	return data


## 1-2 渔村前哨（10分钟，加入火枪手环绕兵）
static func _stage_1_2() -> StageData:
	var data := StageData.new()
	data.chapter = 1
	data.stage = 2
	data.duration_seconds = 600.0  # 10分钟
	data.map_theme = &"coastal"
	data.boss_times = [300.0, 600.0]  # 5分钟中Boss + 10分钟最终Boss
	data.swarm_times = [180.0, 420.0]
	data.swarm_duration = 18.0
	data.base_spawn_interval = 1.5
	data.min_spawn_interval = 0.4
	data.star2_hp_percent = 0.5
	data.star3_hp_percent = 0.8
	return data


## 1-3 海岸突围（12分钟，加入弓箭手远程兵）
static func _stage_1_3() -> StageData:
	var data := StageData.new()
	data.chapter = 1
	data.stage = 3
	data.duration_seconds = 720.0  # 12分钟
	data.map_theme = &"coastal"
	data.boss_times = [360.0, 720.0]
	data.swarm_times = [180.0, 480.0, 600.0]
	data.swarm_duration = 20.0
	data.base_spawn_interval = 1.3
	data.min_spawn_interval = 0.35
	data.star2_hp_percent = 0.5
	data.star3_hp_percent = 0.8
	return data


## 1-4 老船长布莱恩（Boss关，15分钟，完整三Boss节奏）
static func _stage_1_4() -> StageData:
	var data := StageData.new()
	data.chapter = 1
	data.stage = 4
	data.duration_seconds = 900.0  # 15分钟
	data.map_theme = &"coastal"
	data.boss_times = [300.0, 600.0, 900.0]
	data.swarm_times = [180.0, 480.0, 780.0]
	data.swarm_duration = 20.0
	data.base_spawn_interval = 1.2
	data.min_spawn_interval = 0.3
	data.star2_hp_percent = 0.5
	data.star3_hp_percent = 0.8
	return data
