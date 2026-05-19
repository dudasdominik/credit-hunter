extends CanvasLayer

@onready var health_label: Label = $StatsPanel/VBoxContainer/HealthLabel
@onready var health_bar: ProgressBar = $StatsPanel/VBoxContainer/HealthBar
@export var item_slot_scene: PackedScene

@onready var armor_label: Label = $StatsPanel/VBoxContainer/ArmorLabel
@onready var armor_bar: ProgressBar = $StatsPanel/VBoxContainer/ArmorBar

@onready var inventory_button: Button = $StatsPanel/VBoxContainer/InventoryButton
@onready var inventory_panel: Panel = $InventoryPanel
@onready var item_list: VBoxContainer = $InventoryPanel/VBoxContainer/ItemList
@onready var close_button: Button = $InventoryPanel/CloseButton

@onready var dialog_panel: Panel = $DialogPanel
@onready var dialog_name_label: Label = $DialogPanel/VBoxContainer/NameLabel
@onready var dialog_text_label: Label = $DialogPanel/VBoxContainer/DialogText
@onready var start_question_button: Button = $DialogPanel/VBoxContainer/StartQuestionButton
@onready var close_dialog_button: Button = $DialogPanel/VBoxContainer/CloseDialogButton

@onready var quiz_panel: Panel = $QuizPanel
@onready var question_label: Label = $QuizPanel/VBoxContainer/QuestionLabel
@onready var answer_buttons = [
	$QuizPanel/VBoxContainer/AnswerButton1,
	$QuizPanel/VBoxContainer/AnswerButton2,
	$QuizPanel/VBoxContainer/AnswerButton3,
	$QuizPanel/VBoxContainer/AnswerButton4
]
@onready var close_quiz_button: Button = $QuizPanel/VBoxContainer/CloseQuizButton

@onready var objective_label: Label = $StatsPanel/VBoxContainer/ObjectiveLabel

@onready var game_over_panel: Panel = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton
@onready var exit_button: Button = $GameOverPanel/VBoxContainer/ExitButton

@onready var victory_panel: Panel = $VictoryPanel
@onready var victory_restart_button: Button = $VictoryPanel/VBoxContainer/VictoryRestartButton
@onready var victory_exit_button: Button = $VictoryPanel/VBoxContainer/VictoryExitButton

var current_question: Dictionary = {}

func _ready():
	inventory_panel.hide()

	health_bar.max_value = GameManager.max_health
	armor_bar.max_value = GameManager.max_armor

	GameManager.stats_changed.connect(update_stats)
	GameManager.inventory_changed.connect(update_inventory)
	GameManager.objective_changed.connect(update_objective)
	GameManager.dialog_requested.connect(show_dialog)
	GameManager.quiz_requested.connect(show_quiz)
	GameManager.game_over_requested.connect(show_game_over)
	GameManager.victory_requested.connect(show_victory)



	
	inventory_button.pressed.connect(toggle_inventory)
	close_button.pressed.connect(toggle_inventory)

	update_stats()
	update_inventory()
	update_objective()
	dialog_panel.hide()
	quiz_panel.hide()
	game_over_panel.hide()
	victory_panel.hide()
	if GameManager.is_victory:
		show_victory()



	start_question_button.pressed.connect(start_question)
	close_dialog_button.pressed.connect(close_dialog)
	close_quiz_button.pressed.connect(close_quiz)
	restart_button.pressed.connect(restart_game)
	exit_button.pressed.connect(exit_game)
	victory_restart_button.pressed.connect(restart_game)
	victory_exit_button.pressed.connect(exit_game)
	

	

	for i in range(answer_buttons.size()):
		var answer_index := i
		answer_buttons[i].pressed.connect(func(): check_answer(answer_index))
	 


func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		toggle_inventory()


func update_stats():
	health_bar.value = GameManager.health
	armor_bar.value = GameManager.armor

	health_label.text = "Health: %d / %d" % [GameManager.health, GameManager.max_health]
	armor_label.text = "Armor: %d / %d" % [GameManager.armor, GameManager.max_armor]


func update_inventory():
	for child in item_list.get_children():
		child.queue_free()

	if GameManager.inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Üres inventory"
		empty_label.add_theme_font_size_override("font_size", 10)
		item_list.add_child(empty_label)
		return

	for i in range(GameManager.inventory.size()):
		var item_id = GameManager.inventory[i]

		if not GameManager.item_database.has(item_id):
			continue

		var item_data = GameManager.item_database[item_id]

		var slot = item_slot_scene.instantiate()
		item_list.add_child(slot)

		slot.setup(i, item_id, item_data)
		slot.item_used.connect(_on_item_slot_used)

func toggle_inventory():
	inventory_panel.visible = not inventory_panel.visible

func _on_item_slot_used(index: int):
	GameManager.use_item(index)
	update_inventory()
	update_stats()




func close_dialog():
	dialog_panel.hide()

func show_dialog(npc_name: String, dialog_text: String, has_question: bool):
	dialog_name_label.text = npc_name
	dialog_text_label.text = dialog_text

	start_question_button.visible = has_question

	dialog_panel.show()





func start_question():
	dialog_panel.hide()
	GameManager.start_pending_question()


func show_quiz(question_data: Dictionary):
	current_question = question_data

	question_label.text = question_data["question"]

	var answers = question_data["answers"]

	for i in range(answer_buttons.size()):
		answer_buttons[i].text = answers[i]

	quiz_panel.show()


func close_quiz():
	quiz_panel.hide()


func check_answer(index: int):
	if current_question.is_empty():
		return

	var correct_index = current_question["correct_index"]

	if index == correct_index:
		quiz_panel.hide()

		if current_question.has("source") and current_question["source"] == "door":
			var door = get_node_or_null(current_question["door_path"])

			if door != null and door.has_method("open_from_quiz"):
				door.open_from_quiz()
				show_dialog("Helyes válasz", "Jó válasz! Az ajtó kinyílt.", false)
			else:
				show_dialog("Hiba", "Az ajtót nem találom.", false)

		else:
			var reward_item_id = current_question.get("reward_item_id", "")
			
			if reward_item_id != "":
				GameManager.add_item(reward_item_id)
				GameManager.set_objective("Jó válasz! Megszerezted: " + GameManager.get_item_name(reward_item_id))
				var reward_type = GameManager.get_item_type(reward_item_id)
				
				if reward_type != "consumable":
					if current_question.has("npc_path"):
						var npc = get_node_or_null(current_question["npc_path"])
						if npc != null and npc.has_method("mark_completed"):
							npc.mark_completed()

			show_dialog("Helyes válasz", "Jó válasz!", false)

	else:
		var damage = current_question.get("wrong_damage", 10)
		GameManager.damage(damage)

		quiz_panel.hide()
		show_dialog("Rossz válasz", "Ez most nem sikerült. Sebződtél " + str(damage) + "-et.", false)

	current_question = {}

func update_objective():
	objective_label.text = "Objective: " + GameManager.current_objective

func show_game_over():
	game_over_panel.show()
	get_tree().paused = true


func restart_game():
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().reload_current_scene()


func exit_game():
	get_tree().paused = false
	get_tree().quit()


func show_victory():
	print("HUD megkapta a victory signalt")

	inventory_panel.hide()
	dialog_panel.hide()
	quiz_panel.hide()
	game_over_panel.hide()

	victory_panel.show()
	get_tree().paused = true
