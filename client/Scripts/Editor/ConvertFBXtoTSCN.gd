extends Node

# Set the input and output folder paths
#var input_folder_path = "res://Assests/Guns/fbx_guns/"
#var output_folder_path = "res://Models/Guns/gun_scenes/"

func _run(input_folder_path: String, output_folder_path: String):
	# Get a list of all .fbx files in the input folder
	var input_folder = DirAccess.open(input_folder_path)
	print(input_folder)
	if input_folder:
		input_folder.list_dir_begin()
		var file_name = input_folder.get_next()
		print("file_name: " + file_name)
		while file_name != "":
			if file_name.ends_with("fbx"):
				var fbx_path = input_folder_path + file_name
				print(fbx_path)
				convert_fbx_to_tscn(output_folder_path, fbx_path, file_name)
			file_name = input_folder.get_next()
	print("Conversion complete.")

func convert_fbx_to_tscn(output_folder_path, fbx_path:String, file_name: String):
	var parsed_file_name = file_name.replace(".fbx", "")
	# Load the .fbx file as a mesh
	var fbx_mesh = load(fbx_path)
	if not fbx_mesh:
		print("Failed to load ", fbx_path)
		return
		
	# Instance the scene
	var new_scene_instance = fbx_mesh.instantiate()
#	print(new_scene_instance.get_children())
	var root_node = new_scene_instance.find_child("RootNode", true).find_child(parsed_file_name, true)
	var children = root_node.get_children()
	
	for child in children:
		child.owner = root_node
#	print(root_node.get_children())
	var scene = PackedScene.new()
	
	# Save the scene as .tscn in the output folder
	var result = scene.pack(root_node)
	if result == OK:
		var tscn_path = output_folder_path + parsed_file_name + ".tscn"
		var error = ResourceSaver.save(scene, tscn_path )
		
		if error == OK:
			print("Converted ", fbx_path, " to ", tscn_path)
		else:
			print("Failed to save ", tscn_path, error)
	else:
		print("Error on Pack", result)
