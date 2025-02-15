extends Area2D

var checkpointIndex = 0
var positionCheckpoint = Vector2(0,0)

func _on_area_entered(area: Area2D):
	if checkpointIndex == 0:
		positionCheckpoint = Vector2(0, -15)
	elif checkpointIndex == 1:
		positionCheckpoint = Vector2(3598, -1300)
	elif checkpointIndex == 2:
		positionCheckpoint = Vector2(5449, -2870)
	elif checkpointIndex == 3:
		positionCheckpoint = Vector2(11088, -2730)
	elif checkpointIndex == 4:
		positionCheckpoint = Vector2()
	elif checkpointIndex == 5:
		positionCheckpoint = Vector2()
	
	var parent = get_parent()
	var player = parent.get_node('Player')
	player.global_position = positionCheckpoint
