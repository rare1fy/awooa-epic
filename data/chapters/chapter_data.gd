class_name ChapterData
extends Resource
## 章节配置数据

@export var chapter_id: int = 1
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var stages: Array[StageData] = []
@export var unlock_condition_stars: int = 0  ## 需要前面章节累计多少星解锁
@export var chest_thresholds: Array[int] = [6, 9, 12]  ## 星数宝箱阈值
