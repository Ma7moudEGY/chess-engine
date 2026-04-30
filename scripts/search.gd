extends RefCounted
class_name Search

const Zobrist = preload("res://scripts/zobrist.gd")
const SearchBoard = preload("res://scripts/search_board.gd")
const Evaluator = preload("res://scripts/evaluator.gd")
const INFINITY = 10000

const NULL_MOVE_REDUCTION = 3

enum { EXACT, LOWERBOUND, UPPERBOUND }

var godot_board
var zobrist
var evaluator
var search_depth
var transposition_table = {}

func _init(_board, _depth) -> void:
	godot_board = _board
	search_depth = _depth
	zobrist = Zobrist.new()
	evaluator = Evaluator.new()

func get_best_move(color):
	var search_board = SearchBoard.from_godot_board(godot_board, color)
	var castling = search_board.get_castling_rights()
	var _hash = zobrist.compute_hash(godot_board, color, godot_board.en_passant_target, castling)

	var valid_moves = search_board.get_valid_moves(color)
	if valid_moves.is_empty():
		return null

	var overall_best_move = null
	var overall_best_score = -INFINITY

	for d in range(1, search_depth + 1):
		var depth_best_move = null
		var depth_best_score = -INFINITY
		var alpha = -INFINITY
		var beta = INFINITY

		var tt_entry = transposition_table.get(_hash, null)
		var tt_best = tt_entry.get("best_move", null) if tt_entry != null else null

		var ordered_moves = _order_with_tt(valid_moves, tt_best, search_board, color)

		for move in ordered_moves:
			var piece_data = move[0]
			var from_pos = move[1]
			var to_pos = move[2]
			var dest = search_board.get_piece(to_pos)
			var prev_ep = search_board.en_passant_target

			var state = search_board.simulate_move(from_pos, to_pos)
			var new_ep = search_board.en_passant_target
			var new_hash = _update_hash_for_move(_hash, piece_data, from_pos, to_pos, dest, prev_ep, new_ep)
			var enemy = search_board.get_opponent(color)
			var score = -negmax(d - 1, -beta, -alpha, enemy, new_hash, search_board)
			search_board.undo_simulated_move(state)

			if score > depth_best_score:
				depth_best_score = score
				depth_best_move = move

			alpha = max(alpha, score)

		if depth_best_score > overall_best_score:
			overall_best_score = depth_best_score
			overall_best_move = depth_best_move

		if abs(overall_best_score) >= INFINITY - 1000:
			break

	if overall_best_move == null:
		return null

	var gp = _find_godot_piece(overall_best_move[1], overall_best_move[0])
	return [gp, overall_best_move[2]] if gp != null else null

func negmax(depth, alpha, beta, color, _hash, search_board):
	var entry = transposition_table.get(_hash, null)
	if entry != null and entry.depth >= depth:
		var stored_score = entry.score
		if abs(stored_score) > INFINITY - 1000:
			stored_score = stored_score - sign(stored_score) * (entry.depth - depth)
		if entry.flag == EXACT:
			return stored_score
		elif entry.flag == LOWERBOUND:
			alpha = max(alpha, stored_score)
		elif entry.flag == UPPERBOUND:
			beta = min(beta, stored_score)
		if alpha >= beta:
			return alpha

	if depth == 0:
		return _quiesce(alpha, beta, color, _hash, search_board)

	if depth >= 4 and not search_board.is_king_in_check(color) and abs(alpha) < INFINITY - 1000 and abs(beta) < INFINITY - 1000:
		var null_hash = _hash ^ zobrist.side_key
		if search_board.en_passant_target != null:
			null_hash ^= zobrist.ep_keys[int(search_board.en_passant_target.x)]

		var enemy = search_board.get_opponent(color)
		var score = -negmax(depth - 1 - NULL_MOVE_REDUCTION, -beta, -beta + 1, enemy, null_hash, search_board)

		if score >= beta:
			return beta

	var valid_moves = search_board.get_valid_moves(color)

	if valid_moves.is_empty():
		if search_board.is_king_in_check(color):
			return -INFINITY + depth
		else:
			return 0

	valid_moves = _order_with_tt(valid_moves, entry.get("best_move", null) if entry != null else null, search_board, color)

	var best_score = -INFINITY
	var best_move_pos = null
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

		if score > best_score:
			best_score = score
			best_move_pos = [from_pos, to_pos]
		alpha = max(alpha, score)
		if alpha >= beta:
			break

	var flag = EXACT
	if best_score <= original_alpha:
		flag = UPPERBOUND
	elif best_score >= beta:
		flag = LOWERBOUND

	var store_score = best_score
	if abs(best_score) > INFINITY - 1000:
		store_score = best_score + sign(best_score) * depth

	var existing = transposition_table.get(_hash, null)
	if existing == null or depth >= existing.depth:
		transposition_table[_hash] = {
			"score": store_score,
			"flag": flag,
			"depth": depth,
			"best_move": best_move_pos
		}

	return best_score

func _quiesce(alpha, beta, color, _hash, search_board):
	var stand_pat = evaluator.evaluate(search_board, color)
	if stand_pat >= beta:
		return beta
	if alpha < stand_pat:
		alpha = stand_pat

	var capture_moves = []
	for move in search_board.get_valid_moves(color):
		var dest = search_board.get_piece(move[2])
		if dest != null:
			capture_moves.append(move)

	if capture_moves.is_empty():
		return stand_pat

	capture_moves = sort_moves(capture_moves, search_board, color)

	for move in capture_moves:
		var piece_data = move[0]
		var from_pos = move[1]
		var to_pos = move[2]
		var dest = search_board.get_piece(to_pos)
		var prev_ep = search_board.en_passant_target

		var state = search_board.simulate_move(from_pos, to_pos)
		var new_ep = search_board.en_passant_target
		var new_hash = _update_hash_for_move(_hash, piece_data, from_pos, to_pos, dest, prev_ep, new_ep)

		var enemy = search_board.get_opponent(color)
		var score = -_quiesce(-beta, -alpha, enemy, new_hash, search_board)
		search_board.undo_simulated_move(state)

		if score >= beta:
			return beta
		if score > alpha:
			alpha = score

	return alpha

func sort_moves(moves, search_board, color):
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

func _order_with_tt(moves, tt_best, search_board, color):
	var scored = []
	for move in moves:
		var piece_data = move[0]
		var to_pos = move[2]
		var from_pos = move[1]
		var dest = search_board.get_piece(to_pos)
		var score = 0

		if tt_best != null and from_pos == tt_best[0] and to_pos == tt_best[1]:
			score = 1000000

		if dest != null:
			score += SearchBoard.PIECE_VALUES.get(dest.type, 0) * 100 - SearchBoard.PIECE_VALUES.get(piece_data.type, 0)

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

func load_cache(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var result = json.parse(json_text)
	if result != OK:
		return

	var data = json.get_data()
	for key in data:
		var entry = data[key]
		var hash_key = int(key)
		var best = entry.get("best_move", null)
		if best != null and best is Array and best.size() == 2:
			best = [Vector2(best[0][0], best[0][1]), Vector2(best[1][0], best[1][1])]
		transposition_table[hash_key] = {
			"score": entry.get("score", 0),
			"flag": entry.get("flag", 0),
			"depth": entry.get("depth", 0),
			"best_move": best
		}

func save_cache(path):
	if transposition_table.is_empty():
		return

	var data = {}
	for key in transposition_table:
		var entry = transposition_table[key]
		var best = entry.get("best_move", null)
		if best != null:
			best = [[int(best[0].x), int(best[0].y)], [int(best[1].x), int(best[1].y)]]
		data[str(key)] = {
			"score": entry.get("score", 0),
			"flag": entry.get("flag", 0),
			"depth": entry.get("depth", 0),
			"best_move": best
		}

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(data))
	file.close()

func get_cache_size() -> int:
	return transposition_table.size()

func clear_cache():
	transposition_table.clear()
