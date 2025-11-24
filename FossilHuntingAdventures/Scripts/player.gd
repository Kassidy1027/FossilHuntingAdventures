extends CharacterBody2D

# Public variable to control player speed 
@export var speed = 50 

var screen_size

# Function called at the beginning of the game
func _ready():
	screen_size = get_viewport_rect().size

# Function called once every frame
func _process(delta: float) -> void:
	var velocity = Vector2.ZERO
	
	if Input.is_action_pressed("right"):
		velocity.x += 1
	if Input.is_action_pressed("left"):
		velocity.x -= 1
	if Input.is_action_pressed("down"):
		velocity.y += 1
	if Input.is_action_pressed("up"):
		velocity.y -= 1

	# Starting the Player Movement animation
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	
	# Allows Collisions on the map 
	move_and_slide()
	
	# Setting the animation for the Player
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "Walk"
		$AnimatedSprite2D.flip_v = false
		
		$AnimatedSprite2D.flip_h = velocity.x < 0

	
