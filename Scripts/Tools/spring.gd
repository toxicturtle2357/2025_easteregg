extends AnimatableBody2D

@onready var area : Area2D = $Area2D#자식 Area2D를 찾아 변수에 담는다.
@onready var spring : AnimatedSprite2D = $AnimatedSprite2D

@export var strength : float = 400.0 #튀기는 세기
@export var direction : Vector2 = Vector2.UP #위로 튀기기
@export var cooldown : float = 0.125 #초단위


var ready_to_fire := true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area.body_entered.connect(on_area_2d_body_entered)
	#시작 시 idle 재생
	spring.play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func on_area_2d_body_entered(body: Node2D) -> void:
	#준비가 안 되었을 경우 
	if not ready_to_fire:
		return
	
	var dir := direction.normalized()#단위 벡터를 만들어 세기는 strength에 의해서만 조절되게 
	var impulse := dir*strength
	var triggered := false
	
	if body is CharacterBody2D:
		var ch := body as CharacterBody2D
		# ‘수직 패드’ 느낌: 낙하 중이면 속도를 끊고 위로 강하게
		ch.velocity.y = -abs(impulse.y)
		triggered = true
		# 대각/수평 패드를 원하면 윗줄 대신 아래줄 사용:
		# ch.velocity += impulse
	
	if triggered:
		await trigger_effects()

func trigger_effects() -> void:
	ready_to_fire = false
	
	#activate 재생
	spring.play("activated")
	
	#연속 발생 방지
	area.monitoring = false
	
	await get_tree().create_timer(cooldown).timeout
	
	#idle 복귀
	spring.play("idle")
	area.monitoring = true
	ready_to_fire = true
