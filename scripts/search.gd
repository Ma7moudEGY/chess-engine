extends RefCounted
class_name Search

const Evaluator = preload("res://scripts/evaluator.gd")
const MoveGenerator = preload("res://scripts/move_generator.gd")
const INFINITY = 10000

var board
var evaluator
var move_generator
var depth

func _init(_board, _depth) -> void:
    board = _board
    depth = _depth
    
func get_best_move(color):
    move_generator.status = color
    var valid_moves = move_generator.get_valid_moves()
    var best_score = -INFINITY
    var best_move = null
    for move in valid_moves:
        var piece = move[0]
        var to_pos = move[1]
        var state = move_generator.simulate_move(piece.board_position, to_pos)
        var enemy = get_opponent(color)
        var score = negmax(depth - 1, -INFINITY, INFINITY, enemy)
        move_generator.undo_simulated_move(state)
        if best_score <= score:
            best_score = score
            best_move = move
    return best_move

func negmax(depth, alpha, beta, color):
    if depth == 0:
        return evaluator.evaluate(board, color)
    move_generator.status = color
    var valid_moves = move_generator.get_valid_moves()
    if valid_moves.is_empty():
        if move_generator.is_king_in_check(color):
            return -INFINITY
        else:
            return 0
    for move in valid_moves:
        var piece = move[0]
        var to_pos = move[1]
        var state = move_generator.simulate_move(piece.board_position, to_pos)
        var enemy = get_opponent(color)
        var score = -negmax(depth - 1, -beta, -alpha, enemy)
        move_generator.undo_simulated_move(state)
        alpha = max(alpha, score)
        if alpha >= beta:
            return beta
    return alpha
func get_opponent(color):
    return Globals.COLORS.WHITE if color == Globals.COLORS.BLACK else Globals.COLORS.BLACK