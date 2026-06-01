class_name StageRegistry
extends RefCounted
## 关卡注册表
## 统一入口获取任意章节任意关的 StageData

## 每章的关卡数量
const STAGES_PER_CHAPTER: Dictionary = {
	1: 4,
	2: 5,
	3: 5,
	4: 5,
	5: 5,
}

const CHAPTER_NAMES: Dictionary = {
	1: "深海觉醒",
	2: "沿海渔村",
	3: "平原城镇",
	4: "圣殿山脉",
	5: "人类王城",
}

const STAGE_NAMES: Dictionary = {
	# 第一章
	"1_1": "初遇民兵",
	"1_2": "渔村前哨",
	"1_3": "海岸突围",
	"1_4": "老船长布莱恩",
	# 后续章节 TODO
}


static func get_stage_data(chapter: int, stage: int) -> StageData:
	match chapter:
		1: return Chapter1Stages.get_stage(stage)
		# 2: return Chapter2Stages.get_stage(stage)
		_:
			# 未实现的章节返回默认配置
			var data := StageData.new()
			data.chapter = chapter
			data.stage = stage
			return data


static func get_stage_count(chapter: int) -> int:
	return STAGES_PER_CHAPTER.get(chapter, 4) as int


static func get_chapter_name(chapter: int) -> String:
	return CHAPTER_NAMES.get(chapter, "未知") as String


static func get_stage_name(chapter: int, stage: int) -> String:
	var key := "%d_%d" % [chapter, stage]
	return STAGE_NAMES.get(key, "第%d关" % stage) as String


static func is_stage_unlocked(chapter: int, stage: int) -> bool:
	# 第一关永远解锁
	if chapter == 1 and stage == 1:
		return true
	# 同章节：前一关至少1星
	if stage > 1:
		return SaveManager.get_stage_stars(chapter, stage - 1) >= 1
	# 新章节第一关：前一章最后一关至少1星
	var prev_chapter := chapter - 1
	var prev_last_stage := get_stage_count(prev_chapter)
	return SaveManager.get_stage_stars(prev_chapter, prev_last_stage) >= 1
