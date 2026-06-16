extends Polygon2D


func apply_cut(swipe_points: PackedVector2Array) -> void:
	# convert global coords to node local coords
	var local_points := PackedVector2Array()
	for pt in swipe_points:
		local_points.append(to_local(pt))
	
	var sliced_pieces := Slicer.slice_polygon_curved(polygon, local_points)
	
	if sliced_pieces.size() > 1:
		for piece_points in sliced_pieces:
			create_falling_rigidbody(piece_points)
		# delete original polygon
		queue_free()

func create_falling_rigidbody(points: PackedVector2Array) -> void:
	var rb := RigidBody2D.new()
	var poly := Polygon2D.new()
	var col := CollisionPolygon2D.new()

	# Assign polygon data
	poly.polygon = points
	poly.color = Color.RED
	col.polygon = points

	# Add children to RigidBody
	rb.add_child(poly)
	rb.add_child(col)

	# Set initial transform relative to the original node
	rb.global_position = global_position
	
	# Apply separation force
	rb.apply_central_impulse(Vector2(randf_range(-100, 100), randf_range(-50, -150)))

	# Add to scene tree
	get_parent().add_child(rb)
