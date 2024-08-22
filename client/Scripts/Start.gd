extends Control

@onready var loading = $Play/Control/Loading
@onready var play = $Play
@onready var controls = $Controls
@onready var high_scores = $HighScores
@onready var vbox = $HighScores/ScrollContainer/VBoxContainer

@onready var world = load("res://Scenes/world.tscn")
@onready var start = load("res://UI/Start.tscn")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$HTTPRequest.request_completed.connect(_on_request_completed)
	$HTTPRequest.request("https://getleaderboard-56ueawnosq-uc.a.run.app")

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var scores = json.get_data().data
	
	var label_settings = LabelSettings.new()
	label_settings.font_size = 24
	
		
	for i in range(len(scores)):
		var score = scores[i]
		var row = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.set_text(str(i+1) + '. '+ score.name)
		name_label.label_settings = label_settings
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		
		var lvl_label = Label.new()
		lvl_label.set_text(str(score.lvl))
		lvl_label.custom_minimum_size = Vector2(100,0)
		lvl_label.label_settings = label_settings
		row.add_child(lvl_label)
		
		var points_label = Label.new()
		points_label.set_text(str(score.score))
		points_label.custom_minimum_size = Vector2(120,0)
		points_label.label_settings = label_settings
		row.add_child(points_label)
		
		vbox.add_child(row)

func _process(_delta):
	pass

func _on_play_pressed():
	loading.visible = true
	loading.play("Loading")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().create_timer(.70 	).timeout
	get_tree().change_scene_to_packed(world)


func _on_quit_pressed():
	get_tree().change_scene_to_packed(start)
	

func _on_controls_pressed():
	play.visible = false
	controls.visible = true
	
func _on_high_scores_pressed():
	play.visible = false
	high_scores.visible = true
	
func _on_back_pressed():
	controls.visible = false
	high_scores.visible = false
	play.visible = true
	
