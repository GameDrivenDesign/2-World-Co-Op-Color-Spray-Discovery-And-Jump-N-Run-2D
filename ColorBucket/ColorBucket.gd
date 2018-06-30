extends Node2D

export (String, "white", "black", "red", "magenta", "blue", "cyan", "green", "yellow") var color

func _ready():
	$Polygon2D.color = Colors.color_name_to_rgb(color)
