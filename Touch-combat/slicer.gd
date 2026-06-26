class_name Slicer
extends Node

# takes target shape and swipe coords, returns array of resulting sliced shapes
static func slice_polygon_curved(target_poly: PackedVector2Array, swipe_points: PackedVector2Array, thickness: float = 5.0) -> Array[PackedVector2Array]:
	# expand the swipe path into a thick polygon
	# use JOIN_ROUND to handle sharp turns in the swipe curve
	var blade_poly := Geometry2D.offset_polyline(swipe_points, thickness / 2.0, Geometry2D.JOIN_MITER, Geometry2D.END_ROUND)
	var intersection := Geometry2D.intersect_polygons(target_poly, blade_poly[0])
	# if swipe is too short/degenerate, or if no valid targets are hit, return a miss
	if blade_poly.is_empty() or intersection.is_empty():
		return []

	# valid hit occurs
	# Note: clip_polygons can return multiple pieces if the cut splits the target into 3+ parts
	var result := Geometry2D.clip_polygons(target_poly, blade_poly[0])
	
	# filter for valid pieces (must have 3+ vertices to be a polygon)
	var cleaned_result: Array[PackedVector2Array] = []
	for piece in result:
		if piece.size() >= 3:
			cleaned_result.append(piece)
			
	return cleaned_result
