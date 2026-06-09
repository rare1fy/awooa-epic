class_name WeaponDB
extends RefCounted
## 武器/被动数据库（VS 全武器换皮 + 被动 + 进化表）
## 静态构建，集中定义所有可获取的武器与被动

## --- 内部构造助手 ---

static func _w(id: StringName, name: String, desc: String, color: Color,
		wtype: WeaponData.WeaponType, dmg: float, dmg_pl: float,
		cd: float, cd_pl: float, amount: int) -> WeaponData:
	var d := WeaponData.new()
	d.id = id
	d.display_name = name
	d.description = desc
	d.color = color
	d.kind = WeaponData.Kind.WEAPON
	d.weapon_type = wtype
	d.base_damage = dmg
	d.damage_per_level = dmg_pl
	d.base_cooldown = cd
	d.cooldown_per_level = cd_pl
	d.base_amount = amount
	return d


static func _p(id: StringName, name: String, desc: String, color: Color,
		ptype: WeaponData.PassiveType, per_level: float, max_lv: int = 5) -> WeaponData:
	var d := WeaponData.new()
	d.id = id
	d.display_name = name
	d.description = desc
	d.color = color
	d.kind = WeaponData.Kind.PASSIVE
	d.passive_type = ptype
	d.passive_per_level = per_level
	d.max_level = max_lv
	return d


## --- 18 把武器（VS 换皮，鱼人/深海主题）---

static func build_weapons() -> Array[WeaponData]:
	var list: Array[WeaponData] = []

	# 1. 飞鱼镖（飞刀 Knife）— 朝面向连发直线穿透
	var w_dagger := _w(&"flying_dagger", "飞鱼镖", "朝面向高速连射，可穿透",
		Color(0.7, 0.9, 1.0), WeaponData.WeaponType.PROJECTILE, 8.0, 3.0, 0.5, -0.03, 1)
	w_dagger.amount_per_levels = PackedInt32Array([2, 4, 6, 8])
	w_dagger.pierce = 1
	w_dagger.base_speed = 520.0
	w_dagger.evolves_into = &"thousand_fins"
	w_dagger.evolution_requires = &"fin_bracer"
	list.append(w_dagger)

	# 2. 潮汐鞭（鞭子 Whip）— 左右横扫扇形
	var w_whip := _w(&"tide_whip", "潮汐鞭", "左右横扫，攻击身侧敌人",
		Color(0.3, 0.7, 1.0), WeaponData.WeaponType.WHIP, 12.0, 5.0, 1.0, -0.04, 1)
	w_whip.amount_per_levels = PackedInt32Array([3, 5, 7])
	w_whip.base_area = 1.0
	w_whip.evolves_into = &"bloodtide"
	w_whip.evolution_requires = &"hollow_heart"
	list.append(w_whip)

	# 3. 环绕贝壳（圣经 King Bible）— 绕身旋转弹体
	var w_orbit := _w(&"orbit_shell", "环绕贝壳", "贝壳绕身旋转，碰撞伤敌",
		Color(0.9, 0.8, 0.5), WeaponData.WeaponType.ORBIT, 10.0, 4.0, 3.0, 0.0, 1)
	w_orbit.amount_per_levels = PackedInt32Array([2, 3, 4, 5, 6])
	w_orbit.base_area = 1.0
	w_orbit.base_duration = 3.0
	w_orbit.evolves_into = &"tide_scripture"
	w_orbit.evolution_requires = &"spinach"
	list.append(w_orbit)

	# 4. 海毒雾（大蒜 Garlic）— 贴身持续 AOE 光环
	var w_garlic := _w(&"sea_miasma", "海毒雾", "环身毒雾，持续灼烧近敌",
		Color(0.4, 0.9, 0.3), WeaponData.WeaponType.AURA, 5.0, 2.0, 0.6, -0.02, 1)
	w_garlic.base_area = 1.0
	w_garlic.area_per_level = 0.12
	w_garlic.evolves_into = &"abyss_breath"
	w_garlic.evolution_requires = &"pummarola"
	list.append(w_garlic)

	# 5. 闪电链（闪电法球 Lightning Ring）— 随机劈附近敌人
	var w_lightning := _w(&"lightning_chain", "闪电链", "随机劈击附近敌人",
		Color(0.6, 0.4, 1.0), WeaponData.WeaponType.LIGHTNING, 18.0, 7.0, 2.0, -0.06, 1)
	w_lightning.amount_per_levels = PackedInt32Array([3, 5, 7])
	w_lightning.evolves_into = &"thunder_storm"
	w_lightning.evolution_requires = &"duplicator"
	list.append(w_lightning)

	# 6. 回旋鳍刃（斧头 Axe / 回旋镖）— 抛物线飞出返回
	var w_boomerang := _w(&"fin_boomerang", "回旋鳍刃", "抛物飞出再返回，穿透多敌",
		Color(0.8, 0.6, 0.3), WeaponData.WeaponType.BOOMERANG, 20.0, 8.0, 1.5, -0.05, 1)
	w_boomerang.amount_per_levels = PackedInt32Array([3, 5, 7])
	w_boomerang.pierce = 999
	w_boomerang.base_speed = 380.0
	w_boomerang.evolves_into = &"death_spiral"
	w_boomerang.evolution_requires = &"candelabra"
	list.append(w_boomerang)

	# 7. 深海导弹（魔杖 Magic Wand）— 自动锁定追踪
	var w_homing := _w(&"abyss_missile", "深海导弹", "自动锁定最近敌人追踪",
		Color(0.5, 0.8, 0.9), WeaponData.WeaponType.HOMING, 10.0, 4.0, 1.2, -0.04, 1)
	w_homing.amount_per_levels = PackedInt32Array([2, 3, 5, 7])
	w_homing.base_speed = 360.0
	w_homing.evolves_into = &"holy_torrent"
	w_homing.evolution_requires = &"empty_tome"
	list.append(w_homing)

	# 8. 圣水池（圣水 Santa Water）— 地面落点持续伤害区
	var w_water := _w(&"holy_pool", "圣水池", "随机落点形成灼伤水池",
		Color(0.3, 0.6, 1.0), WeaponData.WeaponType.GROUND_AREA, 8.0, 3.0, 2.5, -0.08, 1)
	w_water.amount_per_levels = PackedInt32Array([2, 4, 6])
	w_water.base_area = 1.0
	w_water.base_duration = 2.5
	w_water.evolves_into = &"la_borra"
	w_water.evolution_requires = &"attractorb"
	list.append(w_water)

	# 9. 十字回镖（十字镖 Cross）— 环形扩散十字弹
	var w_cross := _w(&"trident_cross", "三叉回镖", "十字飞出可返回追踪",
		Color(1.0, 0.9, 0.4), WeaponData.WeaponType.GARLIC_RING, 14.0, 5.0, 1.8, -0.05, 1)
	w_cross.amount_per_levels = PackedInt32Array([2, 4, 6])
	w_cross.base_speed = 340.0
	w_cross.evolves_into = &"heaven_sword"
	w_cross.evolution_requires = &"clover"
	list.append(w_cross)

	# 10. 守护漩涡（钻石 Pentagram 化简为环形清屏波）— 周期环形冲击
	var w_ring := _w(&"guard_vortex", "守护漩涡", "周期释放扩散冲击波",
		Color(0.7, 0.5, 1.0), WeaponData.WeaponType.GARLIC_RING, 16.0, 6.0, 2.2, -0.04, 1)
	w_ring.amount_per_levels = PackedInt32Array([4, 7])
	w_ring.base_area = 1.2
	w_ring.area_per_level = 0.15
	list.append(w_ring)

	# 11. 深海护盾（护盾 Shield/Laurel）— 防御反伤光环
	var w_shield := _w(&"abyss_shield", "深海护盾", "环身护盾，撞击反伤",
		Color(0.4, 0.7, 0.8), WeaponData.WeaponType.SHIELD, 6.0, 2.0, 0.5, 0.0, 1)
	w_shield.base_area = 1.0
	w_shield.area_per_level = 0.1
	list.append(w_shield)

	# 12. 潮光激光（激光 Laurel/Phiera 化为激光柱）— 朝面向射激光
	var w_laser := _w(&"tide_laser", "潮光激光", "朝面向持续射出光柱",
		Color(0.5, 1.0, 0.9), WeaponData.WeaponType.BIBLE_LASER, 9.0, 3.5, 0.9, -0.03, 1)
	w_laser.amount_per_levels = PackedInt32Array([3, 5, 7])
	w_laser.base_speed = 700.0
	w_laser.pierce = 3
	list.append(w_laser)

	# 13. 召唤海灵（猫 Cat / 鸟 Bird）— 跟随召唤物
	var w_familiar := _w(&"sea_spirit", "召唤海灵", "召唤海灵环绕扑咬敌人",
		Color(0.6, 0.9, 1.0), WeaponData.WeaponType.FOLLOW_FAMILIAR, 12.0, 4.0, 1.5, -0.04, 1)
	w_familiar.amount_per_levels = PackedInt32Array([3, 5, 7])
	list.append(w_familiar)

	# 14. 散弹贝（霰弹 Phieraggi 化为扇形散射）— 扇形多弹
	var w_spread := _w(&"shell_spread", "散弹贝", "向面向扇形喷射弹片",
		Color(0.9, 0.7, 0.5), WeaponData.WeaponType.PROJECTILE, 7.0, 2.5, 0.8, -0.03, 3)
	w_spread.amount_per_levels = PackedInt32Array([4, 6, 8])
	w_spread.base_speed = 480.0
	w_spread.pierce = 0
	list.append(w_spread)

	# 15. 旋刃涡流（旋风 Song of Mana 化为持续旋切）— 上下贯穿光柱
	var w_pillar := _w(&"vortex_blade", "旋刃涡流", "上下贯穿的水刃光柱",
		Color(0.4, 0.8, 1.0), WeaponData.WeaponType.BIBLE_LASER, 11.0, 4.0, 2.0, -0.05, 1)
	w_pillar.amount_per_levels = PackedInt32Array([4, 7])
	w_pillar.base_speed = 600.0
	w_pillar.pierce = 999
	list.append(w_pillar)

	# 16. 火山喷泉（火山 化为地面爆点）— 随机地面爆炸
	var w_volcano := _w(&"sea_geyser", "海底喷泉", "随机地面喷发爆炸",
		Color(1.0, 0.5, 0.3), WeaponData.WeaponType.GROUND_AREA, 22.0, 8.0, 3.0, -0.1, 1)
	w_volcano.amount_per_levels = PackedInt32Array([3, 5, 7])
	w_volcano.base_area = 1.1
	w_volcano.base_duration = 0.6
	list.append(w_volcano)

	# 17. 寒冰新星（圣水变体 / 冰 化为减速环）— 环形冰冻
	var w_frost := _w(&"frost_nova", "寒冰新星", "环身冰爆，伤害并减速",
		Color(0.6, 0.9, 1.0), WeaponData.WeaponType.GARLIC_RING, 13.0, 5.0, 2.6, -0.06, 1)
	w_frost.amount_per_levels = PackedInt32Array([4, 7])
	w_frost.base_area = 1.1
	list.append(w_frost)

	# 18. 幽冥之书（圣经变体 / 死亡螺旋）— 大范围环绕镰刃
	var w_grimoire := _w(&"abyss_grimoire", "幽冥之书", "环绕的幽冥镰刃，大范围",
		Color(0.5, 0.3, 0.7), WeaponData.WeaponType.ORBIT, 15.0, 6.0, 3.5, 0.0, 1)
	w_grimoire.amount_per_levels = PackedInt32Array([2, 4, 6])
	w_grimoire.base_area = 1.4
	w_grimoire.base_duration = 4.0
	list.append(w_grimoire)

	return list


## --- 进化武器（不出现在升级池，满足条件时由武器替换升级得到）---

static func build_evolutions() -> Array[WeaponData]:
	var list: Array[WeaponData] = []

	var e_thousand := _w(&"thousand_fins", "千鳍刃", "进化：面前飞鱼镖加特林",
		Color(0.8, 1.0, 1.0), WeaponData.WeaponType.PROJECTILE, 22.0, 0.0, 0.12, 0.0, 6)
	e_thousand.pierce = 2
	e_thousand.base_speed = 600.0
	e_thousand.is_evolved = true
	e_thousand.max_level = 1
	list.append(e_thousand)

	var e_bloodtide := _w(&"bloodtide", "血潮鞭", "进化：横扫并吸血",
		Color(0.9, 0.2, 0.3), WeaponData.WeaponType.WHIP, 30.0, 0.0, 0.5, 0.0, 6)
	e_bloodtide.base_area = 1.6
	e_bloodtide.is_evolved = true
	e_bloodtide.max_level = 1
	list.append(e_bloodtide)

	var e_scripture := _w(&"tide_scripture", "潮汐圣典", "进化：无限环绕贝壳",
		Color(1.0, 0.95, 0.6), WeaponData.WeaponType.ORBIT, 28.0, 0.0, 3.0, 0.0, 8)
	e_scripture.base_area = 1.5
	e_scripture.base_duration = 999.0
	e_scripture.is_evolved = true
	e_scripture.max_level = 1
	list.append(e_scripture)

	var e_abyss_breath := _w(&"abyss_breath", "深渊吐息", "进化：巨型毒雾光环",
		Color(0.3, 1.0, 0.4), WeaponData.WeaponType.AURA, 14.0, 0.0, 0.4, 0.0, 1)
	e_abyss_breath.base_area = 2.2
	e_abyss_breath.is_evolved = true
	e_abyss_breath.max_level = 1
	list.append(e_abyss_breath)

	var e_thunder := _w(&"thunder_storm", "雷暴", "进化：连续闪电风暴",
		Color(0.7, 0.5, 1.0), WeaponData.WeaponType.LIGHTNING, 40.0, 0.0, 0.8, 0.0, 9)
	e_thunder.is_evolved = true
	e_thunder.max_level = 1
	list.append(e_thunder)

	var e_death_spiral := _w(&"death_spiral", "死亡螺旋", "进化：360度穿透镰刃",
		Color(0.9, 0.7, 0.2), WeaponData.WeaponType.BOOMERANG, 45.0, 0.0, 0.9, 0.0, 8)
	e_death_spiral.pierce = 999
	e_death_spiral.base_speed = 420.0
	e_death_spiral.is_evolved = true
	e_death_spiral.max_level = 1
	list.append(e_death_spiral)

	var e_holy_torrent := _w(&"holy_torrent", "圣潮急流", "进化：海量追踪导弹",
		Color(0.6, 0.9, 1.0), WeaponData.WeaponType.HOMING, 24.0, 0.0, 0.4, 0.0, 9)
	e_holy_torrent.base_speed = 420.0
	e_holy_torrent.is_evolved = true
	e_holy_torrent.max_level = 1
	list.append(e_holy_torrent)

	var e_la_borra := _w(&"la_borra", "深渊泥沼", "进化：移动的巨型水池",
		Color(0.4, 0.7, 1.0), WeaponData.WeaponType.GROUND_AREA, 20.0, 0.0, 1.5, 0.0, 8)
	e_la_borra.base_area = 1.8
	e_la_borra.base_duration = 3.5
	e_la_borra.is_evolved = true
	e_la_borra.max_level = 1
	list.append(e_la_borra)

	var e_heaven_sword := _w(&"heaven_sword", "天堂之刃", "进化：环绕十字剑阵",
		Color(1.0, 1.0, 0.6), WeaponData.WeaponType.GARLIC_RING, 35.0, 0.0, 1.2, 0.0, 8)
	e_heaven_sword.base_area = 1.6
	e_heaven_sword.is_evolved = true
	e_heaven_sword.max_level = 1
	list.append(e_heaven_sword)

	return list


## --- 全套被动 ---

static func build_passives() -> Array[WeaponData]:
	var list: Array[WeaponData] = []
	list.append(_p(&"spinach", "菠菜", "伤害 +10%/级", Color(0.3, 0.8, 0.3),
		WeaponData.PassiveType.DAMAGE, 0.10))
	list.append(_p(&"empty_tome", "空白之书", "冷却 -8%/级", Color(0.6, 0.6, 0.9),
		WeaponData.PassiveType.COOLDOWN, 0.08))
	list.append(_p(&"candelabra", "烛台", "范围 +10%/级", Color(0.9, 0.8, 0.4),
		WeaponData.PassiveType.AREA, 0.10))
	list.append(_p(&"bracer", "护腕", "弹速 +10%/级", Color(0.7, 0.7, 0.7),
		WeaponData.PassiveType.PROJECTILE_SPEED, 0.10))
	list.append(_p(&"fin_bracer", "鱼鳍护腕", "弹速 +12%/级", Color(0.5, 0.8, 0.9),
		WeaponData.PassiveType.PROJECTILE_SPEED, 0.12))
	list.append(_p(&"spellbinder", "咒缚", "效果持续 +10%/级", Color(0.8, 0.5, 0.9),
		WeaponData.PassiveType.AREA, 0.08))
	list.append(_p(&"duplicator", "复制器", "投射物 +1（少量等级）", Color(1.0, 0.7, 0.3),
		WeaponData.PassiveType.AMOUNT, 1.0, 2))
	list.append(_p(&"empty_heart", "空虚之心", "最大生命 +10%/级", Color(0.9, 0.3, 0.4),
		WeaponData.PassiveType.MAX_HP, 0.10))
	list.append(_p(&"hollow_heart", "空心之心", "最大生命 +15%/级", Color(0.9, 0.2, 0.3),
		WeaponData.PassiveType.MAX_HP, 0.15))
	list.append(_p(&"pummarola", "番茄", "回血加成（持续 +0.2/级）", Color(0.9, 0.3, 0.2),
		WeaponData.PassiveType.MAX_HP, 0.05))
	list.append(_p(&"wings", "翅膀", "移速 +10%/级", Color(0.8, 0.9, 1.0),
		WeaponData.PassiveType.MOVE_SPEED, 0.10))
	list.append(_p(&"attractorb", "吸引宝珠", "拾取范围 +25%/级", Color(0.5, 0.7, 1.0),
		WeaponData.PassiveType.PICKUP_RANGE, 0.25))
	list.append(_p(&"clover", "三叶草", "幸运 +10%/级", Color(0.3, 0.9, 0.4),
		WeaponData.PassiveType.LUCK, 0.10))
	list.append(_p(&"crown", "皇冠", "经验获取 +8%/级", Color(1.0, 0.9, 0.3),
		WeaponData.PassiveType.GREED, 0.08))
	list.append(_p(&"stone_heart", "重生石", "复活 +1（仅1级）", Color(0.7, 0.7, 0.8),
		WeaponData.PassiveType.REVIVAL, 1.0, 1))
	list.append(_p(&"greed_purse", "贪婪钱袋", "金币 +20%/级", Color(1.0, 0.85, 0.2),
		WeaponData.PassiveType.GREED, 0.20))
	return list
