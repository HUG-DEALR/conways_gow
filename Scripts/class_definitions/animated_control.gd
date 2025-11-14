class_name AnimatedControl extends Node

signal entered

@export_group("Options")
@export var from_center: bool = true
@export var hover_animation: bool = true
@export var enter_animation: bool = false
@export var parallel_animations: bool = true
@export var properties: Array = [
	"scale",
	"position",
	"rotation",
	"size",
	"self_modulate",
]

@export_group("Hover Settings")
@export var hover_time: float = 0.1
@export var hover_delay: float = 0.0
@export var ignore_position: bool = false
@export var hover_position: Vector2 = Vector2.ZERO
@export var hover_transition: Tween.TransitionType
@export var hover_easing: Tween.EaseType
@export var hover_scale: Vector2 = Vector2.ONE
@export var hover_rotation: float
@export var hover_size: Vector2
@export var hover_modulate: Color = Color.WHITE

@export_group("Entrance Settings")
@export var wait_for: AnimatedControl
@export var entrance_time: float = 0.1
@export var entrance_delay: float = 0.0
@export var entrance_transition: Tween.TransitionType
@export var entrance_easing: Tween.EaseType
@export var entrance_scale: Vector2 = Vector2.ONE
@export var entrance_position: Vector2 = Vector2.ZERO
@export var entrance_rotation: float
@export var entrance_size: Vector2
@export var entrance_modulate: Color = Color.WHITE

var target: Control
var default_scale: Vector2
var hover_values: Dictionary
var default_values: Dictionary
var entrance_values: Dictionary

const immediate_transition: Tween.TransitionType = Tween.TRANS_LINEAR

func _ready() -> void:
	target = get_parent()
	call_deferred("setup")

func setup() -> void:
	if from_center:
		target.pivot_offset = target.size/2.0
	default_scale = target.scale
	default_values = {
		"scale": target.scale,
		"position": target.position,
		"rotation": target.rotation,
		"size": target.size,
		"self_modulate": target.modulate,
	}
	hover_values = {
		"scale": hover_scale,
		"position": target.position + hover_position,
		"rotation": target.rotation + deg_to_rad(hover_rotation),
		"size": hover_size,
		"self_modulate": hover_modulate,
	}
	entrance_values = {
		"scale": entrance_scale,
		"position": target.position + entrance_position,
		"rotation": target.rotation + deg_to_rad(entrance_rotation),
		"size": entrance_size,
		"self_modulate": entrance_modulate,
	}
	connect_signals_from_parent()
	if enter_animation:
		on_enter()
	else:
		entered.emit()

func on_enter() -> void:
	add_tween(entrance_values, true, 0.0, 0.0, immediate_transition, entrance_easing, false)
	if wait_for:
		pass
	else:
		add_tween(default_values, parallel_animations, entrance_time, entrance_delay, entrance_transition, entrance_easing, true)

func connect_signals_from_parent() -> void:
	if hover_animation:
		target.mouse_entered.connect(add_tween.bind(
				hover_values,
				parallel_animations,
				hover_time,
				hover_delay,
				hover_transition,
				hover_easing,
				false,
			)
		)
		target.mouse_exited.connect(add_tween.bind(
				default_values,
				parallel_animations,
				hover_time,
				hover_delay,
				hover_transition,
				hover_easing,
				false,
			)
		)
	if wait_for:
		wait_for.entered.connect(add_tween.bind(
				default_values,
				parallel_animations,
				entrance_time,
				entrance_delay,
				entrance_transition,
				entrance_easing,
				true,
			)
		)

func add_tween(values: Dictionary, parallel: bool, seconds: float, delay: float, transition: Tween.TransitionType, easing: Tween.EaseType, entering_animation: bool = false) -> void:
	if get_tree():
		var tween: Tween = get_tree().create_tween()
		tween.set_parallel(parallel)
		tween.pause()
		for property in properties:
			if not (ignore_position and property == "position"):
				tween.tween_property(target, str(property), values[property], seconds).set_trans(transition).set_ease(easing)
		await get_tree().create_timer(delay).timeout
		tween.play()
		if entering_animation:
			await tween.finished
			entered.emit()
