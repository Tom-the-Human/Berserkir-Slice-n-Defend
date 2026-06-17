extends Area2D
class_name Enemy

signal attacked_player(damage_amount: int) # when progress reaches 1.0
signal killed # when Body is_broken
signal part_broken # when ANY component breaks

var progress := 0.0 # 0.0 at horizon, 1.0 at player
@export var speed := 0.2 # adjust as needed

var start_pos : Vector2 
var end_pos : Vector2 # Forground/hit zone

@onready var polygon_node: Polygon2D = $Body/Polygon2D

# hit zone entered outline
var outline_line: Line2D
var in_hit_zone := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var center_x := 540.0
	
	# army width (pick random spot in army at horizon)
	# TWEAK THIS TO MATCH ART!!!
	var spawn_offset := randf_range(-350.0, 350.0)
	#############################################
	
	# horizon is 576
	start_pos = Vector2(center_x + spawn_offset, 576.0)
	
	# spread multiplier (adjust to make them filter onto the bridge, not necessarily center)
	var spread_multiplier := -0.9
	
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
	
	# for all parts, if sliceable, connect signal
	for child in get_children():
		if child is SliceablePart:
			child.destroyed.connect(func(): part_broken.emit())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	progress += delta * speed
	position = start_pos.lerp(end_pos, progress)
	
	var perspective_curve := pow(progress, 3)
	var scale_factor : Variant = lerp(0.1, 10.0, perspective_curve)
	scale = Vector2(scale_factor, scale_factor)
	
	# control draw order
	z_index = int(progress * 100)
	
	if progress >= 0.75 and not in_hit_zone:
		in_hit_zone = true
		# debug
		print("hit zone entered")
		# change outline_width to make visible
		outline_line.width = 1.5
	
	if progress >= 1.0:
		hit_player()

func hit_player() -> void:
	attacked_player.emit(10)
	queue_free()

func apply_cut(swipe_points: PackedVector2Array) -> void:
	if progress < 0.75:
		return
	
	# check for shield
	var shield = get_node_or_null("Shield")
	if shield and not shield.is_broken:
		var hit_shield = shield.apply_cut(swipe_points)
		if hit_shield:
			apply_knockback()
			return
	
	# check for armor
	var armor = get_node_or_null("Armor")
	if armor and not armor.is_broken:
		var hit_armor = armor.apply_cut(swipe_points)
		if hit_armor:
			apply_knockback()
			return
	
	# if no protection
	var body = get_node_or_null("Body")
	if body and not body.is_broken:
		body.apply_cut(swipe_points)
		die()

func apply_knockback() -> void:
	# push enemy back when hit but not killed
	progress = max(0.0, progress - 0.2)
	
	# update scale and position
	position = start_pos.lerp(end_pos, progress)
	var perspective_curve := pow(progress, 3)
	var scale_factor : float = lerp(0.1, 10.0, perspective_curve)
	scale = Vector2(scale_factor, scale_factor)
	z_index = int(progress * 100)
	
	if progress < 0.75:
		# no longer in hit zone
		in_hit_zone = false
		outline_line.width = 0.0

func die() -> void:
	killed.emit()
	queue_free()
