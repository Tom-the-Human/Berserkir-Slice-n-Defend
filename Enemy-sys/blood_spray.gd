extends CPUParticles2D

func spray(swipe_dir: Vector2, enemy_scale: float) -> void:
	# scale and velocity (tweak!)
	scale_amount_min = 2.0 * enemy_scale
	scale_amount_max = 4.0 * enemy_scale
	initial_velocity_min = 400.0 * enemy_scale
	initial_velocity_max = 800.0 * enemy_scale
	
	# convert swipe vector to angle
	direction = swipe_dir
	
	spread = 20.0
	
	initial_velocity_max = 1400.0
	initial_velocity_min = 800.0
	
	emitting = true

func _on_finished() -> void:
	queue_free()
