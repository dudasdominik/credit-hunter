extends Node2D

@export var door_name: String = "Robotika ajtó"
@export var required_item_id: String = "RobotikaPart"
@export var consume_required_item: bool = false
@export var requires_item: bool = true

@export var missing_item_text: String = "Ehhez az ajtóhoz szükséged van erre:"
@export var opened_text: String = "Az ajtó kinyílt."
@export var objective_after_open: String = "Menj be a Robotika terembe."

@export var ask_question_to_open: bool = false
@export var question_dialog_text: String = "Az ajtó csak akkor nyílik ki, ha helyesen válaszolsz."

@export var question_text: String = "Mit csinál egy szervó motor?"
@export var answer_1: String = "Meghatározott szögbe vagy pozícióba áll be vezérlőjel alapján"
@export var answer_2: String = "Meghatározott szögbe vagy pozícióba áll be vezérlőjel alapján"
@export var answer_3: String = "Csak elektromos energiát tárol, és akkumulátorként működik"
@export var answer_4: String = "Kizárólag szenzoradatokat mér, például hőmérsékletet vagy távolságot"
@export var correct_index: int = 0
@export var wrong_answer_damage: int = 10

@onready var sprite: Sprite2D = $Sprite2D
@onready var door_collision: CollisionShape2D = $DoorBody/CollisionShape2D
@onready var interact_area_collision: CollisionShape2D = $InteractArea/CollisionShape2D
@onready var interact_label: Label = $InteractLabel



var player_inside := false
var is_open := false


func _ready():
	interact_label.hide()


func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		try_open()


func try_open():
	if is_open:
		return

	if requires_item:
		if not GameManager.has_item(required_item_id):
			var item_name = GameManager.get_item_name(required_item_id)
			GameManager.show_dialog(door_name, missing_item_text + " " + item_name)
			return

	if ask_question_to_open:
		start_door_question()
		return

	if requires_item and consume_required_item:
		GameManager.remove_item_by_id(required_item_id)

	open_door()


func open_door():
	is_open = true

	GameManager.show_dialog(door_name, opened_text)
	GameManager.set_objective(objective_after_open)

	interact_label.hide()

	door_collision.set_deferred("disabled", true)
	interact_area_collision.set_deferred("disabled", true)

	sprite.hide()


func _on_interact_area_body_entered(body):
	if body.is_in_group("player") and not is_open:
		player_inside = true
		interact_label.show()


func _on_interact_area_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		interact_label.hide()

func start_door_question():
	var question_data = {
		"source": "door",
		"door_path": get_path(),
		"question": question_text,
		"answers": [
			answer_1,
			answer_2,
			answer_3,
			answer_4
		],
		"correct_index": correct_index,
		"wrong_damage": wrong_answer_damage
	}

	GameManager.show_teacher_dialog(door_name, question_dialog_text, question_data)

func open_from_quiz():
	if is_open:
		return

	if requires_item and consume_required_item:
		GameManager.remove_item_by_id(required_item_id)

	open_door()
