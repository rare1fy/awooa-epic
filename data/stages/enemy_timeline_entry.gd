class_name EnemyTimelineEntry
extends Resource
## 敌人时间轴条目
## 定义某个时间点开始出现某种敌人

@export var unlock_time: float = 0.0  ## 从第几秒开始出现
@export var enemy: EnemyData
@export var spawn_weight: int = 10  ## 刷新权重（越高越常见）
@export var max_concurrent: int = 50  ## 同时存在上限
