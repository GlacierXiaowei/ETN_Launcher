extends Node

enum GameStatus {
	NOT_INSTALLED,
	CHECKING_UPDATE,
	UPDATE_AVAILABLE,
	UPDATE_REQUIRED,
	UPDATE_FAILED,
	READY_TO_LAUNCH,
	RUNNING
}

var games: Dictionary = {}

func _ready() -> void:
	pass

func get_game_status(game_id: String) -> GameStatus:
	return games.get(game_id, GameStatus.NOT_INSTALLED)

func set_game_status(game_id: String, status: GameStatus) -> void:
	games[game_id] = status
