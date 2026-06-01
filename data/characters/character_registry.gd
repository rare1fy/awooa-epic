class_name CharacterRegistry
extends RefCounted
## 角色注册表
## 所有可操控鱼人英雄的静态数据集中管理


static func get_all_characters() -> Array[Dictionary]:
	return [
		_swordfish(),
		_tidehunter(),
		_warleader(),
		_oracle(),
		_nightcrawler(),
		_stormcaller(),
	]


static func get_character(id: StringName) -> Dictionary:
	for data: Dictionary in get_all_characters():
		if data.get("id") == id:
			return data
	return {}


static func get_character_count() -> int:
	return get_all_characters().size()


## --- 角色定义 ---

## 剑鱼·突刺者 — 初始角色，平衡型
static func _swordfish() -> Dictionary:
	return {
		"id": &"swordfish",
		"name": "剑鱼·突刺者",
		"rarity": 1,
		"base_hp": 120.0,
		"base_speed": 180.0,
		"base_damage": 12.0,
		"attack_interval": 0.5,
		"attack_type": "ranged",
		"ultimate_name": "鱼叉风暴",
		"ultimate_desc": "向四周发射8根鱼叉，穿透所有敌人",
		"talent_a_name": "穿透强化",
		"talent_a_desc": "普攻穿透+1个敌人",
		"talent_b_name": "急速突刺",
		"talent_b_desc": "攻速提升30%",
		"gadget_name": "闪现跃水",
		"gadget_desc": "瞬移一小段距离，获得1秒无敌",
		"unlock_cost": 0,  # 初始免费
		"color": Color(0.3, 0.7, 1.0),
	}


## 鱼人猎潮者 — 远程穿透型
static func _tidehunter() -> Dictionary:
	return {
		"id": &"tidehunter",
		"name": "鱼人猎潮者",
		"rarity": 1,
		"base_hp": 100.0,
		"base_speed": 190.0,
		"base_damage": 14.0,
		"attack_interval": 0.6,
		"attack_type": "ranged",
		"ultimate_name": "潮汐巨浪",
		"ultimate_desc": "释放一道巨浪向前推进，击退并伤害路径上所有敌人",
		"talent_a_name": "深海压力",
		"talent_a_desc": "对减速敌人伤害+50%",
		"talent_b_name": "鱼叉连射",
		"talent_b_desc": "每次攻击发射2根鱼叉",
		"gadget_name": "水盾",
		"gadget_desc": "获得一个吸收50点伤害的护盾，持续5秒",
		"unlock_cost": 10,
		"color": Color(0.2, 0.6, 0.8),
	}


## 鱼人战争队长 — 近战冲锋型
static func _warleader() -> Dictionary:
	return {
		"id": &"warleader",
		"name": "鱼人战争队长",
		"rarity": 2,
		"base_hp": 160.0,
		"base_speed": 160.0,
		"base_damage": 18.0,
		"attack_interval": 0.8,
		"attack_type": "melee",
		"ultimate_name": "战争怒吼",
		"ultimate_desc": "全体队友攻击力+50%持续8秒，并击退周围敌人",
		"talent_a_name": "铁壁",
		"talent_a_desc": "受到伤害减少25%",
		"talent_b_name": "狂暴",
		"talent_b_desc": "血量低于50%时攻击力翻倍",
		"gadget_name": "冲锋",
		"gadget_desc": "向前冲刺，撞飞路径上的敌人",
		"unlock_cost": 20,
		"color": Color(0.3, 0.9, 0.3),
	}


## 鱼人先知 — 辅助治疗型
static func _oracle() -> Dictionary:
	return {
		"id": &"oracle",
		"name": "鱼人先知",
		"rarity": 2,
		"base_hp": 90.0,
		"base_speed": 170.0,
		"base_damage": 8.0,
		"attack_interval": 1.0,
		"attack_type": "support",
		"ultimate_name": "生命之泉",
		"ultimate_desc": "治疗自身和所有队友50%最大生命值",
		"talent_a_name": "再生之力",
		"talent_a_desc": "每秒恢复1%最大生命值",
		"talent_b_name": "灵魂链接",
		"talent_b_desc": "队友受伤时分担30%伤害给主角",
		"gadget_name": "净化",
		"gadget_desc": "移除所有减速/中毒效果，2秒免疫",
		"unlock_cost": 20,
		"color": Color(0.3, 0.8, 0.9),
	}


## 鱼人夜行者 — 近战毒伤型
static func _nightcrawler() -> Dictionary:
	return {
		"id": &"nightcrawler",
		"name": "鱼人夜行者",
		"rarity": 2,
		"base_hp": 95.0,
		"base_speed": 210.0,
		"base_damage": 10.0,
		"attack_interval": 0.35,
		"attack_type": "melee",
		"ultimate_name": "暗影突袭",
		"ultimate_desc": "隐身2秒，期间攻击力×3且无敌",
		"talent_a_name": "剧毒涂层",
		"talent_a_desc": "攻击附带持续3秒的毒伤（每秒5点）",
		"talent_b_name": "致命一击",
		"talent_b_desc": "20%概率暴击，伤害×2.5",
		"gadget_name": "烟雾弹",
		"gadget_desc": "释放烟雾，周围敌人失明2秒（停止追踪）",
		"unlock_cost": 30,
		"color": Color(0.4, 0.2, 0.6),
	}


## 鱼人风暴祭司 — 远程AOE型
static func _stormcaller() -> Dictionary:
	return {
		"id": &"stormcaller",
		"name": "鱼人风暴祭司",
		"rarity": 3,
		"base_hp": 80.0,
		"base_speed": 150.0,
		"base_damage": 20.0,
		"attack_interval": 1.2,
		"attack_type": "aoe",
		"ultimate_name": "雷霆万钧",
		"ultimate_desc": "召唤闪电风暴，全屏随机落雷10次，每次造成大量伤害",
		"talent_a_name": "连锁闪电",
		"talent_a_desc": "攻击弹射3个额外目标",
		"talent_b_name": "风暴之眼",
		"talent_b_desc": "周围持续产生伤害光环（每秒3点）",
		"gadget_name": "雷击",
		"gadget_desc": "对最近的敌人释放一道强力闪电，造成100点伤害",
		"unlock_cost": 50,
		"color": Color(0.6, 0.2, 0.9),
	}
