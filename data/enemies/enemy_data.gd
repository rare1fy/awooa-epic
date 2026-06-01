class_name EnemyData
extends Resource
## 敌人数据定义

enum BehaviorType {
	CHARGE,     ## 直线冲锋（默认）
	RANGED,     ## 远程射击（保持距离发射弹道）
	CIRCLE,     ## 环绕走位（绕玩家转圈靠近）
	SPLIT,      ## 分裂（死亡时分裂为小怪）
	DASH,       ## 冲刺（间歇性高速冲刺）
	TANK,       ## 坦克（缓慢但高血高甲，击退抗性）
}

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var scene: PackedScene
@export var behavior: BehaviorType = BehaviorType.CHARGE
@export var base_hp: float = 20.0
@export var base_damage: float = 5.0
@export var speed: float = 80.0
@export var exp_drop: int = 1
@export var is_elite: bool = false
@export var color: Color = Color(0.8, 0.2, 0.2, 1.0)
@export var scale_mult: float = 1.0  ## 体型倍率

## 远程敌人专用
@export var projectile_speed: float = 200.0
@export var attack_range: float = 180.0
@export var attack_interval: float = 2.0

## 分裂敌人专用
@export var split_count: int = 2
@export var split_hp_ratio: float = 0.3

## 冲刺敌人专用
@export var dash_speed_mult: float = 3.0
@export var dash_interval: float = 3.0
@export var dash_duration: float = 0.4
