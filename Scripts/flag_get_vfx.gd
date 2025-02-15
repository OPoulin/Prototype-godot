extends AnimatedSprite2D


func _on_frame_changed():
	print(frame)


func _on_animation_finished():
	frame = 0
	queue_free()
