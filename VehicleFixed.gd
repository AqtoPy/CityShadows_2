extends VehicleBody3D

class_name PlayerVehicle

## Настройки движения
@export var max_speed = 30.0
@export var engine_power = 600.0
@export var steering_sensitivity = 0.8
@export var max_steer_angle = 0.4
@export var brake_power = 10.0
@export var handbrake_power = 15.0
@export var drift_factor = 0.95  # 1.0 - полный дрифт, 0.0 - нет дрифта

## Настройки камеры
@export var third_person_offset = Vector3(0, 2.5, -6)
@export var camera_rotation_speed = 0.005

## Физические параметры
@export var mass = 1500.0
@export var suspension_stiffness = 50.0
@export var suspension_compression = 2.0
@export var suspension_damping = 10.0

## Состояние
var is_player_inside = false
var current_speed = 0.0
var is_drifting = false
var drift_angle = 0.0

## Узлы
@onready var camera_pivot = $CameraPivot
@onready var third_person_camera = $CameraPivot/ThirdPersonCamera
@onready var interaction_area = $InteractionArea
@onready var exit_position = $ExitPosition

func _ready():
    # Настройка физики
    mass = mass
    for wheel in get_children():
        if wheel is VehicleWheel3D:
            wheel.suspension_stiffness = suspension_stiffness
            wheel.suspension_compression = suspension_compression
            wheel.suspension_damping = suspension_damping
    
    # Настройка взаимодействия
    interaction_area.body_entered.connect(_on_body_entered)
    set_process_input(false)
    
    # Отключаем камеру машины при старте
    third_person_camera.clear_current()

func _physics_process(delta):
    if is_player_inside:
        current_speed = linear_velocity.length()
        handle_movement(delta)
        handle_drift(delta)

func _input(event):
    if is_player_inside:
        # Выход из машины
        if Input.is_action_just_pressed("exit_vehicle"):
            exit_vehicle()
        
        # Управление камерой
        if event is InputEventMouseMotion:
            camera_pivot.rotate_y(-event.relative.x * camera_rotation_speed)
            camera_pivot.rotation.y = clamp(
                camera_pivot.rotation.y,
                -max_steer_angle * 2,
                max_steer_angle * 2
            )

func handle_movement(delta):
    # Управление газом/тормозом
    var accelerate = Input.get_action_strength("accelerate")
    var brake = Input.get_action_strength("brake")
    var handbrake = Input.get_action_strength("handbrake")
    var steer = Input.get_axis("steer_right", "steer_left")
    
    # Применение сил
    engine_force = accelerate * engine_power
    brake = brake * brake_power
    
    # Ручной тормоз
    if handbrake > 0:
        brake = handbrake_power
        is_drifting = true
    else:
        is_drifting = false
    
    # Управление рулем
    steering = move_toward(
        steering,
        steer * max_steer_angle,
        delta * steering_sensitivity
    )
    
    # Ограничение скорости
    if current_speed > max_speed:
        engine_force = 0

func handle_drift(delta):
    if is_drifting and current_speed > 5.0:
        # Усиливаем занос при ручнике
        var drift_force = linear_velocity.normalized().cross(Vector3.UP) * drift_factor
        apply_central_force(drift_force * mass * current_speed * 0.1)
        
        # Визуальные эффекты дрифта (можно добавить частицы)
        drift_angle = lerp(drift_angle, steering * 2.0, delta * 2.0)
    else:
        drift_angle = lerp(drift_angle, 0.0, delta * 5.0)

func enter_vehicle(player):
    if is_player_inside: return
    
    is_player_inside = true
    player.set_process_input(false)
    player.visible = false
    
    # Включаем управление машиной
    set_process_input(true)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    third_person_camera.make_current()

func exit_vehicle():
    if !is_player_inside: return
    
    # Возвращаем управление игроку
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.global_transform = exit_position.global_transform
        player.visible = true
        player.set_process_input(true)
        player.get_node("Camera3D").make_current()
    
    # Сбрасываем управление машиной
    is_player_inside = false
    set_process_input(false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    engine_force = 0
    brake = 1.0
    steering = 0
    
    # Отключаем камеру машины
    third_person_camera.clear_current()

func _on_body_entered(body):
    if body.is_in_group("player") and Input.is_action_just_pressed("interact"):
        enter_vehicle(body)
