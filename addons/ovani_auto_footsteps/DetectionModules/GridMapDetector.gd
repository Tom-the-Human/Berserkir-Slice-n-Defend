extends FootMatDetectionModule

func TryFigureMaterial(raycast_response : Dictionary, foot_node : AutoFootSteps) -> StringName:
	if raycast_response["collider"] is GridMap:
		
		# Nope-out if the AutoFootSteps doesn't want GridMap support
		if (!foot_node.support_gridmaps):
			return AutoFootSteps.AIR_NAME
		
		# Get the foot's position relative to the GridMap
		var hit_grid : GridMap = raycast_response["collider"]
		var grid_hit_location : Vector3 = hit_grid.to_local(raycast_response["position"]);
		grid_hit_location = grid_hit_location - Vector3(0, hit_grid.cell_size.y / 2, 0);
		# offset the foot's position, in case of uncentered gridmap
		grid_hit_location += foot_node.grid_offset; 
		
		# Find the hit cell type or Fail
		var hit_cell : int = hit_grid.get_cell_item(hit_grid.local_to_map(grid_hit_location));
		if (hit_cell == GridMap.INVALID_CELL_ITEM):
			return AutoFootSteps.AIR_NAME
		
		# if the hit cell has a mesh:
		var mesh : Mesh = hit_grid.mesh_library.get_item_mesh(hit_cell);
		if mesh != null:
			# Find first mat that easily pairs with a Foot Step Sound.
			# TODO: Add custom exceptions for ArrayMeshes, as we can now
			# judge those on a per-face basis.
			for s_count in mesh.get_surface_count():
				var mat : Material = mesh.surface_get_material(s_count)
				if mat == null:
					continue
				
				var figured_material : FootProfileMaterialSpecification = foot_node.get_mat_fmat(mat);
				if figured_material.name != AutoFootSteps.AIR_NAME:
					foot_node._cached_material_materials[mat] = figured_material.name
					return figured_material.name
		
		# no mesh OR no matched material, check name
		return foot_node.foot_profile._string_to_material(hit_grid.mesh_library.get_item_name(hit_cell)).name
	else:
		return AutoFootSteps.AIR_NAME
