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
@export var blood_spray_scene: PackedScene
@export var wood_spray_scene: PackedScene
@export var armor_break_sfx: PackedScene

# hit zone entered outline
var outline_line: Line2D
var in_hit_zone := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("enemies")
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
		# change outline_width to make visible
		outline_line.width = 1.5
	
	if progress >= 1.0:
		hit_player()

func hit_player() -> void:
	attacked_player.emit(10)
	queue_free()

func apply_cut(swipe_points: PackedVector2Array, remaining_pierces: int, swipe_dir: Vector2) -> int:
	if progress < 0.75 or remaining_pierces <= 0:
		return remaining_pierces
	
	var parts_hit := 0
		
	# check for shield
	var shield = get_node_or_null("Shield")
	if remaining_pierces > 0 and shield and not shield.is_broken:
		var hit_shield_rb = shield.apply_cut(swipe_points, swipe_dir)
		if hit_shield_rb:
			remaining_pierces -= 1
			parts_hit += 1
			if wood_spray_scene:
				var splinters = wood_spray_scene.instantiate()
				var cut_pos = Geometry2D.get_closest_point_to_segment(shield.global_position, swipe_points[0], swipe_points[-1])
				
				hit_shield_rb.add_child(splinters)
				splinters.global_position = cut_pos
				splinters.z_index = hit_shield_rb.z_index + 1
				splinters.spray(swipe_dir, scale.x)
	
	# check for armor
	var armor = get_node_or_null("Armor")
	if remaining_pierces > 0 and armor and not armor.is_broken:
		var hit_armor = armor.apply_cut(swipe_points, swipe_dir)
		if hit_armor:
			remaining_pierces -= 1
			parts_hit += 1
			if armor_break_sfx:
				var audio = armor_break_sfx.instantiate()
				get_tree().current_scene.add_child(audio)
				audio.play()
	
	# if no protection
	var body = get_node_or_null("Body")
	if remaining_pierces > 0 and body and not body.is_broken:
		var hit_body_rb = body.apply_cut(swipe_points, swipe_dir)
		if hit_body_rb:
			remaining_pierces -= 1
			parts_hit += 1
			if blood_spray_scene:
				var blood = blood_spray_scene.instantiate()
				var cut_pos = Geometry2D.get_closest_point_to_segment(body.global_position, swipe_points[0], swipe_points[-1])
				
				hit_body_rb.add_child(blood)
				blood.global_position = cut_pos
				blood.z_index = z_index + 1
				#get_tree().current_scene.add_child(blood)
				blood.spray(swipe_dir, scale.x)
				get_tree().current_scene.trigger_screen_splatter()
			die()
	
	if parts_hit > 0 and not is_queued_for_deletion():
		apply_knockback()
	
	return remaining_pierces

func apply_knockback() -> void:
	# push enemy back when hit but not killed
	progress = max(0.0, progress - Global.knockback)
	
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
