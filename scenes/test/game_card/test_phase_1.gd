extends Control

@onready var game_card: Button = $GameCard
@onready var status_label: Label = $StatusLabel
#
#
#func _ready():
	#status_label.text = "Phase 1: 基础结构测试"
	#print("[TestPhase1] 测试场景已启动")
	#
	#game_card.card_selected.connect(_on_card_selected)
	#game_card.card_deselected.connect(_on_card_deselected)
	#game_card.card_confirmed.connect(_on_card_confirmed)
	#game_card.card_hover_started.connect(_on_card_hover_started)
	#game_card.card_hover_ended.connect(_on_card_hover_ended)
	#
	#print("=== 测试开始 ===")
	#print("请将鼠标悬停在卡片上")
#
#func _on_card_selected():
	#status_label.text = "卡片：悬停中"
	#print("[TestPhase1] card_selected - 鼠标进入卡片")
#
#func _on_card_deselected():
	#status_label.text = "卡片：未悬停"
	#print("[TestPhase1] card_deselected - 鼠标离开卡片")
#
#func _on_card_confirmed():
	#status_label.text = "卡片：被点击！"
	#print("[TestPhase1] card_confirmed - 卡片被点击")
#
#func _on_card_hover_started():
	#print("[TestPhase1] card_hover_started - 悬停动画开始")
#
#func _on_card_hover_ended():
	#print("[TestPhase1] card_hover_ended - 悬停动画结束")
