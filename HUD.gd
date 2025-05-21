extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var armor_bar = $ArmorBar
@onready var money_label = $MoneyLabel
@onready var faction_label = $FactionLabel
@onready var rank_label = $RankLabel
@onready var ammo_label = $AmmoLabel
@onready var weapon_icon = $WeaponIcon
@onready var death_screen = $DeathScreen
@onready var level_up_popup = $LevelUpPopup
@onready var promotion_popup = $PromotionPopup

func update_health(current, maximum):
    health_bar.max_value = maximum
    health_bar.value = current
    health_bar.get_node("Label").text = str(current) + "/" + str(maximum)

func update_armor(current, maximum):
    armor_bar.max_value = maximum
    armor_bar.value = current
    armor_bar.get_node("Label").text = str(current) + "/" + str(maximum)

func update_money(amount):
    money_label.text = "$" + str(amount)

func update_faction_info(faction_name, rank_name):
    faction_label.text = "Фракция: " + faction_name
    rank_label.text = "Ранг: " + rank_name

func update_ammo(current, max_ammo, spare):
    ammo_label.text = str(current) + " / " + str(spare)

func update_weapon_icon(weapon_type):
    match weapon_type:
        "pistol":
            weapon_icon.texture = preload("res://assets/icons/pistol.png")
        "assault_rifle":
            weapon_icon.texture = preload("res://assets/icons/rifle.png")
        "knife":
            weapon_icon.texture = preload("res://assets/icons/knife.png")
        _:
            weapon_icon.texture = null

func show_death_screen():
    death_screen.visible = true
    # Можно добавить таймер для автоматического скрытия

func hide_death_screen():
    death_screen.visible = false

func show_level_up_message(new_level):
    level_up_popup.get_node("Label").text = "Новый уровень! " + str(new_level)
    level_up_popup.visible = true
    await get_tree().create_timer(2.0).timeout
    level_up_popup.visible = false

func show_promotion_message(new_rank):
    promotion_popup.get_node("Label").text = "Повышение! " + new_rank
    promotion_popup.visible = true
    await get_tree().create_timer(2.0).timeout
    promotion_popup.visible = false
