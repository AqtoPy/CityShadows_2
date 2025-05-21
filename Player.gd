extends CharacterBody3D

## Настройки игрока
@export var walk_speed = 5.0
@export var run_speed = 8.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.002

## Состояния игрока
enum PlayerState { NORMAL, AIMING, RELOADING, INTERACTING }
var current_state = PlayerState.NORMAL

## Характеристики игрока
var health = 100
var max_health = 100
var armor = 0
var max_armor = 100
var money = 500
var experience = 0
var level = 1
var reputation = 0  # Репутация во фракции

## Система фракций
enum Faction { NEUTRAL, POLICE, GANG, MILITARY }
var faction = Faction.NEUTRAL
var faction_rank = 0  # 0 - новичок, 1-5 - ранги
var faction_ranks = {
    Faction.POLICE: ["Рекрут", "Офицер", "Детектив", "Лейтенант", "Капитан"],
    Faction.GANG: ["Шестидесятник", "Боец", "Бригадир", "Правяка", "Авторитет"],
    Faction.MILITARY: ["Рядовой", "Ефрейтор", "Сержант", "Лейтенант", "Капитан"]
}

## Оружие и инвентарь
var current_weapon = null
var weapons = []  # Массив слотов оружия
var inventory = {}  # Предметы инвентаря

## Физика
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed = walk_speed
var is_running = false
var is_crouching = false

## Компоненты
@onready var camera = $Camera3D
@onready var hud = $Camera3D/HUD
@onready var interaction_ray = $Camera3D/InteractionRay
@onready var weapon_holder = $Camera3D/WeaponHolder

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    update_hud()
    initialize_default_weapons()

func initialize_default_weapons():
    # Добавляем стартовое оружие в зависимости от фракции
    match faction:
        Faction.POLICE:
            add_weapon("pistol", 12, 60)
        Faction.GANG:
            add_weapon("knife")
            add_weapon("pistol", 8, 40)
        Faction.MILITARY:
            add_weapon("assault_rifle", 30, 120)
        _:
            add_weapon("knife")

func add_weapon(weapon_type, ammo = 0, spare_ammo = 0):
    var weapon_data = {
        "type": weapon_type,
        "ammo": ammo,
        "max_ammo": get_max_ammo(weapon_type),
        "spare_ammo": spare_ammo,
        "damage": get_weapon_damage(weapon_type)
    }
    weapons.append(weapon_data)
    if current_weapon == null:
        switch_weapon(0)

func get_max_ammo(weapon_type):
    match weapon_type:
        "pistol": return 12
        "assault_rifle": return 30
        "shotgun": return 8
        _: return 0

func get_weapon_damage(weapon_type):
    match weapon_type:
        "pistol": return 25
        "assault_rifle": return 15
        "shotgun": return 40
        "knife": return 50
        _: return 0

func _input(event):
    # Управление камерой мышью
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
    
    # Взаимодействие с объектами
    if Input.is_action_just_pressed("interact"):
        try_interact()
    
    # Переключение оружия
    if Input.is_action_just_pressed("weapon_1") and weapons.size() > 0:
        switch_weapon(0)
    if Input.is_action_just_pressed("weapon_2") and weapons.size() > 1:
        switch_weapon(1)
    
    # Перезарядка
    if Input.is_action_just_pressed("reload") and current_weapon != null:
        reload_weapon()

func _physics_process(delta):
    # Гравитация
    if not is_on_floor():
        velocity.y -= gravity * delta
    
    # Прыжок
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
    
    # Бег и приседание
    is_running = Input.is_action_pressed("sprint")
    is_crouching = Input.is_action_pressed("crouch")
    
    # Движение
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if is_running and not is_crouching:
        current_speed = run_speed
    elif is_crouching:
        current_speed = walk_speed * 0.5
    else:
        current_speed = walk_speed
    
    if direction:
        velocity.x = direction.x * current_speed
        velocity.z = direction.z * current_speed
    else:
        velocity.x = move_toward(velocity.x, 0, current_speed)
        velocity.z = move_toward(velocity.z, 0, current_speed)
    
    move_and_slide()
    
    # Обновление HUD
    update_hud()

func update_hud():
    hud.update_health(health, max_health)
    hud.update_armor(armor, max_armor)
    hud.update_money(money)
    hud.update_faction_info(get_faction_name(), get_rank_name())
    
    if current_weapon != null:
        hud.update_ammo(current_weapon["ammo"], current_weapon["max_ammo"], current_weapon["spare_ammo"])
        hud.update_weapon_icon(current_weapon["type"])
    else:
        hud.update_ammo(0, 0, 0)
        hud.update_weapon_icon("none")

func get_faction_name():
    match faction:
        Faction.POLICE: return "Полиция"
        Faction.GANG: return "Банда"
        Faction.MILITARY: return "Армия"
        _: return "Гражданский"

func get_rank_name():
    if faction == Faction.NEUTRAL:
        return "Нет ранга"
    
    if faction_rank >= 0 and faction_rank < faction_ranks[faction].size():
        return faction_ranks[faction][faction_rank]
    return "Неизвестный ранг"

func try_interact():
    if interaction_ray.is_colliding():
        var collider = interaction_ray.get_collider()
        if collider.has_method("interact"):
            collider.interact(self)

func switch_weapon(index):
    if index >= 0 and index < weapons.size():
        current_weapon = weapons[index]
        # Здесь можно добавить анимацию смены оружия
        update_hud()

func reload_weapon():
    if current_weapon == null or current_weapon["spare_ammo"] <= 0:
        return
    
    var ammo_needed = current_weapon["max_ammo"] - current_weapon["ammo"]
    if ammo_needed <= 0:
        return
    
    var ammo_to_add = min(ammo_needed, current_weapon["spare_ammo"])
    current_weapon["ammo"] += ammo_to_add
    current_weapon["spare_ammo"] -= ammo_to_add
    
    # Здесь можно добавить анимацию перезарядки
    update_hud()

func take_damage(damage, damage_source = null):
    # Учет брони
    var damage_to_health = damage
    
    if armor > 0:
        var damage_to_armor = min(damage, armor)
        armor -= damage_to_armor
        damage_to_health = damage - damage_to_armor
    
    health -= damage_to_health
    
    # Проверка смерти
    if health <= 0:
        die(damage_source)
    
    update_hud()

func die(killer):
    # Обработка смерти игрока
    health = 0
    hud.show_death_screen()
    
    # Штраф за смерть
    money = max(0, money - 100)
    
    # Здесь можно добавить респавн или загрузку сохранения
    print("Игрок умер. Убийца: ", killer)

func heal(amount):
    health = min(health + amount, max_health)
    update_hud()

func add_armor(amount):
    armor = min(armor + amount, max_armor)
    update_hud()

func add_money(amount):
    money += amount
    update_hud()

func add_experience(amount):
    experience += amount
    # Проверка повышения уровня
    var exp_needed = level * 100
    if experience >= exp_needed:
        level_up()

func level_up():
    level += 1
    experience = 0
    max_health += 10
    health = max_health
    hud.show_level_up_message(level)

func change_faction(new_faction, initial_rank = 0):
    faction = new_faction
    faction_rank = initial_rank
    reputation = 0
    update_hud()

func promote():
    if faction == Faction.NEUTRAL:
        return
    
    if faction_rank < faction_ranks[faction].size() - 1:
        faction_rank += 1
        hud.show_promotion_message(get_rank_name())

func add_reputation(amount):
    if faction == Faction.NEUTRAL:
        return
    
    reputation += amount
    # Проверка на повышение
    if reputation >= (faction_rank + 1) * 100:
        promote()
        reputation = 0

func fire_weapon():
    if current_state == PlayerState.RELOADING or current_weapon == null:
        return
    
    if current_weapon["ammo"] <= 0:
        # Попытка стрелять без патронов - звук щелчка
        return
    
    current_weapon["ammo"] -= 1
    
    # Создание луча выстрела
    var ray = RayCast3D.new()
    ray.position = camera.position
    ray.target_position = Vector3(0, 0, -100)
    ray.collision_mask = 1  # Маска для столкновений
    
    # Проверка попадания
    if ray.is_colliding():
        var target = ray.get_collider()
        if target.has_method("take_damage"):
            target.take_damage(current_weapon["damage"], self)
    
    # Здесь можно добавить эффекты выстрела
    update_hud()
