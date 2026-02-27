extends Node

@onready var label: Label = $Label

var http_request : HTTPRequest
var url: String = "https://atomgit.com/godothub/godot/releases/download/4.6.1-stable/Godot_v4.6.1-stable_export_templates.tpz"
var download_path: String = "user://downloads/Godot_v4.6.1-stable_export_templates.tpz"
var download_progress_bar_load = load("res://component/download_progress_bar.tscn")
var download_progress_bar


func _ready() -> void:
	http_request = VersionUtils.create_http_request(download_path)
	add_child(http_request)
	http_request.request(url)
	download_progress_bar = download_progress_bar_load.instantiate()
	download_progress_bar.http_request = http_request
	download_progress_bar.progress_changed.connect(_on_progress_changed)
	add_child(download_progress_bar)


func _on_progress_changed(current_bytes: int, total_bytes: int, speed: float) -> void:
	print("current: %d, total: %d, speed: %.2f" % [current_bytes, total_bytes, speed])
	var current_mb = current_bytes / 1024.0 / 1024.0
	var total_mb = total_bytes / 1024.0 / 1024.0
	var percent = 0.0
	if total_bytes > 0:
		percent = float(current_bytes) / float(total_bytes) * 100.0
	label.text = "下载: %.2f MB / %.2f MB (%.1f%%) - %.2f MB/s" % [current_mb, total_mb, percent, speed]
