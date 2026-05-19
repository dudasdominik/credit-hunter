extends Panel

signal item_used(index: int)

@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/TextBox/NameLabel
@onready var info_label: Label = $HBoxContainer/TextBox/InfoLabel
@onready var use_button: Button = $HBoxContainer/UseButton

var item_index := -1


func setup(index: int, item_id: String, item_data: Dictionary):
	item_index = index

	name_label.text = item_data.get("name", item_id)
	info_label.text = get_info_text(item_data)

	if item_data.has("icon"):
		var texture = load(item_data["icon"])
		if texture != null:
			icon.texture = texture

	use_button.text = get_button_text(item_data)
	use_button.pressed.connect(_on_use_pressed)


func get_info_text(item_data: Dictionary) -> String:
	var type = item_data.get("type", "unknown")

	match type:
		"consumable":
			var effect = item_data.get("effect", "")
			var value = item_data.get("value", 0)

			if effect == "heal":
				return "Heal +" + str(value)

			if effect == "armor_restore":
				return "Armor +" + str(value)

			return "Consumable"

		"weapon":
			return "Damage +" + str(item_data.get("damage_bonus", 0))

		"armor":
			return "Armor +" + str(item_data.get("armor_bonus", 0))

		"quest_item":
			return "Quest item"

		_:
			return str(type)


func get_button_text(item_data: Dictionary) -> String:
	var type = item_data.get("type", "unknown")

	match type:
		"consumable":
			return "Use"
		"weapon":
			return "Equip"
		"armor":
			return "Equip"
		"quest_item":
			return "-"
		_:
			return "Use"


func _on_use_pressed():
	if item_index == -1:
		return

	item_used.emit(item_index)
