class_name CharacterData
extends Resource
## 主角鱼人数据定义
## 每个可操控的鱼人英雄的静态数据

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export_range(1, 3) var rarity: int = 1  ## 1=普通 2=稀有 3=史诗
@export var base_hp: float = 100.0
@export var base_speed: float = 200.0
@export var base_damage: float = 10.0
@export var attack_interval: float = 0.5
@export var attack_scene: PackedScene  ## 攻击行为场景
@export var ultimate_scene: PackedScene  ## 大招行为场景
@export_multiline var ultimate_description: String
@export var talent_a: TalentData
@export var talent_b: TalentData
@export var gadget: GadgetData
@export var super_talent: TalentData
@export var unlock_cost: int = 10  ## 碎片数量
