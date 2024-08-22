extends Control

signal save_score

@onready var loading = $Control/Loading
@onready var play = $Wasted/Play
@onready var quit = $Wasted/Quit
@onready var save_score_screen = $SaveScoreScreen
@onready var save_score_screen_input = $SaveScoreScreen/Input
@onready var saved = $SaveScoreScreen/Saved
@onready var warning = $SaveScoreScreen/Input/Warning
@onready var save_score_button = $Wasted/SaveScoreButton
@onready var wasted = $Wasted
@onready var name_input = $SaveScoreScreen/Input/NameInput




@onready var world = load("res://Scenes/world.tscn")
@onready var start = load("res://UI/Start.tscn")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(_delta):
	pass

func _on_play_pressed():
	loading.visible = true
	loading.play("Loading")
	play.visible = false
	quit.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().create_timer(.5).timeout
	get_tree().change_scene_to_packed(world)


func _on_quit_pressed():
	get_tree().change_scene_to_packed(start)
	
func _on_save_score_button_pressed():
	wasted.visible = false
	save_score_screen.visible = true
	
func _on_back_pressed():
	wasted.visible = true
	save_score_screen.visible = false
	
func _on_save_pressed():
	if name_input.text == '':
		warning.visible = true
		return
	save_score_screen_input.visible = false
	save_score.emit(name_input.text)
	loading.visible = true
	loading.play("Loading")

	await get_tree().create_timer(1.1).timeout
	loading.visible = false
	saved.visible = true

