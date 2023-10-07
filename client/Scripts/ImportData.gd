extends Node


var gun_data

func _ready():
	var gun_data_txt = FileAccess.get_file_as_string("res://Data/guns.json")
	gun_data = JSON.parse_string(gun_data_txt)
	
