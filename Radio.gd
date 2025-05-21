extends Node3D

class_name RadioItem

signal station_changed(station_index)
signal radio_toggled(is_on)

@export var stations: Array[AudioStream] = [
    preload("res://audio/radio/station1.ogg"),
    preload("res://audio/radio/station2.ogg"),
    preload("res://audio/radio/station3.ogg")
]

var current_station: int = 0
var is_radio_on: bool = false
var audio_player: AudioStreamPlayer3D

func _ready():
    audio_player = AudioStreamPlayer3D.new()
    add_child(audio_player)
    audio_player.stream = stations[current_station]
    audio_player.unit_size = 5.0  # Радиус слышимости

func toggle_radio():
    is_radio_on = !is_radio_on
    if is_radio_on:
        audio_player.play()
    else:
        audio_player.stop()
    radio_toggled.emit(is_radio_on)

func next_station():
    current_station = (current_station + 1) % stations.size()
    audio_player.stream = stations[current_station]
    if is_radio_on:
        audio_player.play()
    station_changed.emit(current_station)

func prev_station():
    current_station = (current_station - 1) % stations.size()
    audio_player.stream = stations[current_station]
    if is_radio_on:
        audio_player.play()
    station_changed.emit(current_station)

func get_current_station_name() -> String:
    return "Станция %d" % (current_station + 1)
