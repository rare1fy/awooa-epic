class_name GadgetData
extends Resource
## 妙具数据定义

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var max_uses_per_stage: int = 3
@export var cooldown: float = 10.0
