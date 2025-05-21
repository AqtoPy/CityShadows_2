extends CharacterBody3D

class_name NPC

@export_category("Настройки NPC")
@export var npc_name: String = "Горожанин"
@export var dialogue_lines: Array[String] = [
    "Привет, странник.",
    "Не видел тебя раньше...",
    "Уходи, пока цел."
]
@export var interaction_distance: float = 2.5
@export var cooldown_time: float = 10.0  # Время между репликами

@export_group("Визуальные настройки")
@export var show_name_plate: bool = true
@export var name_plate_offset: Vector3 = Vector3(0, 2, 0)

var player_in_range: bool = false
var can_talk: bool = true
var current_player: Node = null

@onready var name_label = $NameLabel
@onready var dialogue_timer = $DialogueTimer
@onready var speech_bubble = $SpeechBubble

func _ready():
    # Настройка визуальных элементов
    if show_name_plate:
        name_label.text = npc_name
        name_label.position = name_plate_offset
    else:
        name_label.visible = false
    
    speech_bubble.visible = false
    
    # Подключаем сигналы области взаимодействия
    $InteractionArea.body_entered.connect(_on_player_entered)
    $InteractionArea.body_exited.connect(_on_player_exited)
    
    # Настраиваем область взаимодействия
    var collision_shape = $InteractionArea/CollisionShape3D
    if collision_shape:
        collision_shape.shape.radius = interaction_distance

func _process(_delta):
    if player_in_range and current_player:
        # Поворачиваем NPC к игроку (плавно)
        var direction = (current_player.global_position - global_position).normalized()
        var target_rotation = atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)

func _on_player_entered(body):
    if body.is_in_group("player") and can_talk:
        player_in_range = true
        current_player = body
        start_dialogue()

func _on_player_exited(body):
    if body.is_in_group("player"):
        player_in_range = false
        current_player = null
        hide_dialogue()

func start_dialogue():
    if not can_talk or dialogue_lines.is_empty():
        return
    
    # Выбираем случайную фразу
    var random_line = dialogue_lines[randi() % dialogue_lines.size()]
    
    # Показываем реплику
    show_speech_bubble(random_line)
    
    # Включаем кулдаун
    can_talk = false
    dialogue_timer.start(cooldown_time)

func show_speech_bubble(text: String):
    speech_bubble.visible = true
    speech_bubble.get_node("Label").text = text
    
    # Автоматически скрываем через 3 секунды
    await get_tree().create_timer(3.0).timeout
    if speech_bubble:
        speech_bubble.visible = false

func hide_dialogue():
    speech_bubble.visible = false

func _on_dialogue_timer_timeout():
    can_talk = true
    if player_in_range:
        start_dialogue()
