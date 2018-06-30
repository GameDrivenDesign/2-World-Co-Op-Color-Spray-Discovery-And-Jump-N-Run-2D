extends Node2D

export (String, "white", "black", "red", "magenta", \
				"blue", "cyan", "green", "yellow") var colorName = "cyan"

var bucketColor = null

func _ready():
	bucketColor = Colors.color_name_to_rgb(colorName)
	$Polygon2D.color = bucketColor

func _on_CollisionArea_body_entered(body):
	if body.is_in_group("player"):
		print('Player has entered')
		body.paintColor = bucketColor
		queue_free()