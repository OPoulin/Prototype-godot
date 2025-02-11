extends CharacterBody2D

@onready var _animated_sprite = $AnimatedSprite2D

@export var DoubleJumpVFXScene: PackedScene
@export var JumpVFXScene: PackedScene
@export var DashRechargeVFXScene: PackedScene
@export var DashGroundLeftVFXScene: PackedScene
@export var DashGroundRightVFXScene: PackedScene
@export var LandingVFXScene: PackedScene
@export var AirDashLeftVFXScene: PackedScene
@export var AirDashRightVFXScene: PackedScene
@export var GrappleGetVFXScene: PackedScene
@export var SPEED: float
@export var ORIGINAL_JUMP_VELOCITY = -800
var JUMP_VELOCITY = 0

var droite = false # 2 Bools for camera clarity
var gauche = false
var canMove = true # Bool to block player movement

var cameraOriginalPosition
var look = false # Bool to start the look timers one at a time
var isLooking = false # Bool to check if the player is looking in a direction
var lookingRight = true # Bool to check if the player is looking right
var lookingLeft = false # Bool to check if the player is looking left

var saute = false # Bool to check if the player has jumped
var ascent = false # Bool to start the reset process once the player goes back on the floor after jumping
var doubleSaut = false # Bool to check if the player jumped a second time
var gravityModifier = 1 # float to add to gravity while in the air
var jumpBuffer = false # Bool buffer to make the jump more satisfying
var onFloor = false # Bool to check if the player is on the ground

var canAttack = true # Bool to check if the player can attack

var isDashing = false # Bool to check if the player is dashing
var dashOnce = false # Bool to prevent overuse of the dash
var airDash = false # Bool for the air dash

var onWall = false # Bool to check if the player is on the wall
var goingDownWall = false # Bool to check if the player is moving down when on a wall
var canCling = true # Bool to prevent excessive wall clings after having exited one
var left = false # Bools to set which direction the player is looking after a wall cling
var right = false
var wallJump = false # Bool to add the velocity when wall jumping
var inertiaWallJump = false # Bool to add inertia once a wall jump is made

var isHooked = false # Bool to check if the player has been hooked on a wall
@export var maxRopeLength: int # Length of the rope (same as the raycast)
var currentRopeLength # How much rope we show
var aimDirection = Vector2(0,0) # Direction the player is aiming with the right stick
var fireHook = false # Bool for the animation of the throw
var hookSpeed: float # Float to keep player speed when firing the hook in the air
var canHook = true # Bool to allow the use of the grappling hook

# Animation bools
var jumpDescentAnim = false # jump to say that the transition between ascent and descent has played out fully
var hasJumped = false # Bool that says if the player has jumped
var attack1 = false # Bools for the 3-hit attack
var attack2 = false
var attack3 = false
var isAttacking = false # Bool that checks if you are attacking
var finalAttack = false # Bool to stun you when you deliver the third attack
var airAttack = false # Bool to check if an air attack got triggered
var dashAnim = false # Bool for showing the dash animation


func _ready(): # Triggers once as soon as the scene is ready
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN # Hides the mouse
	cameraOriginalPosition = $Camera2D.position # Crown jewel of my failures
	currentRopeLength = maxRopeLength # Resets the length of the rope on first call


func _physics_process(delta):
	
	# Add the gravity.
	if not is_on_floor() and not isDashing and not onWall and fireHook == false and isHooked == false:
		velocity += get_gravity() * delta * gravityModifier # Makes player fall fast
		if velocity.y > 1600:
			velocity.y = 1600
	
	
	# Adds gravity if not jumping
	if not is_on_floor() and saute == false and not isDashing and not onWall and fireHook == false and isHooked == false:
		gravityModifier += 0.06
		onFloor = false
	
	if fireHook == true and not is_on_floor():
		velocity.y = 0
	
	if is_on_ceiling_only():
		saute = false
		$JumpAscentTimer.stop()
	
	
	# Resets values specific to the jump once back on the floor
	if is_on_floor() and ascent == false:
		$JumpAscentTimer.stop()
		$JumpBufferTimer.stop()
		saute = false
		JUMP_VELOCITY = ORIGINAL_JUMP_VELOCITY
		gravityModifier = 1
		jumpDescentAnim = false
		hasJumped = false
		doubleSaut = false
		inertiaWallJump = false
		if jumpBuffer:
			_buffer_jump()
			jumpBuffer = false
		if airDash:
			airDash = false
			dashOnce = false
			dashAnim = false
			isDashing = false
			$DashResetTimer.stop()
			$DashLengthTimer.stop()
			$DashAnimTimer.stop()
			$AirDashAnimTimer.stop()
			var dashResetVFX = DashRechargeVFXScene.instantiate()
			dashResetVFX.position = $PositionPlayer.global_position + Vector2(0, -20)
			add_sibling(dashResetVFX)
			if Input.get_axis('Move_left', 'Move_right') != 0:
				var directionDash = Input.get_axis('Move_left', 'Move_right') ## I DO NOT REMEMBER WHAT THIS WAS FOR AT ALL
	
	
	if is_on_floor() and saute == false: # Plays the landing vfx scene once the player touches the ground after being in the air
		if not onFloor:
			onFloor = true
			var landingVFX = LandingVFXScene.instantiate()
			landingVFX.position = $PositionPlayer.global_position + Vector2(0, -15)
			add_sibling(landingVFX)
	
	if Input.is_action_just_pressed('Jump') and saute == false and doubleSaut == true: # Handles the buffer for the jump
		jumpBuffer = true
		$JumpBufferTimer.start()
	
	
	# If the player presses jump while in the air
	## (MIGHT HAVE BEEN FIXED??) Seems like the player is stuck in the ascent animation during the second jump if the descent animation has played already
	if Input.is_action_just_pressed('Jump') and not is_on_floor() and doubleSaut == false and onWall == false:
		onFloor = false
		saute = true
		ascent = true
		hasJumped = true
		doubleSaut = true
		jumpDescentAnim = false
		fireHook = false
		$ResetJumpTimer.stop()
		$ResetJumpTimer.start()
		$JumpAscentTimer.stop()
		$JumpAscentTimer.start()
		JUMP_VELOCITY = ORIGINAL_JUMP_VELOCITY
		gravityModifier = 1
		if dashAnim:
			isDashing = false
			dashAnim = false
		# VFX for the double jump
		var DoubleJumpVFX = DoubleJumpVFXScene.instantiate()
		DoubleJumpVFX.position = $PositionPlayer.global_position - Vector2(30, 40)
		add_sibling(DoubleJumpVFX)
	
	if is_on_wall() and not is_on_floor() and canCling and ($RayCastCheckRightTop.is_colliding() or $RayCastCheckLeftTop.is_colliding()) and ($RayCastCheckLeftBottom.is_colliding() or $RayCastCheckRightBottom.is_colliding()): # Starts the wall cling when on a wall while in the air
		if not onWall:
			if _animated_sprite.flip_h == false:
				_animated_sprite.play('Wall_cling_right')
				_animated_sprite.position = Vector2(20, 40)
				left = true
				right = false
			else:
				_animated_sprite.play('Wall_cling_right')
				_animated_sprite.position = Vector2(-15, 40)
				left = false
				right = true
			onWall = true
			saute = false
			ascent = false
			doubleSaut = false
			fireHook = false
			isHooked = false
			$ResetJumpTimer.stop()
			$JumpAscentTimer.stop()
			jumpBuffer = false
			$DashLengthTimer.stop()
			$DashResetTimer.stop()
			if dashOnce:
				dashOnce = false
				var dashResetVFX = DashRechargeVFXScene.instantiate()
				dashResetVFX.position = $PositionPlayer.global_position + Vector2(0, -20)
				add_sibling(dashResetVFX)
				if isDashing == true:
					isDashing = false
					if _animated_sprite.flip_h == false:
						velocity.x += 30
					else:
						velocity.x -= 30
					
			$DashLengthTimer.stop()
			$DashResetTimer.stop()
			velocity.y = 0
			gravityModifier = 1
		
	
	if is_on_wall_only() and onWall == true: # Goes down when pressing down on a wall
		if Input.is_action_pressed('Look_down'):
			velocity.y = 300
			onWall = true
			goingDownWall = true
			if $RayCastCheckLeftBottom.is_colliding() or $RayCastCheckRightBottom.is_colliding():
				# print('start slide')
				_animated_sprite.play('Wall_slide_right')
			elif _animated_sprite.animation != 'Wall_cling_right':
				_animated_sprite.play('Wall_cling_right')
		elif Input.is_action_just_released('Look_down'):
			goingDownWall = false
			velocity.y = 0
			onWall = true
			if _animated_sprite.animation != 'Wall_cling_right':
				_animated_sprite.play('Wall_cling_right')
			
	
	if Input.is_action_just_released('Look_down') and onWall == true: # Here to ensure it properly stops, double checking basically
			# print('stop going down')
			goingDownWall = false
			velocity.y = 0
			onWall = true
			if _animated_sprite.flip_h == false:
				velocity.x = 2000
			else:
				velocity.x = -2000
			if _animated_sprite.animation != 'Wall_cling_right':
				_animated_sprite.play('Wall_cling_right')
	
	if $RayCastCheckLeftBottom.is_colliding() == false and right == true and onWall == true:
		velocity.y = 0
		goingDownWall = false
	elif $RayCastCheckRightBottom.is_colliding() == false and left == true and onWall == true:
		velocity.y = 0
		goingDownWall = false
	
	if is_on_wall() and onWall == true and Input.is_action_just_pressed('Jump') and canMove == true:
		saute = true
		ascent = true
		hasJumped = true
		canCling = false
		JUMP_VELOCITY = ORIGINAL_JUMP_VELOCITY
		$WallClingResetTimer.start()
		$ResetJumpTimer.start()
		$JumpAscentTimer.start()
		_animated_sprite.position = Vector2(0, 0)
		onWall = false
		wallJump = true
	
	if wallJump == true:
		wallJump = false
		inertiaWallJump = true
		$WallJumptimer.start()
		
		if _animated_sprite.flip_h == false:
			_animated_sprite.flip_h = true
		else:
			_animated_sprite.flip_h = false
	
	
	var Joystick = Input.get_axis('Move_left', 'Move_right')
	if is_on_floor() == false and inertiaWallJump == true and Joystick == 0 and dashOnce == false:
		if lookingLeft == true:
			velocity.x = 500
		elif lookingRight == true:
			velocity.x = -500
	elif Joystick != 0:
		inertiaWallJump = false
	
	if not is_on_wall() and onWall == true and goingDownWall == false: # When exiting the wall
		onWall = false
		canCling = false
		$WallClingResetTimer.start()
		_animated_sprite.position = Vector2(0, 0)
		_animated_sprite.play('Jump_fall')
		jumpDescentAnim = true
	
	
	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not isAttacking and fireHook == false:
		saute = true
		ascent = true
		hasJumped = true
		canCling = false
		$WallClingResetTimer.start()
		$ResetJumpTimer.start()
		$JumpAscentTimer.start()
		if not doubleSaut:
			var JumpVFX = JumpVFXScene.instantiate()
			JumpVFX.position = $PositionPlayer.global_position - Vector2(0, 30)
			JumpVFX.visible = true
			add_sibling(JumpVFX)
		if dashAnim:
			isDashing = false
			dashAnim = false
	
	# When the player releases the jump button while in the air, stop their ascent
	if Input.is_action_just_released('Jump') and saute == true:
		saute = false
		JUMP_VELOCITY = -15
		velocity.y = JUMP_VELOCITY
		$JumpAscentTimer.stop()
	
	
	# While the jump button is held, smoothe the jump curve over the course of the jump
	if  Input.is_action_pressed('Jump') and saute == true:
		JUMP_VELOCITY = JUMP_VELOCITY * 0.98
		velocity.y = JUMP_VELOCITY
	
	if fireHook == true and not is_on_floor():
		if hookSpeed == null or hookSpeed == 0:
			hookSpeed = velocity.x
			print('setting speed')
			print(velocity.x)
		if velocity.x <= 0:
			velocity.x = hookSpeed
		
	
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("Move_left", "Move_right")
	if direction != null and isAttacking == false and isDashing == false and canMove == true and fireHook == false and isHooked == false:
		# print('je bouge')
		if direction < 0.3 and direction > 0:
			direction = 0.3
		elif direction > -0.3 and direction < 0:
			direction = -0.3
		
		if abs(velocity.x) > SPEED:
			velocity.x = velocity.x * 0.95
		else:
			if onWall:
				if abs(direction) > 0.4:
					goingDownWall = false
					velocity.x = direction * SPEED
			else:
				velocity.x = direction * SPEED
	else:
		if abs(velocity.x) > SPEED:
			velocity.x = velocity.x * 0.95
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
	
	if direction > 0:
		lookingRight = true
		lookingLeft = false
	else:
		lookingLeft = true
		lookingRight = false
	
	if Input.is_action_just_pressed("Dash") and dashOnce == false and isAttacking == false and onWall == false and isHooked == false and fireHook == false:
		isDashing = true
		dashOnce = true
		dashAnim = true
		if not is_on_floor():
			$AirDashAnimTimer.start()
			airDash = true
			jumpDescentAnim = false
			if onWall:
				pass
			else:
				if $AnimatedSprite2D.flip_h == true:
					var airDashLeftVFX = AirDashLeftVFXScene.instantiate()
					airDashLeftVFX.position = $PositionPlayer.global_position + Vector2(0, -40)
					add_sibling(airDashLeftVFX)
				else:
					var airDashRightVFX = AirDashRightVFXScene.instantiate()
					airDashRightVFX.position = $PositionPlayer.global_position + Vector2(0, -40)
					add_sibling(airDashRightVFX)
		else:
			$DashAnimTimer.start()
			if $AnimatedSprite2D.flip_h == true:
				var dashGroundLeftVFX = DashGroundLeftVFXScene.instantiate()
				dashGroundLeftVFX.position = $PositionPlayer.global_position + Vector2(0, -40)
				add_sibling(dashGroundLeftVFX)
			else:
				var dashGroundRightVFX = DashGroundRightVFXScene.instantiate()
				dashGroundRightVFX.position = $PositionPlayer.global_position + Vector2(0, -40)
				add_sibling(dashGroundRightVFX)
		$DashLengthTimer.start()
		$SmoothTransitionDashTimer.start()
		_animated_sprite.play('Dash')
		
	elif Input.is_action_just_pressed("Dash") and dashOnce == false and isAttacking == true and onWall == false and canMove and isHooked == false and fireHook == false:
		isDashing = true
		dashOnce = true
		dashAnim = true
		isAttacking = false
		attack1 = false
		attack2 = false
		canAttack = true
		if $AnimatedSprite2D.flip_h == true:
			var dashGroundLeftVFX = DashGroundLeftVFXScene.instantiate()
			dashGroundLeftVFX.position = $PositionPlayer.global_position + Vector2(0, -40)
			add_sibling(dashGroundLeftVFX)
		else:
			var dashGroundRightVFX = DashGroundRightVFXScene.instantiate()
			dashGroundRightVFX.position = $PositionPlayer.global_position + Vector2(0, -40)
			add_sibling(dashGroundRightVFX)
		
		if lookingRight == true and isDashing == true:
			_animated_sprite.flip_h = false
			velocity.x = 400
		elif lookingLeft == true and isDashing == true:
			_animated_sprite.flip_h = true
			velocity.x = -400
		$DashLengthTimer.start()
		$DashAnimTimer.start()
		_animated_sprite.play('Dash')
	
	if isDashing == true:
		if not onWall:
			if _animated_sprite.flip_h == false and direction != 0:
				velocity += Vector2(380, 0)
				velocity.y = 0
			elif _animated_sprite.flip_h == true and direction != 0:
				velocity += Vector2(-380, 0)
				velocity.y = 0
			elif _animated_sprite.flip_h == false and direction == 0:
				velocity = Vector2(1800, 0)
				velocity.y = 0
			elif _animated_sprite.flip_h == true and direction == 0:
				velocity = Vector2(-1800, 0)
				velocity.y = 0
		else:
			if _animated_sprite.animation == 'airDash' and direction != 0:
				velocity += Vector2(380, 0)
				velocity.y = 0
			elif _animated_sprite.flip_h == false and direction != 0:
				velocity += Vector2(-380, 0)
				velocity.y = 0
			elif _animated_sprite.flip_h == true and direction == 0:
				velocity = Vector2(1800, 0)
				velocity.y = 0
			elif _animated_sprite.flip_h == false and direction == 0:
				velocity = Vector2(-1800, 0)
				velocity.y = 0
	
	# Disables for a fraction of a second the player collisions to go through one-way platforms
	if Input.is_action_pressed('Look_down') and Input.is_action_just_pressed('Drop_through') and is_on_floor() and isAttacking == false and fireHook == false:
		gravityModifier = 2.5
		if $RayCastCheckGround.is_colliding():
			var collider = $RayCastCheckGround.get_collider()
			var cell = collider.local_to_map($RayCastCheckGround.get_collision_point())
			if cell == Vector2i(2, 2) or cell == Vector2i(1, 2) or cell == Vector2i(0, 2):
				$CollisionShape2D.disabled = true
				$DropThroughTimer.start()
		elif $RayCastCheckGround2.is_colliding():
			var collider2 = $RayCastCheckGround2.get_collider()
			var cell2 = collider2.local_to_map($RayCastCheckGround2.get_collision_point())
			if cell2 == Vector2i(2, 2) or cell2 == Vector2i(1, 2) or cell2 == Vector2i(0, 2):
				$CollisionShape2D.disabled = true
				$DropThroughTimer.start()
	
	aimDirection.x = -Input.get_action_strength('Move_left') + Input.get_action_strength('Move_right')
	aimDirection.y = +Input.get_action_strength('Look_down') - Input.get_action_strength('Look_up')
	
	if Input.is_action_just_pressed('Grapple_gamepad') and onWall == false and isAttacking == false and airAttack == false and fireHook == false and canHook == true:
		_hook_gamepad()
		fireHook = true
		canAttack = false
		canHook = false
		_animated_sprite.play('Throw_begin')
		$GrapplingHookResetTimer.start()
		$BetweenGrapplingHookTimer.start()
	
	if Input.is_action_just_pressed('Grapple_mouse') and onWall == false and isAttacking == false and airAttack == false and fireHook == false and canHook == true:
		_hook_mouse()
		fireHook = true
		canAttack = false
		canHook = false
		_animated_sprite.play('Throw_begin')
		$GrapplingHookResetTimer.start()
		$BetweenGrapplingHookTimer.start()
	
	move_and_slide()




func _process(delta):
	
	# Changes player sprites following movement
	var direction = Input.get_axis('Move_left', 'Move_right')
	
	if abs(direction) < 0.6 and direction != 0 and is_on_floor() and attack1 == false and attack2 == false and attack3 == false and finalAttack == false and airAttack == false and dashAnim == false and canMove and fireHook == false and isHooked == false: # Depending on player speed, plays the idle, walk or run animation
		_animated_sprite.play('Walk')
		
	elif abs(direction) >= 0.6 and is_on_floor() and attack1 == false and attack2 == false and attack3 == false and finalAttack == false and airAttack == false and dashAnim == false and canMove and fireHook == false and isHooked == false:
		_animated_sprite.play('Run')
		
	elif is_on_floor() and attack1 == false and attack2 == false and attack3 == false and finalAttack == false and airAttack == false and dashAnim == false and canMove and fireHook == false and isHooked == false:
		_animated_sprite.play("Idle")
		# print('je idle')
		
	
	if not isAttacking and not airAttack and dashAnim == false and not onWall and fireHook == false:
		if direction > 0: # Flips sprites depending on last pressed direction
			_animated_sprite.flip_h = false
		elif direction < 0:
			_animated_sprite.flip_h = true
	
	# STUPID FUNCTION THAT SERVES JUST ABOUT 0 PURPOSE
	#if not isAttacking and not airAttack:
		#if direction > 0 and droite == false:
			#$Camera2D.global_position.x += 1000
			#droite = true
			#gauche = false
			#print('droite')
		#elif direction < 0 and gauche == false:
			#$Camera2D.global_position.x -= 1000
			#gauche = true
			#droite = false
			#print('gauche')
		#else:
			#$Camera2D.position = cameraOriginalPosition
	
	# Changes player sprite to the jumping one in order
	if velocity.y < -15 and saute == true and not is_on_floor() and not isAttacking and not airAttack and dashAnim == false and fireHook == false: # PLays the ascent part of the jump
		_animated_sprite.play('Jump_start')
	
	if velocity.y > -15 and jumpDescentAnim == false and hasJumped == true and airAttack == false and dashAnim == false and onWall == false and fireHook == false:
		_animated_sprite.play('Jump_transition')
		jumpDescentAnim = true
	
	if velocity.y > 10 and jumpDescentAnim == false and hasJumped == false and not airAttack and dashAnim == false and onWall == false and fireHook == false:
		_animated_sprite.play('Jump_fall')
		jumpDescentAnim = true
	
	
	# Makes the player attack when the attack button is pressed
	if Input.is_action_just_pressed('Attack') and is_on_floor() and attack1 == false and attack2 == false and attack3 == false and finalAttack == false and canAttack == true:
		_animated_sprite.play('Attack1')
		$BetweenAttacksTimer.start()
		canAttack = false
		attack1 = true
		isAttacking = true
		velocity.x = 0
		$AttackCollisionArea/AttackCollisionBeginTimer.start()
	
	elif Input.is_action_just_pressed('Attack') and is_on_floor() and attack1 == true and attack2 == false and attack3 == false and finalAttack == false and canAttack == true:
		_animated_sprite.play('Attack2')
		$AttackResetTimer.stop()
		$BetweenAttacksTimer.start()
		canAttack = false
		attack2 = true
		isAttacking = true
		$AttackCollisionArea/AttackCollisionBeginTimer.stop()
		$AttackCollisionArea/CollisionShapeAttackLeft.disabled = true
		$AttackCollisionArea/CollisionShapeAttackRight.disabled = true
		$AttackCollisionArea/Attack2CollisionBeginTimer.start()
	
	elif Input.is_action_just_pressed('Attack') and is_on_floor() and attack1 == true and attack2 == true and attack3 == false and finalAttack == false and canAttack == true:
		_animated_sprite.play('Attack3')
		$AttackResetTimer.stop()
		$BetweenAttacksTimer.start()
		canAttack = false
		attack3 = true
		finalAttack = true
		isAttacking = true
		$AttackCollisionArea/Attack2CollisionBeginTimer.stop()
		$AttackCollisionArea/CollisionShapeAttackLeft.disabled = true
		$AttackCollisionArea/CollisionShapeAttackRight.disabled = true
		$AttackCollisionArea/Attack3CollisionBeginTimer.start()
	
	
	# Makes the player attack if the attack button is pressed in the air
	if Input.is_action_just_pressed("Attack") and not is_on_floor() and airAttack == false and not onWall and fireHook == false:
		_animated_sprite.play('Air_attack')
		airAttack = true
		$AirAttackTimer.start()
	
	if $AnimatedSprite2D.animation == 'Air_attack' and is_on_floor():
			$AirAttackTimer.stop()
			airAttack = false
	elif $AnimatedSprite2D.animation == 'Air_attack' and ascent == true and doubleSaut == true:
		$AirAttackTimer.stop()
		airAttack = false
		
	## Tried to make a camera movement work, it didn't
	# Moves camera following player up and down input
	#if Input.is_action_pressed('Look_down') and not Input.is_action_pressed('Move_left') and not Input.is_action_pressed('Move_right') and is_on_floor() and look == false and isAttacking == false and isDashing == false:
		#if look == false:
			#$LookDownTimer.start()
		# print('je vais regarder dans 1.5s')
		#look = true
	#else:
		#$LookDownTimer.stop()
	#
	#if Input.is_action_pressed('Look_up') and not Input.is_action_pressed('Move_left') and not Input.is_action_pressed('Move_right') and is_on_floor() and look == false and isAttacking == false and isDashing == false:
		#if look == false:
			#$LookUpTimer.start()
		# print('je vais regarder dans 1.5s')
		#look = true
	#else:
		#$LookDownTimer.stop()
	#
	#
	# Puts camera back to where it was after looking up or down
	#if Input.is_action_just_released('Look_down') and isLooking == true:
		#$Camera2D.global_position = $Camera2D.global_position - Vector2(0, 150)
		#isLooking = false
		#look = false
	#elif Input.is_action_just_released('Look_up') and isLooking == true:
		#$Camera2D.global_position = $Camera2D.global_position + Vector2(0, 150)
		#isLooking = false 
		#look = false
	
	
	## DEBUG ONLY (REMOVE BEFORE END OF PROJECT)
	if Input.is_action_just_pressed('Reset'):
		get_tree().reload_current_scene()
	


func _input(event):
	if ((event is InputEventKey or event is InputEventMouseButton) and event.is_pressed()) or event is InputEventMouseMotion:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Shows
		
	if (event is InputEventJoypadButton or event is InputEventJoypadMotion) and event.is_pressed():
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN # Hides the mouse

func _buffer_jump(): # Provides a 0.05s buffer for the player to jump before actually hitting the ground
	saute = true
	ascent = true
	hasJumped = true
	doubleSaut = false
	look = false
	$ResetJumpTimer.start()
	$JumpAscentTimer.start()
	var JumpVFX = JumpVFXScene.instantiate()
	JumpVFX.position = $PositionPlayer.global_position - Vector2(0, 30)
	add_sibling(JumpVFX)

func _hook_gamepad():
	if aimDirection.x < 0:
		_animated_sprite.flip_h = true
	elif aimDirection.x > 0:
		_animated_sprite.flip_h = false
	
	
	if _animated_sprite.flip_h == false:
		if aimDirection == Vector2(0, 0):
			aimDirection = Vector2(1, 0)
		elif aimDirection.x < 0:
			if aimDirection.y > 0:
				aimDirection = Vector2(0, 1)
			elif aimDirection.y < 0:
				aimDirection = Vector2(0, -1)
			else:
				aimDirection = Vector2(1, 0)
		$RayCastGrapplingHookRight.target_position = aimDirection.normalized() * maxRopeLength
	else:
		if aimDirection == Vector2(0, 0):
			aimDirection = Vector2(-1, 0)
		elif aimDirection.x > 0:
			if aimDirection.y > 0:
				aimDirection = Vector2(0, 1)
			elif aimDirection.y < 0:
				aimDirection = Vector2(0, -1)
			else:
				aimDirection = Vector2(-1, 0)
		$RayCastGrapplingHookLeft.target_position = aimDirection.normalized() * maxRopeLength


func _hook_mouse():
	if get_global_mouse_position().x > position.x :
		_animated_sprite.flip_h = false
		$RayCastGrapplingHookRight.look_at(get_global_mouse_position())
	elif get_global_mouse_position().x < position.x :
		_animated_sprite.flip_h = true
		$RayCastGrapplingHookLeft.look_at(get_global_mouse_position())

# ALL FUNCTIONS RELATED TO TIMERS BELOW THIS POINT

func _on_jump_ascent_timer_timeout(): # After the maximum jump time, sets the saute bool to false
	saute = false
	$JumpAscentTimer.stop()


func _on_reset_jump_timer_timeout(): # After beginning the jump, sets the ascent bool to false
	ascent = false
	onFloor = false


func _on_look_down_timer_timeout(): # Once the down button is held for long enough
	look = true
	$LookDownTimer.stop()
	if isLooking == false:
		$Camera2D.global_position = $Camera2D.global_position + Vector2(0, 150) # Moves the camera
	isLooking = true


func _on_look_up_timer_timeout(): # Once the up button is held for long enough
	look = true
	$LookUpTimer.stop()
	if isLooking == false:
		$Camera2D.global_position = $Camera2D.global_position - Vector2(0, 150) # Moves the camera
	isLooking = true


func _on_animated_sprite_2d_animation_finished(): # Once an animation reaches its end
	if _animated_sprite.animation == 'Jump_transition' and not airAttack and not onWall and not fireHook: # If that animation was the jump transition
		_animated_sprite.play("Jump_fall")
	
	if _animated_sprite.animation == 'Attack1': # If that animation was an attack
		$AttackResetTimer.start()
	elif _animated_sprite.animation == 'Attack2':
		$AttackResetTimer.start()
	elif _animated_sprite.animation == 'Attack3':
		$AttackFinTimer.start()


func _on_attack_reset_timer_timeout(): # Timer after which an attack can be executed
	isAttacking = false
	attack1 = false
	attack2 = false
	attack3 = false

func _on_attack_fin_timer_timeout(): # Timer after which the player can act after performing the 3rd attack in their kit
	# print('fini')
	finalAttack = false
	isAttacking = false
	attack1 = false
	attack2 = false
	attack3 = false

func _on_air_attack_timer_timeout(): # Timer after which a player can attack again in the air
	airAttack = false


func _on_drop_through_timer_timeout(): # Timer that enables back the collision on the player after they dropped through one-way platforms
	$CollisionShape2D.disabled = false


func _on_between_attacks_timer_timeout(): # Timer to stop players from spamming the attack button, skipping active frames
	canAttack = true


func _on_jump_buffer_timer_timeout(): # Timer after which the player pressed the jump button too early and the buffer falls inactive
	jumpBuffer = false


func _on_dash_length_timer_timeout(): # Timer that adjusts how long the dash lasts
	isDashing = false
	if not airDash:
		$DashResetTimer.start()
	


func _on_dash_reset_timer_timeout(): # Timer that resets the ability to dash after a certain amount of time
	dashOnce = false
	# print($PositionPlayer.global_position)
	# print(global_position)
	var dashResetVFX = DashRechargeVFXScene.instantiate()
	dashResetVFX.position = $PositionPlayer.global_position + Vector2(0, -20)
	add_sibling(dashResetVFX)


func _on_dash_anim_timer_timeout(): # timer that stops the animation of the dash
	dashAnim = false


func _on_wall_cling_reset_timer_timeout():
	canCling = true


func _on_air_dash_anim_timer_timeout():
	dashAnim = false


func _on_wall_jumptimer_timeout():
	canMove = true
	wallJump = false


func _on_attack_collision_begin_timer_timeout():
	if _animated_sprite.flip_h == false:
		$AttackCollisionArea/CollisionShapeAttackRight.disabled = false
	else:
		$AttackCollisionArea/CollisionShapeAttackLeft.disabled = false
	$AttackCollisionArea/AttackCollisionTimer.start()


func _on_attack_2_collision_begin_timer_timeout():
	if _animated_sprite.flip_h == false:
		$AttackCollisionArea/CollisionShapeAttackRight.disabled = false
	else:
		$AttackCollisionArea/CollisionShapeAttackLeft.disabled = false
	$AttackCollisionArea/AttackCollisionTimer.start()


func _on_attack_3_collision_begin_timer_timeout():
	if _animated_sprite.flip_h == false:
		$AttackCollisionArea/CollisionShapeAttackRight.disabled = false
	else:
		$AttackCollisionArea/CollisionShapeAttackLeft.disabled = false
	$AttackCollisionArea/AttackCollisionTimer.start()


func _on_attack_collision_timer_timeout():
	$AttackCollisionArea/CollisionShapeAttackRight.disabled = true
	$AttackCollisionArea/CollisionShapeAttackLeft.disabled = true


func _on_grappling_hook_reset_timer_timeout(): # If the grappling hook touches nothing
	fireHook = false
	canAttack = true


func _on_between_grappling_hook_timer_timeout():
	canHook = true
	var grappleGetVFX = GrappleGetVFXScene.instantiate()
	grappleGetVFX.position = $PositionPlayer.global_position + Vector2(0, -30)
	add_sibling(grappleGetVFX)


func _on_smooth_transition_dash_timer_timeout():
	if Input.get_axis('Move_left', 'Move_right') != 0 and is_on_floor():
		_animated_sprite.play('Run')
	elif not is_on_floor() and not is_on_wall():
		_animated_sprite.play('Jump_fall')
	else:
		pass
