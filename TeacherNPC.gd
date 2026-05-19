extends Area2D

@export var npc_name: String = "Varázsló Tanár"
@export var dialog_text: String = "Üdv, hallgató! Készen állsz egy kérdésre?"

@export var is_teacher: bool = true

@export var requires_quest_item: bool = false
@export var required_item_id: String = "Microscope"
@export var consume_required_item: bool = false
@export var missing_item_text: String = "Előbb hozd el nekem ezt az itemet:"
@export var has_item_text: String = "Látom, nálad van, amire szükségem van."

@export var reward_item_id: String = "RobotikaPart"
@export var completed_text: String = "Ezt a feladatot már teljesítetted."


@export var question_text: String = "Mi a szenzor feladata robotikában?"
@export var answer_1: String = "Adatok érzékelése a környezetből"
@export var answer_2: String = "Motor kizárólagos vezérlése"
@export var answer_3: String = "Adatbázis törlése"
@export var answer_4: String = "Weboldal megjelenítése"
@export var correct_index: int = 0

@onready var interact_label: Label = $InteractLabel

var player_inside := false
var required_item_consumed := false
var is_completed := false


func _ready():
	interact_label.hide()


func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		interact()


func interact():
	if is_completed:
		GameManager.show_dialog(npc_name, completed_text)
		return
	if requires_quest_item:
		if not GameManager.has_item(required_item_id) and not required_item_consumed:
			var item_name = GameManager.get_item_name(required_item_id)
			GameManager.show_dialog(npc_name, missing_item_text + " " + item_name)
			return

		if consume_required_item and not required_item_consumed:
			GameManager.remove_item_by_id(required_item_id)
			required_item_consumed = true

		if has_item_text != "":
			print(npc_name + ": " + has_item_text)

	if is_teacher:
		var question_data = {
			"source": "teacher",
			"npc_path": get_path(),
			"npc_name": npc_name,
			"question": question_text,
			"answers": [
				answer_1,
				answer_2,
				answer_3,
				answer_4
			],
			"correct_index": correct_index,
			"reward_item_id": reward_item_id
		}

		GameManager.show_teacher_dialog(npc_name, dialog_text, question_data)
	else:
		GameManager.show_dialog(npc_name, dialog_text)


func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		interact_label.show()


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		interact_label.hide()

func mark_completed():
	is_completed = true
