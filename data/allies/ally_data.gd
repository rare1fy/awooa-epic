class_name AllyData
extends Resource
## 队友鱼人数据定义
## 局内可招募的队友静态数据

enum AttackType {
	MELEE,      ## 近战：直接扣血
	RANGED,     ## 远程：发射普通弹道
	SUPPORT,    ## 辅助：治疗/增益
	TRAP,       ## 陷阱：放置地面效果
	AOE,        ## 范围：攻击命中多个目标
	CHAIN,      ## 连锁：弹射多个目标
}

## 特殊效果
enum SpecialEffect {
	NONE,
	PIERCE,     ## 穿透（弹道穿过多个敌人）
	SLOW,       ## 减速（命中后减速敌人）
	POISON,     ## 中毒（持续伤害）
	KNOCKBACK,  ## 击退
	HEAL_AURA,  ## 治疗光环（周期性治疗主角）
	EXPLODE,    ## 爆炸（弹道命中后 AOE）
	CHAIN_LIGHTNING, ## 连锁闪电（弹射 3 目标）
}

@export var id: StringName
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var attack_type: AttackType = AttackType.RANGED
@export var special_effect: SpecialEffect = SpecialEffect.NONE
@export var base_damage: float = 8.0
@export var attack_interval: float = 1.0
@export var attack_scene: PackedScene
@export var preferred_distance: float = 80.0
@export var pool_weight: int = 10
@export var color: Color = Color(0.3, 0.8, 1.0, 1.0)

## 特效参数
@export var pierce_count: int = 2
@export var slow_percent: float = 0.4
@export var slow_duration: float = 2.0
@export var poison_dps: float = 3.0
@export var poison_duration: float = 3.0
@export var knockback_force: float = 150.0
@export var heal_amount: float = 2.0
@export var heal_interval: float = 3.0
@export var explode_radius: float = 60.0
@export var chain_targets: int = 3

@export_multiline var star2_description: String
@export_multiline var star3_description: String
