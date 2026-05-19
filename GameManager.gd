extends Node

signal stats_changed
signal inventory_changed
signal dialog_requested(npc_name: String, dialog_text: String, has_question: bool)
signal quiz_requested(question_data: Dictionary)
signal objective_changed
signal game_over_requested
signal victory_requested
signal player_damaged(amount: int)

var max_health := 100
var health := 100

var max_armor := 50
var armor := 25
var player_damage := 20
var current_objective := "Keresd meg az első tanárt."
var pending_question: Dictionary = {}
var is_game_over := false
var is_victory := false

var victory_items: Array[String] = [
	"RobotikaPart",
	"NeptunGyuru",
	"ZHKiraly"
]

var item_database = {
	"Armor1": {
		"name": "Armor_Red",
		"type": "armor",
		"armor_bonus": 15,
		"icon": "res://assets/items/Armor1.png"
	},
	"Armor2": {
		"name": "Armor_Hat",
		"type": "armor",
		"armor_bonus": 10,
		"icon": "res://assets/items/Armor2.png"
	},
	"ArmorPotion1": {
		"name": "Armor Potion",
		"type": "consumable",
		"effect": "armor_restore",
		"value": 20,
		"icon": "res://assets/items/ArmorPortion1.png"
	},
	"HealthPotion1": {
		"name": "Health Potion",
		"type": "consumable",
		"effect": "heal",
		"value": 25,
		"icon": "res://assets/items/HealthPotion1.png"
	},
	"Medicpack": {
		"name": "Medic Pack",
		"type": "consumable",
		"effect": "heal",
		"value": 15,
		"icon": "res://assets/items/Medipack.png"
	},
	"Microscope": {
		"name": "Microscope",
		"type": "quest_item",
		"icon": "res://assets/items/Microscope.png"
	},
	"NeptunGyuru": {
		"name": "NeptunRing",
		"type": "quest_item",
		"icon": "res://assets/items/NeptunGyuru.png"
	},
	"RobotikaPart": {
		"name": "Robotika Part",
		"type": "quest_item",
		"icon": "res://assets/items/RobotikaPart1.png"
	},
	"Trophy1": {
		"name": "Throphy",
		"type": "quest_item",
		"icon": "res://assets/items/Trophy1.png"
	},
	"ClassroomKey": {
		"name": "Teremkulcs",
		"type": "quest_item",
		"icon": "res://assets/items/ClassroomKey.png"
	},
	"ZHKiraly": {
		"name": "Crown",
		"type": "quest_item",
		"icon": "res://assets/items/ZHKiraly.png"
	},
	"Sword1": {
		"name": "Iron Sword",
		"type": "weapon",
		"damage_bonus": 10,
		"icon": "res://assets/items/Sword1.png"
	},
	"Sword2": {
		"name": "Small Sword",
		"type": "weapon",
		"damage_bonus": 8,
		"icon": "res://assets/items/Sword2.png"
	},
	"Sword3": {
		"name": "Long Sword",
		"type": "weapon",
		"damage_bonus": 14,
		"icon": "res://assets/items/Sword3.png"
	},
}

var inventory: Array[String] = []

func set_objective(text: String):
	current_objective = text
	objective_changed.emit()


func show_dialog(npc_name: String, dialog_text: String):
	pending_question = {}
	dialog_requested.emit(npc_name, dialog_text, false)


func show_teacher_dialog(npc_name: String, dialog_text: String, question_data: Dictionary):
	pending_question = question_data
	dialog_requested.emit(npc_name, dialog_text, true)


func start_pending_question():
	if pending_question.is_empty():
		print("Nincs pending kérdés.")
		return

	quiz_requested.emit(pending_question)

func set_health(value: int):
	health = clamp(value, 0, max_health)
	stats_changed.emit()


func set_armor(value: int):
	armor = clamp(value, 0, max_armor)
	stats_changed.emit()

func reset_game():
	is_game_over = false
	is_victory = false

	max_health = 100
	health = 100

	max_armor = 50
	armor = 25

	player_damage = 20
	inventory.clear()

	current_objective = "Keresd meg az első tanárt."

	stats_changed.emit()
	inventory_changed.emit()
	objective_changed.emit()

func damage(amount: int):
	var remaining_damage = amount

	if armor > 0:
		var armor_damage = min(armor, remaining_damage)
		armor -= armor_damage
		remaining_damage -= armor_damage

	if remaining_damage > 0:
		health -= remaining_damage

	health = clamp(health, 0, max_health)
	armor = clamp(armor, 0, max_armor)

	stats_changed.emit()
	player_damaged.emit(amount)

	if health <= 0 and not is_game_over:
		is_game_over = true
		game_over_requested.emit()

func heal(amount: int):
	health = clamp(health + amount, 0, max_health)
	stats_changed.emit()


func add_armor(amount: int):
	armor = clamp(armor + amount, 0, max_armor)
	stats_changed.emit()



func remove_item(item_name: String):
	if inventory.has(item_name):
		inventory.erase(item_name)
		inventory_changed.emit()


func add_item(item_id: String):
	if not item_database.has(item_id):
		print("Nincs ilyen item: ", item_id)
		return

	inventory.append(item_id)
	inventory_changed.emit()
	print("Felvéve: ", item_database[item_id]["name"])

	check_victory()


func use_item(index: int):
	if index < 0 or index >= inventory.size():
		return

	var item_id = inventory[index]
	var item = item_database[item_id]

	match item["type"]:
		"consumable":
			use_consumable(index, item)
		"weapon":
			equip_weapon(index, item)
		"armor":
			equip_armor(index, item)


func use_consumable(index: int, item: Dictionary):
	match item["effect"]:
		"heal":
			heal(item["value"])
		"armor_restore":
			add_armor(item["value"])

	inventory.remove_at(index)
	inventory_changed.emit()


func equip_weapon(index: int, item: Dictionary):
	player_damage += item["damage_bonus"]
	print("Damage növelve: ", player_damage)

	inventory.remove_at(index)
	inventory_changed.emit()


func equip_armor(index: int, item: Dictionary):
	max_armor += item["armor_bonus"]
	armor += item["armor_bonus"]

	stats_changed.emit()

	inventory.remove_at(index)
	inventory_changed.emit()


func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func remove_item_by_id(item_id: String) -> bool:
	if inventory.has(item_id):
		inventory.erase(item_id)
		inventory_changed.emit()
		return true
	
	return false


func get_item_name(item_id: String) -> String:
	if item_database.has(item_id):
		return item_database[item_id].get("name", item_id)
	
	return item_id

func check_victory():
	print("Victory check indul...")
	print("Inventory: ", inventory)
	print("Victory items: ", victory_items)

	if is_game_over:
		print("Nincs victory, mert game over aktív.")
		return

	if is_victory:
		print("Victory már aktív, újra küldöm a signalt.")
		victory_requested.emit()
		return

	for item_id in victory_items:
		if not inventory.has(item_id):
			print("Hiányzó victory item: ", item_id)
			return

	print("VICTORY TELJESÜLT!")
	is_victory = true
	victory_requested.emit()


func get_item_type(item_id: String) -> String:
	if item_database.has(item_id):
		return item_database[item_id].get("type", "")
	
	return ""
