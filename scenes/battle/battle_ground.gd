class_name BattleGround
extends Node2D
## 战斗场景地面背景
## 生成网格纹理，让玩家能感知移动

@export var grid_size: int = 64  ## 网格间距（像素）
@export var grid_color: Color = Color(0.15, 0.18, 0.25, 1.0)  ## 网格线颜色
@export var bg_color: Color = Color(0.08, 0.1, 0.14, 1.0)  ## 背景色
@export var map_size: Vector2 = Vector2(4000, 4000)  ## 地图总大小

var _texture: ImageTexture


func _ready() -> void:
	_generate_ground_texture()


func _generate_ground_texture() -> void:
	# 生成一个 tile 大小的纹理，然后用 TextureRect 平铺
	var tile_size: int = grid_size * 4  # 256px tile
	var img := Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)

	# 填充背景
	img.fill(bg_color)

	# 画网格线
	var line_color := grid_color
	for y: int in tile_size:
		for x: int in tile_size:
			# 主网格线（每 grid_size 像素）
			if x % grid_size == 0 or y % grid_size == 0:
				img.set_pixel(x, y, line_color)
			# 中心十字（每 tile 中心加亮点）
			if x % grid_size == grid_size / 2 and y % grid_size == grid_size / 2:
				img.set_pixel(x, y, Color(0.2, 0.25, 0.35, 1.0))

	_texture = ImageTexture.create_from_image(img)

	# 用多个 Sprite2D 平铺覆盖地图
	var tiles_x: int = ceili(map_size.x / tile_size) + 2
	var tiles_y: int = ceili(map_size.y / tile_size) + 2
	var offset_x: float = -(tiles_x * tile_size) / 2.0
	var offset_y: float = -(tiles_y * tile_size) / 2.0

	for ty: int in tiles_y:
		for tx: int in tiles_x:
			var spr := Sprite2D.new()
			spr.texture = _texture
			spr.centered = false
			spr.position = Vector2(offset_x + tx * tile_size, offset_y + ty * tile_size)
			spr.z_index = -100
			add_child(spr)
