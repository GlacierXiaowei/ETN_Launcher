extends VideoStreamPlayer

@export var auto_start := true
@export var seamless_loop := true

var _restarting := false

func _ready():
	loop = false
	finished.connect(_on_finished)
	if auto_start:
		_warm_start()

func _warm_start():
	play()
	await get_tree().process_frame
	paused = true
	stream_position = 0.0
	paused = false

func _on_finished():
	if not seamless_loop:
		return
	if _restarting:
		return

	_restarting = true
	_restart()

func _restart():
	stop()
	await get_tree().process_frame
	stream_position = 0.0
	play()
	_restarting = false
