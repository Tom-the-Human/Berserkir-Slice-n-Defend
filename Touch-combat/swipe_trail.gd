extends Line2D
class_name SwipeTrail

signal swipe_started
signal swipe_completed(swipe_point: PackedVector2Array)

var max_points := 15
var is_swiping := false
var swipe_start_pos := Vector2.ZERO
var swipe_end_pos := Vector2.ZERO

func _ready() -> void:
	# style line as weapon trail
	width = 8.0
	default_color = Color(1, 0.2, 0.2, 0.8)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_started.emit()
			is_swiping = true
			clear_points()
			swipe_start_pos = event.position
			add_point(event.position)
		else:
			is_swiping = false
			swipe_end_pos = event.position
			trigger_slice()
			clear_points()
	
	# draw trail while dragging
	if event is InputEventScreenDrag and is_swiping:
		var previous_point: Vector2 = points[-1] if get_point_count() > 0 else event.position
		add_point(event.position)
		if get_point_count() > max_points:
			remove_point(0)
	
		# preemptive raycast to trigger SFX
		#var enemies = get_tree().get_nodes_in_group("enemies")
		#for enemy in enemies:
			# Verify enemy is in the Hit Zone and audio has not already fired
			#if enemy.progress >= 0.75 and not enemy.impact_audio_played:
				# Define approximate bounding box (scale 100x100 relative to center)
				#var rect = Rect2(enemy.global_position - Vector2(50, 50), Vector2(100, 100))


func trigger_slice() -> void:
	var distance := swipe_start_pos.distance_to(swipe_end_pos)
	# test that it's long enough to be a valid attack (tweak?)
	if distance > 50.0:
		swipe_completed.emit(points)
