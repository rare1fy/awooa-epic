class_name WeaponData
extends Resource
## 武器/被动数据定义（数据驱动）
## 一把武器从 1 级升到 max_level，每级数值由基础值 + 每级增量推算

enum Kind {
	WEAPON,   ## 主动武器（自动攻击）
	PASSIVE,  ## 被动道具（属性加成）
}

## 武器攻击模式（仅 WEAPON 用）
enum WeaponType {
	PROJECTILE,   ## 直线弹道（飞鱼镖 / 飞刀）
	WHIP,         ## 左右横扫扇形（鞭子）
	ORBIT,        ## 环绕旋转弹体（圣经 / 贝壳）
	AURA,         ## 贴身持续 AOE 光环（大蒜）
	LIGHTNING,    ## 随机劈附近敌人（闪电）
	BOOMERANG,    ## 抛物线飞出返回（回旋镖 / 斧头）
	HOMING,       ## 自动锁定追踪弹（魔杖 / 导弹）
	GROUND_AREA,  ## 地面落点持续伤害区（圣水）
	GARLIC_RING,  ## 环形扩散冲击波（十字镖 / 钻石）
	SHIELD,       ## 防御反伤光环（护盾）
	BIBLE_LASER,  ## 朝面向发射激光柱（激光）
	FOLLOW_FAMILIAR,  ## 跟随召唤物攻击（猫 / 鸟）
}

## 被动加成类型（仅 PASSIVE 用）
enum PassiveType {
	DAMAGE,        ## 伤害 +%
	ATTACK_SPEED,  ## 攻速 +%（冷却减少）
	MOVE_SPEED,    ## 移速 +%
	MAX_HP,        ## 最大生命 +%
	AREA,          ## 范围 +%
	PROJECTILE_SPEED,  ## 弹速 +%
	PICKUP_RANGE,  ## 拾取范围 +%
	AMOUNT,        ## 投射物数量 +1
	COOLDOWN,      ## 冷却 -%
	LUCK,          ## 幸运（掉落 / 暴击）
	GREED,         ## 金币获取 +%
	REVIVAL,       ## 复活次数 +1
}

@export var id: StringName = &""
@export var display_name: String = "武器"
@export var description: String = ""
@export var kind: Kind = Kind.WEAPON
@export var color: Color = Color(0.4, 0.8, 1.0)
@export var max_level: int = 8

## --- WEAPON 字段 ---
@export var weapon_type: WeaponType = WeaponType.PROJECTILE
@export var base_damage: float = 10.0
@export var damage_per_level: float = 4.0
@export var base_cooldown: float = 1.0      ## 攻击间隔（秒）
@export var cooldown_per_level: float = -0.05  ## 每级冷却变化（通常为负=变快）
@export var base_amount: int = 1            ## 投射物 / 命中数量
@export var amount_per_levels: PackedInt32Array = []  ## 在第几级 +1 数量
@export var base_area: float = 1.0          ## 范围倍率
@export var area_per_level: float = 0.08
@export var base_speed: float = 400.0       ## 弹速
@export var pierce: int = 0                 ## 穿透次数
@export var base_duration: float = 1.0      ## 持续时间（光环 / 地面区）

## --- PASSIVE 字段 ---
@export var passive_type: PassiveType = PassiveType.DAMAGE
@export var passive_per_level: float = 0.1  ## 每级加成（百分比或绝对值）

## --- 进化 ---
@export var evolves_into: StringName = &""        ## 进化后的武器 id（空=不可进化）
@export var evolution_requires: StringName = &""  ## 需要满级的被动 id（空=仅需武器满级）
@export var is_evolved: bool = false              ## 是否为进化形态（不出现在升级池）


## 计算指定等级的伤害
func get_damage(level: int) -> float:
	return base_damage + damage_per_level * float(level - 1)


## 计算指定等级的冷却（攻击间隔），不低于 0.1
func get_cooldown(level: int) -> float:
	return maxf(0.1, base_cooldown + cooldown_per_level * float(level - 1))


## 计算指定等级的投射物数量
func get_amount(level: int) -> int:
	var amount := base_amount
	for lv: int in amount_per_levels:
		if level >= lv:
			amount += 1
	return amount


## 计算指定等级的范围倍率
func get_area(level: int) -> float:
	return base_area + area_per_level * float(level - 1)
