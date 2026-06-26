extends CPUParticles2D


func spray(swipe_dir: Vector2, enemy_scale: float) -> void:
	# scale and velocity
	scale_amount_min = 2.0 * enemy_scale
	scale_amount_max = 6.0 * enemy_scale
	initial_velocity_min = 500.0 * enemy_scale
	initial_velocity_max = 900.0 * enemy_scale

	direction = swipe_dir
	spread = 35.0
	
	emitting = true
	
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()
