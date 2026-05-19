extends Area2D

@export var enemy: Node

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Player belépett a soldier szobába")
		if enemy != null:
			enemy.call("on_player_entered_room")


func _on_body_exited(body):
	if body.is_in_group("player"):
		print("Player kilépett a soldier szobából")
		if enemy != null:
			enemy.call("on_player_exited_room")
