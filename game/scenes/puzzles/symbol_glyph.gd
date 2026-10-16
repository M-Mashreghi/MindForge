extends Control
## Draws a named symbol as a distinct shape, so symbols never rely on color
## alone. Shared by pattern and memory renderers.

const SYMBOLS := ["circle", "triangle", "square", "diamond", "star", "hexagon", "cross", "ring"]

@export var symbol: String = "circle":
	set(value):
		symbol = value
		queue_redraw()
@export var color: Color = Color(0.92, 0.88, 1.0):
	set(value):
		color = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) * 0.36
	match symbol:
		"circle":
			draw_circle(c, r, color)
		"ring":
			draw_arc(c, r * 0.85, 0.0, TAU, 32, color, r * 0.3)
		"square":
			draw_rect(Rect2(c - Vector2.ONE * r * 0.85, Vector2.ONE * r * 1.7), color)
		"triangle":
			draw_colored_polygon(_regular(c, r, 3, -PI / 2.0), color)
		"diamond":
			draw_colored_polygon(_regular(c, r, 4, -PI / 2.0), color)
		"hexagon":
			draw_colored_polygon(_regular(c, r, 6, 0.0), color)
		"star":
			var points := PackedVector2Array()
			for i in 10:
				var radius := r if i % 2 == 0 else r * 0.45
				var angle := -PI / 2.0 + i * PI / 5.0
				points.append(c + Vector2(cos(angle), sin(angle)) * radius)
			draw_colored_polygon(points, color)
		"cross":
			var w := r * 0.5
			draw_rect(Rect2(c.x - w / 2.0, c.y - r, w, r * 2.0), color)
			draw_rect(Rect2(c.x - r, c.y - w / 2.0, r * 2.0, w), color)
		_:
			draw_string(get_theme_default_font(), c + Vector2(-8, 8), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 28, color)


static func _regular(center: Vector2, radius: float, sides: int, offset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		var angle := offset + i * TAU / sides
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
