extends Node2D

export (NodePath) var player1_path
export (NodePath) var player2_path

var player1 = null
var player2 = null

const BEFORE_REACHING_SIDE_ZOOM_FACTOR = 1.5
const MIN_ZOOM_FACTOR = 1
const MAX_ZOOM_FACTOR = 2.0

func _ready():
	player1 = get_node(player1_path)
	player2 = get_node(player2_path)

func _process(delta):
	var screen_size = get_viewport().size
	var half_screen_height = screen_size.y / 2
	
	var p1_pos = player1.global_position
	var p2_pos = player2.global_position
	var p1_screen_center_dist = abs(p1_pos.y - global_position.y)
	var p2_screen_center_dist = abs(p2_pos.y - global_position.y)
	
	var middle_x = (p1_pos.x + p2_pos.x) / 2
	var distance_x = abs(p1_pos.x - p2_pos.x)
	
	# Move the camera left and right, but never move it vertically.
	global_position.x = middle_x
	
	# Zoom the camera. Bigger zoom factors leads to zooming out.
	# The lower bound zoom is set to MIN_ZOOM_FACTOR, so that we never zoom nearer than initially. 
	var zoom_x = distance_x / screen_size.x * BEFORE_REACHING_SIDE_ZOOM_FACTOR
	var zoom_y = max(p1_screen_center_dist, p2_screen_center_dist) / half_screen_height * BEFORE_REACHING_SIDE_ZOOM_FACTOR
	var zoom_factor = min(max(max(zoom_x, zoom_y), MIN_ZOOM_FACTOR), MAX_ZOOM_FACTOR)
	
	$Camera.zoom = Vector2(zoom_factor, zoom_factor)
