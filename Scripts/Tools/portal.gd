@tool
extends StaticBody2D
class_name Portal

@export var pair_id: StringName = &"A"

# 콜론(:)으로 값 지정 → 실제 값이 1/2로 저장됨
@export_enum("Blue(Entrance):1", "Orange(Exit):2")
var portal_type: int = 1

@export var entrance_only: bool = true
@export var exit_offset: Vector2 = Vector2(0, -24)

# 속도 옵션
@export var keep_velocity: bool = true         # 속도 보존 켜기/끄기
@export var flip_velocity: bool = true         # 반대 방향으로 뒤집기
@export var velocity_scale: float = 1.0        # 속도 배수(부스트/감속)
@export var min_exit_speed: float = 0.0        # 최소 속도 보장(0이면 사용 안 함)

# 스킨(한 장짜리 시트 좌/우)
@export var atlas: Texture2D
@export var blue_on_left: bool = false         # 시트에서 파랑이 '왼쪽'이면 On

# 충돌 자동 세팅(원하면 Off)
@export var auto_config_collision: bool = true

@onready var area: Area2D = $Area2D
var sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("portal")

	# Sprite2D 자동 탐색(이름 달라도 OK)
	sprite = $Sprite2D if has_node("Sprite2D") else findSpriteChild()

	applySkin()                     # 미리보기 갱신(에디터/런타임 공통)

	# 에디터에선 여기서 종료(등록/시그널/마스크 건드리지 않음)
	if Engine.is_editor_hint():
		return

	if auto_config_collision:
		# 루트는 '벽'처럼만 존재, 아무것도 감지하지 않음
		collision_layer = 2
		collision_mask = 0
		# Area2D는 플레이어만 감지 (플레이어 Layer=1 가정)
		area.collision_layer = 0
		area.collision_mask = 1

	area.body_entered.connect(onAreaBodyEntered)

	PortalManager.registerPortal(self)
	print("[Portal ready] name=", name, " pair=", pair_id, " type=", portal_type)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	PortalManager.unregisterPortal(self)

# 에디터에서 값 바꾸면 한 프레임마다 미리보기 갱신(간단·안전)
func _process(_d: float) -> void:
	if Engine.is_editor_hint():
		applySkin()

func findSpriteChild() -> Sprite2D:
	for c in get_children():
		if c is Sprite2D:
			return c as Sprite2D
	return null

# ── 감지/텔레포트 ─────────────────────────────
func onAreaBodyEntered(body: Node) -> void:
	# 포탈/타일 등은 무시 → 포탈이 이동하는 문제 방지
	if body.is_in_group("portal"):
		return
	if not (body is CharacterBody2D or body is RigidBody2D):
		return

	# 입구 제한(필요 시 한쪽만)
	if entrance_only and portal_type != 1:
		return

	# 쿨다운
	if not PortalManager.checkTeleportAllowed(body):
		return

	# 목적지
	var dst: Node2D = PortalManager.getOtherPortal(self)
	if dst == null:
		print("[Portal] blocked: no destination (pair/type 확인)")
		return

	teleportBody(body, dst)
	PortalManager.markTeleport(body)
	print("[Portal] teleported to ", dst.name)

func teleportBody(body: Node, dst: Node2D) -> void:
	# 1) 위치 이동(출구 앞쪽으로)
	body.global_position = dst.to_global(exit_offset)

	# 2) 속도 보존/회전(선택)
	if not keep_velocity:
		return

	var rot := dst.global_rotation - global_rotation
	if flip_velocity:
		rot += PI  # 들어온 방향의 '정반대'로 뒤집기

	var exit_forward := Vector2.RIGHT.rotated(dst.global_rotation)

	if body is CharacterBody2D:
		var ch := body as CharacterBody2D
		var v := ch.velocity.rotated(rot) * velocity_scale
		if min_exit_speed > 0.0 and v.length() < min_exit_speed:
			v = exit_forward * min_exit_speed
		ch.velocity = v

	elif body is RigidBody2D:
		var rb := body as RigidBody2D
		var v := rb.linear_velocity.rotated(rot) * velocity_scale
		if min_exit_speed > 0.0 and v.length() < min_exit_speed:
			v = exit_forward * min_exit_speed
		rb.linear_velocity = v
		rb.sleeping = false

# ── 스킨 적용(한 장 시트의 좌/우 반쪽) ─────────────────
func applySkin() -> void:
	if sprite == null:
		return
	var tex: Texture2D = atlas if atlas != null else sprite.texture
	if tex == null:
		return

	sprite.texture = tex
	sprite.region_enabled = true

	var sz: Vector2i = tex.get_size()
	if sz.x <= 0 or sz.y <= 0:
		return

	var half_w := int(sz.x / 2)
	var rect_blue: Rect2i
	var rect_orange: Rect2i

	if blue_on_left:
		rect_blue   = Rect2i(0, 0, half_w, sz.y)        # 왼쪽 파랑
		rect_orange = Rect2i(half_w, 0, half_w, sz.y)   # 오른쪽 주황
	else:
		rect_orange = Rect2i(0, 0, half_w, sz.y)        # 왼쪽 주황
		rect_blue   = Rect2i(half_w, 0, half_w, sz.y)   # 오른쪽 파랑

	sprite.region_rect = rect_blue if portal_type == 1 else rect_orange
