class_name StageData
extends Resource
## 关卡配置数据
## 定义单关的时间轴、敌人配置、Boss 等

@export var chapter: int = 1
@export var stage: int = 1
@export var duration_seconds: float = 900.0  ## 默认15分钟
@export var map_theme: StringName = &"deep_sea"

## Boss 节点时间（秒），Boss 出现时清场
@export var boss_times: Array[float] = [300.0, 600.0, 900.0]
@export var boss_enemies: Array[EnemyData] = []

## 尸潮时间（秒），短时间高密度
@export var swarm_times: Array[float] = [180.0, 480.0, 780.0]
@export var swarm_duration: float = 20.0

## 敌人配置：按时间段解锁不同敌人
@export var enemy_timeline: Array[EnemyTimelineEntry] = []

## 基础刷怪间隔（秒），随时间递减
@export var base_spawn_interval: float = 1.5
@export var min_spawn_interval: float = 0.3

## 三星条件
@export var star2_hp_percent: float = 0.5
@export var star3_hp_percent: float = 0.8
