extends FootMatDetectionModule


func _init() -> void:
	supported = type_exists("Terrain3D")

var supported : bool

func TryFigureMaterial(raycast_response : Dictionary, foot_node : AutoFootSteps) -> StringName:
	if !supported:
		return foot_node.AIR_NAME
		
	var Terrain : Node = raycast_response["collider"]
	if Terrain.get_class() != "Terrain3D":
		return foot_node.AIR_NAME
	
	var tex_datas : Vector3 = Terrain["data"].get_texture_id(foot_node.global_position)
	var tex_id : int = tex_datas.y if tex_datas.z > .5 else tex_datas.x
	var texs : Array = Terrain["assets"]["texture_list"]
	for tex in texs:
		if tex["id"] == tex_id:
			#first check name
			var fmat := foot_node.foot_profile._string_to_material(tex["name"])
			if fmat.name != foot_node.AIR_NAME:
				return fmat.name
			else:
				var tex_asset : Texture2D = tex["albedo_texture"]
				fmat = foot_node.foot_profile._string_to_material(tex_asset.resource_name)
				if fmat.name != foot_node.AIR_NAME:
					return fmat.name
				else:
					return foot_node.foot_profile._string_to_material(tex_asset.resource_path).name
	return foot_node.AIR_NAME
