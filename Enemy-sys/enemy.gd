extends Area2D
class_name Enemy

signal attacked_player(damage_amount: int)

var progress := 0.0 # 0.0 at horizon, 1.0 at player
@export var speed := 0.2 # adjust as needed

var start_pos : Vector2 
var end_pos : Vector2 # Forground/hit zone

@onready var polygon_node: Polygon2D = $Polygon2D

# hit zone entered outline
var outline_line: Line2D
var in_hit_zone := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var center_x := 540.0
	
	# army width (pick random spot in army at horizon)
	# TWEAK THIS TO MATCH ART!!!
	var spawn_offset := randf_range(-250.0, 250.0)
	#############################################
	
	# horizon is 576
	start_pos = Vector2(center_x + spawn_offset, 576.0)
	
	# spread multiplier (adjust to make them filter onto the bridge, not necessarily center)
	var spread_multiplier := 1.0
	
	# foreground Y is 1152
	end_pos = Vector2(center_x + (spawn_offset * spread_multiplier), 1152.0)
	
	position = start_pos
	scale = Vector2(0.1, 0.1)
	
	# outline setup
	outline_line = Line2D.new()
	outline_line.points = polygon_node.polygon
	outline_line.closed = true # Automatically connects the last point to the first
	outline_line.width = 0.0   # Keep it invisible until it reaches the Hit Zone
	outline_line.default_color = Color(1.5, 0.2, 0.2) # Over-bright red for a subtle glow effect
	# Add it as a child of the polygon so it perfectly overlaps
	polygon_node.add_child(outline_line)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	progress += delta * speed
	position = start_pos.lerp(end_pos, progress)
	
	var perspective_curve := pow(progress, 3)
	var scale_factor : Variant = lerp(0.1, 10.0, perspective_curve)
	scale = Vector2(scale_factor, scale_factor)
	
	if progress >= 0.75 and not in_hit_zone:
		in_hit_zone = true
		# debug
		print("hit zone entered")
		# change outline_width to make visible
		outline_line.width = 2.5
	
	if progress >= 1.0:
		hit_player()

func hit_player() -> void:
	attacked_player.emit(10)
	queue_free()

func apply_cut(swipe_points: PackedVector2Array) -> void:
	if progress < 0.75:
		return
		
	var local_points := PackedVector2Array()
	for pt in swipe_points:
		local_points.append(to_local(pt))
	
	var sliced_pieces := Slicer.slice_polygon_curved(polygon_node.polygon, local_points)
	
	if sliced_pieces.size() > 1:
		for piece_points in sliced_pieces:
			create_falling_rigidbody(piece_points)
		queue_free()

func create_falling_rigidbody(points: PackedVector2Array) -> void:
	var scaled_points := PackedVector2Array()
	for pt in points:
		scaled_points.append(pt * self.scale)
	
	var rb := RigidBody2D.new()
	var poly := Polygon2D.new()
	var col := CollisionPolygon2D.new()
	
	poly.polygon = scaled_points
	# try to implement texture later (UV maps)
	poly.color = Color.DARK_RED
	col.polygon = scaled_points

	rb.add_child(poly)
	rb.add_child(col)
	rb.global_position = global_position
	
	rb.apply_central_impulse(Vector2(randf_range(-100, 100), randf_range(-50, -150)))
	get_parent().add_child(rb)
