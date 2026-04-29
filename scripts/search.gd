extends RefCounted
class_name Search

const Zobrist = preload("res://scripts/zobrist.gd")
const SearchBoard = preload("res://scripts/search_board.gd")
const INFINITY = 10000

enum { EXACT, LOWERBOUND, UPPERBOUND }

var godot_board
var zobrist
var search_depth
var transposition_table = {}

func _init(_board, _depth) -> void:
	godot_board = _board
	search_depth = _depth
	zobrist = Zobrist.new()

func get_best_move(color):
	transposition_table.clear()

	var search_board = SearchBoard.from_godot_board(godot_board, color)
	var castling = search_board.get_castling_rights()
	var _hash = zobrist.compute_hash(godot_board, color, godot_board.en_passant_target, castling)

	var valid_moves = search_board.get_valid_moves(color)
	if valid_moves.is_empty():
		return null

	valid_moves = sort_moves(valid_moves, search_board)

	var best_score = -INFINITY
	var best_move = null
	var alpha = -INFINITY
	var beta = INFINITY

	var best_godot_move = null

	for move in valid_moves:
		var piece_data = move[0]
		var from_pos = move[1]
		var to_pos = move[2]
		var dest = search_board.get_piece(to_pos)
		var prev_ep = search_board.en_passant_target

		var state = search_board.simulate_move(from_pos, to_pos)
		var new_ep = search_board.en_passant_target
		var new_hash = _update_hash_for_move(_hash, piece_data, from_pos, to_pos, dest, prev_ep, new_ep)
		var enemy = search_board.get_opponent(color)
		var score = negmax(search_depth - 1, -beta, -alpha, enemy, new_hash, search_board)
		search_board.undo_simulated_move(state)
		if best_score <= score:
			best_score = score
			best_move = move

			var gp = _find_godot_piece(from_pos, piece_data)
			if gp != null:
				best_godot_move = [gp, to_pos]

		alpha = max(alpha, score)

	if best_godot_move == null:
		return null
	return best_godot_move

func negmax(depth, alpha, beta, color, _hash, search_board):
	var entry = transposition_table.get(_hash, null)
	if entry != null and entry.depth >= depth:
		if entry.flag == EXACT:
			return entry.score
		elif entry.flag == LOWERBOUND:
			alpha = max(alpha, entry.score)
		elif entry.flag == UPPERBOUND:
			beta = min(beta, entry.score)
		if alpha >= beta:
			return entry.score

	if depth == 0:
		return search_board.evaluate(color)

	var valid_moves = search_board.get_valid_moves(color)

	if valid_moves.is_empty():
		if search_board.is_king_in_check(color):
			return -INFINITY
		else:
			return 0

	valid_moves = sort_moves(valid_moves, search_board)

	var best_score = -INFINITY
	var original_alpha = alpha

	for move in valid_moves:
		var piece_data = move[0]
		var from_pos = move[1]
		var to_pos = move[2]
		var dest = search_board.get_piece(to_pos)
		var prev_ep = search_board.en_passant_target

		var state = search_board.simulate_move(from_pos, to_pos)
		var new_ep = search_board.en_passant_target
		var new_hash = _update_hash_for_move(_hash, piece_data, from_pos, to_pos, dest, prev_ep, new_ep)

		var enemy = search_board.get_opponent(color)
		var score = -negmax(depth - 1, -beta, -alpha, enemy, new_hash, search_board)
		search_board.undo_simulated_move(state)

		best_score = max(best_score, score)
		alpha = max(alpha, score)
		if alpha >= beta:
			break

	var flag = EXACT
	if best_score <= original_alpha:
		flag = UPPERBOUND
	elif best_score >= beta:
		flag = LOWERBOUND

	transposition_table[_hash] = {
		"score": best_score,
		"flag": flag,
		"depth": depth,
	}

	return best_score

func sort_moves(moves, search_board):
	var scored = []
	for move in moves:
		var piece_data = move[0]
		var to_pos = move[2]
		var dest = search_board.get_piece(to_pos)
		var score = 0
		if dest != null:
			score = SearchBoard.PIECE_VALUES.get(dest.type, 0) * 100 - SearchBoard.PIECE_VALUES.get(piece_data.type, 0)
		scored.append([move, score])

	scored.sort_custom(func(a, b): return a[1] > b[1])
	var result = []
	for s in scored:
		result.append(s[0])
	return result

func _update_hash_for_move(_hash, piece_data, from_pos, to_pos, dest_piece, prev_ep, new_ep):
	_hash ^= zobrist.piece_keys[zobrist._piece_type_to_index(piece_data.type)][zobrist._color_to_index(piece_data.color)][zobrist._square_index(from_pos)]
	_hash ^= zobrist.piece_keys[zobrist._piece_type_to_index(piece_data.type)][zobrist._color_to_index(piece_data.color)][zobrist._square_index(to_pos)]

	if dest_piece != null:
		_hash ^= zobrist.piece_keys[zobrist._piece_type_to_index(dest_piece.type)][zobrist._color_to_index(dest_piece.color)][zobrist._square_index(to_pos)]

	if prev_ep != null:
		_hash ^= zobrist.ep_keys[int(prev_ep.x)]
	if new_ep != null:
		_hash ^= zobrist.ep_keys[int(new_ep.x)]

	_hash ^= zobrist.side_key
	return _hash

func _find_godot_piece(pos, piece_data):
	for piece in godot_board.pieces:
		if piece.board_position == pos and piece.piece_type == piece_data.type and piece.color == piece_data.color:
			return piece
	return null
