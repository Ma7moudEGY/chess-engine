extends RefCounted
class_name ai

var board

func _init(_board) -> void:
    board = _board

func get_best_move(valid_moves):
    var move = valid_moves.pick_random()
    return move