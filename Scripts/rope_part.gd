extends Sprite2D

func _on_timer_despawn_timeout():
	queue_free()
