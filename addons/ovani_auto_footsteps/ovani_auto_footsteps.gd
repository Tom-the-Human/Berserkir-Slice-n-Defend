@tool
extends EditorPlugin

# Hidden Folder Vars 
const HIDDEN_FOLDER : StringName = "AutoFootStepsPlugin"
var file_list_tree : Control
var file_system_list : ItemList

func _enter_tree() -> void:
	
	if Engine.get_version_info().minor > 5:
		file_list_tree = self.get_editor_interface().get_file_system_dock().get_child(0).get_child(1).get_child(0).get_child(0)
	else:
		file_list_tree = self.get_editor_interface().get_file_system_dock().get_child(3, true).get_child(0, true)
	file_system_list = self.get_editor_interface().get_file_system_dock().find_children("*", "FileSystemList", true, false)[0]

func _process(delta: float) -> void:
	
	#if Engine.get_version_info().minor <= 5:
	# Hide Redirection folder from FileSystem dock primary list
	var resItem : TreeItem = file_list_tree.get_root().get_child(1)
	for i in resItem.get_child_count():
		if resItem.get_child(i).get_text(0) == HIDDEN_FOLDER:
			resItem.get_child(i).visible = false
	
	# Hide Redirection folder from FileSystem dock secondary list
	for i in file_system_list.item_count:
		if file_system_list.get_item_text(i) == HIDDEN_FOLDER:
			file_system_list.remove_item(i)
			break
	

# Unneeded Utility Func
func print_node_data(node : Node):
	for prop in node.get_property_list():
		var data = node.get(prop["name"])
		if data == null:
			data = "null"
		print(prop["name"] + " : " + str(data))
