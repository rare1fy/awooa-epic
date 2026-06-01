class_name AudioManagerClass
extends Node
## 音频管理器
## 管理 BGM 和 SFX 播放，处理前后台切换时的暂停/恢复

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

const MAX_SFX_PLAYERS := 8


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = &"Music"
	add_child(_bgm_player)

	for i: int in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)

	_setup_visibility_handlers()


func play_bgm(stream: AudioStream) -> void:
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stream = stream
	_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()


func play_sfx(stream: AudioStream) -> void:
	for player: AudioStreamPlayer in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return


func _setup_visibility_handlers() -> void:
	if OS.has_feature("web"):
		get_tree().root.focus_exited.connect(_on_focus_lost)
		get_tree().root.focus_entered.connect(_on_focus_gained)


func _on_focus_lost() -> void:
	_bgm_player.stream_paused = true


func _on_focus_gained() -> void:
	_bgm_player.stream_paused = false
