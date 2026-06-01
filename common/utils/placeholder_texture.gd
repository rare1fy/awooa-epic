class_name PlaceholderTexture
extends RefCounted
## 占位纹理生成器
## 在没有美术资源时，用代码生成彩色圆形/方形纹理

## 缓存已生成的纹理，避免重复创建
static var _cache: Dictionary = {}


## 生成一个纯色圆形纹理
static func circle(radius: int, color: Color) -> ImageTexture:
	var key := "circle_%d_%s" % [radius, color.to_html()]
	if _cache.has(key):
		return _cache[key]

	var size := radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)

	for y: int in size:
		for x: int in size:
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius - 1:
				img.set_pixel(x, y, color)
			elif dist <= radius:
				# 边缘抗锯齿
				var alpha := 1.0 - (dist - (radius - 1))
				var edge_color := Color(color.r, color.g, color.b, color.a * alpha)
				img.set_pixel(x, y, edge_color)

	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## 生成一个带轮廓的圆形纹理（更好看）
static func outlined_circle(radius: int, fill: Color, outline: Color = Color.WHITE) -> ImageTexture:
	var key := "ocircle_%d_%s_%s" % [radius, fill.to_html(), outline.to_html()]
	if _cache.has(key):
		return _cache[key]

	var size := radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	var outline_width := maxf(1.0, radius * 0.15)

	for y: int in size:
		for x: int in size:
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius - outline_width:
				img.set_pixel(x, y, fill)
			elif dist <= radius:
				img.set_pixel(x, y, outline)

	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## 生成一个小方块纹理（用于弹道）
static func square(size: int, color: Color) -> ImageTexture:
	var key := "square_%d_%s" % [size, color.to_html()]
	if _cache.has(key):
		return _cache[key]

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)

	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## 生成一个菱形纹理（用于经验宝石）
static func diamond(size: int, color: Color) -> ImageTexture:
	var key := "diamond_%d_%s" % [size, color.to_html()]
	if _cache.has(key):
		return _cache[key]

	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := size / 2

	for y: int in size:
		for x: int in size:
			var dx := absf(x - half)
			var dy := absf(y - half)
			if (dx / float(half) + dy / float(half)) <= 1.0:
				img.set_pixel(x, y, color)

	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex
