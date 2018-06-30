extends Node

const colors = {
	"white": Color(1.0, 1.0, 1.0),
	"black": Color(0.0, 0.0, 0.0),
	
	"red": Color(1.0, 0.0, 0.0),
	"green": Color(0.0, 1.0, 0.0),
	"blue": Color(0.0, 0.0, 1.0),
	
	"yellow": Color(1.0, 1.0, 0.0),
	"cyan": Color(0.0, 1.0, 1.0),
	"magenta": Color(1.0, 0.0, 1.0),
}

const color_to_tile_index = {
	colors["red"]: 0,
	colors["green"]: 1,
	colors["white"]: 2,
	colors["black"]: 3,
	colors["yellow"]: 4,
	colors["magenta"]: 7,
	colors["cyan"]: 6,
	colors["blue"]: 5
}	

func color_name_to_rgb(color_name):
	return colors[color_name]
	
func color_name_to_tile_index(color):
	return color_to_tile_index[color]

func rgb_to_color_name(rgb):
	for color_name in colors:
		if colors[color_name] == rgb:
			return color_name
	
	# This should never happen :(
	print("Given color was invalid")
	assert(false)

func mix_additive_rgb(color1, color2):
	return Color(
		min(1.0, color1.r + color2.r), 
		min(1.0, color1.g + color2.g),
		min(1,0, color1.b + color2.b)
	)

func mix_subtractive_rgb(color1, color2):
	return Color(
		max(0.0, color1.r - color2.r), 
		max(0.0, color1.g - color2.g),
		max(0,0, color1.b - color2.b)
	)
	
func mix_additive_name(color1, color2):
	return rgb_to_color_name(
		mix_additive_rgb(
			color_name_to_rgb(color1),
			color_name_to_rgb(color2)
		)
	)
	
func mix_subtractive_name(color1, color2):
	return rgb_to_color_name(
		mix_subtractive_rgb(
			color_name_to_rgb(color1),
			color_name_to_rgb(color2)
		)
	)