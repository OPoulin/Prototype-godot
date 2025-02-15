extends Area2D

@export var flagGetVFXScene: PackedScene

func _on_area_entered(area: Area2D) -> void:
	var parent1 = get_parent()
	var parent2 = parent1.get_parent()
	var parent3 = parent2.get_parent()
	var deathPlane = parent3.get_node("DeathPlane")
	var currentFlag
	
	
	if get_parent() == parent2.get_node("Flag1") and deathPlane.checkpointIndex <= 0:
		deathPlane.checkpointIndex = 1
		currentFlag = parent2.get_node("Flag1/Area2DFlag")
		var flagGetVFX = flagGetVFXScene.instantiate()
		flagGetVFX.position = currentFlag.position + Vector2(0, -10)
		add_sibling(flagGetVFX)
		
	elif get_parent() == parent2.get_node('Flag2') and deathPlane.checkpointIndex <= 1:
		deathPlane.checkpointIndex = 2
		currentFlag = parent2.get_node("Flag2/Area2DFlag")
		var flagGetVFX = flagGetVFXScene.instantiate()
		flagGetVFX.position = currentFlag.global_position + Vector2(0, -10)
		print(currentFlag.global_position)
		add_sibling(flagGetVFX)
	elif get_parent() == parent2.get_node('Flag3') and deathPlane.checkpointIndex <= 2:
		deathPlane.checkpointIndex = 3
		currentFlag = parent2.get_node("Flag3/Area2DFlag")
		var flagGetVFX = flagGetVFXScene.instantiate()
		flagGetVFX.position = currentFlag.global_position + Vector2(0, -10)
		print(currentFlag.global_position)
		add_sibling(flagGetVFX)
	
	print(deathPlane.checkpointIndex)
