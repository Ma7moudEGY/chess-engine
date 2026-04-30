extends RefCounted
class_name SearchBoard

const PIECE_VALUES = {
	Globals.PIECE_TYPES.PAWN: 100,
	Globals.PIECE_TYPES.KNIGHT: 320,
	Globals.PIECE_TYPES.BISHOP: 330,
	Globals.PIECE_TYPES.ROOK: 500,
	Globals.PIECE_TYPES.QUEEN: 900,
	Globals.PIECE_TYPES.KING: 20000,
}

const BISHOP_BEAM_INCREMENTS = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
const ROOK_BEAM_INCREMENTS = [[1, 0], [-1, 0], [0, 1], [0, -1]]
const KNIGHT_SPOT_INCREMENTS = [[2, 1], [2, -1], [-2, 1], [-2, -1], [1, 2], [1, -2], [-1, 2], [-1, -2]]
const KING_SPOT_INCREMENTS = [[1, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1]]

var grid = []
var white_king_pos = Vector2(4, 7)
var black_king_pos = Vector2(4, 0)
var en_passant_target = null
var active_color

static func from_godot_board(godot_board, color):
	var sb = SearchBoard.new()
	sb.grid = []
	for i in range(64):
		sb.grid.append(null)

	for piece in godot_board.pieces:
		var idx = int(piece.board_position.x) + int(piece.board_position.y) * 8
		sb.grid[idx] = {
			"type": piece.piece_type,
			"color": piece.color,
			"moved": piece.moved,
		}

	sb.white_king_pos = Vector2(godot_board.white_king_pos)
	sb.black_king_pos = Vector2(godot_board.black_king_pos)
	if godot_board.en_passant_target != null:
		sb.en_passant_target = Vector2(godot_board.en_passant_target)
	else:
		sb.en_passant_target = null
	sb.active_color = color

	return sb

func get_piece(pos):
	var idx = int(pos.x) + int(pos.y) * 8
	return grid[idx]

func _is_checking_discovered(piece, from_pos, to_pos, color):
	var king_pos = white_king_pos if color == Globals.COLORS.WHITE else black_king_pos
	var enemy = get_opponent(color)

	var all_dirs = BISHOP_BEAM_INCREMENTS + ROOK_BEAM_INCREMENTS
	for dir in all_dirs:
		var dx = dir[0]
		var dy = dir[1]
		
		if _is_on_ray(king_pos, from_pos, dx, dy):
			var cx = int(from_pos.x) + dx
			var cy = int(from_pos.y) + dy
			while cx >= 0 and cx < 8 and cy >= 0 and cy < 8:
				var p = grid[cx + cy * 8]
				if p != null:
					if p.color == enemy and _is_slider_threatening(p, dx, dy):
						if not _is_on_ray(king_pos, to_pos, dx, dy):
							return true
					break
				cx += dx
				cy += dy
	return false

func get_valid_moves(color):
	var moves = []
	var enemy = get_opponent(color)
	var king_pos = white_king_pos if color == Globals.COLORS.WHITE else black_king_pos

	var attacked_squares = _get_attacked_squares(enemy)
	var pinned_pieces = _compute_pins(color, king_pos)

	for y in range(8):
		for x in range(8):
			var p = grid[x + y * 8]
			if p == null or p.color != color:
				continue

			var from = Vector2(x, y)
			var is_king = p.type == Globals.PIECE_TYPES.KING
			var pin_dir = pinned_pieces.get(from, null)
			var pseudo = _get_pseudo_legal_moves(p, from)

			for to in pseudo:
				var passes = false

				if is_king:
					if not attacked_squares.has(to):
						passes = true
				elif pin_dir != null:
					if _is_on_ray(from, to, pin_dir[0], pin_dir[1]):
						passes = true
				else:
					if _is_checking_discovered(p, from, to, color):
						passes = false
					else:
						passes = true

				if passes:
					moves.append([p, from, to])
				else:
					var state = simulate_move(from, to)
					if not is_king_in_check(color):
						moves.append([p, from, to])
					undo_simulated_move(state)

	return moves

func simulate_move(from_pos, to_pos):
	var idx_from = int(from_pos.x) + int(from_pos.y) * 8
	var idx_to = int(to_pos.x) + int(to_pos.y) * 8

	var piece = grid[idx_from]
	var dest = grid[idx_to]
	var prev_moved = piece.moved
	var prev_type = piece.type
	var prev_ep = en_passant_target
	var rook_from = null
	var rook_to = null
	var rook_state = null
	var prev_white_king = Vector2(white_king_pos)
	var prev_black_king = Vector2(black_king_pos)
	var ep_captured = null
	var ep_captured_idx = -1

	if piece.type == Globals.PIECE_TYPES.PAWN and dest == null and en_passant_target != null and to_pos == en_passant_target:
		var ep_idx = int(en_passant_target.x) + int(en_passant_target.y) * 8
		ep_captured = grid[ep_idx]
		ep_captured_idx = ep_idx
		grid[ep_idx] = null

	grid[idx_to] = {"type": piece.type, "color": piece.color, "moved": true}
	grid[idx_from] = null

	if piece.type == Globals.PIECE_TYPES.KING and abs(int(to_pos.x) - int(from_pos.x)) == 2:
		var y = int(from_pos.y)
		if int(to_pos.x) > int(from_pos.x):
			rook_from = Vector2(7, y)
			rook_to = Vector2(int(from_pos.x) + 1, y)
		else:
			rook_from = Vector2(0, y)
			rook_to = Vector2(int(from_pos.x) - 1, y)

		var rook_idx_from = int(rook_from.x) + int(rook_from.y) * 8
		var rook_idx_to = int(rook_to.x) + int(rook_to.y) * 8
		var rook = grid[rook_idx_from]
		if rook != null:
			rook_state = rook.moved
			grid[rook_idx_to] = {"type": rook.type, "color": rook.color, "moved": true}
			grid[rook_idx_from] = null

	if piece.type == Globals.PIECE_TYPES.KING:
		if piece.color == Globals.COLORS.WHITE:
			white_king_pos = Vector2(to_pos)
		else:
			black_king_pos = Vector2(to_pos)

	var dir = -1 if piece.color == Globals.COLORS.WHITE else 1
	if piece.type == Globals.PIECE_TYPES.PAWN and int(to_pos.y) - int(from_pos.y) == dir * 2:
		en_passant_target = Vector2(int(to_pos.x), int(to_pos.y) - dir)
	else:
		en_passant_target = null

	if piece.type == Globals.PIECE_TYPES.PAWN:
		var promote_rank = 0 if piece.color == Globals.COLORS.WHITE else 7
		if int(to_pos.y) == promote_rank:
			grid[idx_to]["type"] = Globals.PIECE_TYPES.QUEEN

	return {
		"piece": piece,
		"dest": dest,
		"from_idx": idx_from,
		"to_idx": idx_to,
		"prev_moved": prev_moved,
		"prev_type": prev_type,
		"prev_ep": prev_ep,
		"rook_from": rook_from,
		"rook_to": rook_to,
		"rook_state": rook_state,
		"prev_white_king": prev_white_king,
		"prev_black_king": prev_black_king,
		"ep_captured": ep_captured,
		"ep_captured_idx": ep_captured_idx,
	}

func undo_simulated_move(state):
	grid[state.from_idx] = {
		"type": state.prev_type,
		"color": state.piece.color,
		"moved": state.prev_moved,
	}
	grid[state.to_idx] = state.dest

	if state.rook_from != null:
		var r_from = int(state.rook_from.x) + int(state.rook_from.y) * 8
		var r_to = int(state.rook_to.x) + int(state.rook_to.y) * 8
		grid[r_from] = {
			"type": Globals.PIECE_TYPES.ROOK,
			"color": state.piece.color,
			"moved": state.rook_state,
		}
		grid[r_to] = null

	white_king_pos = Vector2(state.prev_white_king)
	black_king_pos = Vector2(state.prev_black_king)
	en_passant_target = state.prev_ep

	if state.ep_captured != null:
		grid[state.ep_captured_idx] = state.ep_captured

func is_king_in_check(color):
	var king_pos = white_king_pos if color == Globals.COLORS.WHITE else black_king_pos
	return is_square_attacked(king_pos, get_opponent(color))

func is_square_attacked(pos, attacking_color):
	for y in range(8):
		for x in range(8):
			var p = grid[x + y * 8]
			if p != null and p.color == attacking_color:
				var threat = _get_threatened_squares(p, Vector2(x, y))
				if pos in threat:
					return true
	return false

func _get_attacked_squares(color):
	var attacked = {}
	for y in range(8):
		for x in range(8):
			var p = grid[x + y * 8]
			if p != null and p.color == color:
				var threats = _get_threatened_squares(p, Vector2(x, y))
				for sqaure in threats:
					attacked[sqaure] = true
	return attacked

func _is_on_ray(from, to, dx, dy):
	var diff_x = int(to.x) - int(from.x)
	var diff_y = int(to.y) - int(from.y)
	
	if dx == 0 and dy == 0:
		return false
	if dx != 0 and diff_x % dx != 0:
		return false
	if dy != 0 and diff_y % dy != 0:
		return false
	if dx != 0:
		var t = diff_x / dx
		if t <= 0:
			return false
		if dy != 0 and diff_y / dy != t:
			return false
	else:
		var t = diff_y / dy
		if t <= 0:
			return false
	return true

func _compute_pins(color, king_pos):
	var pins = {}
	var all_dirs = BISHOP_BEAM_INCREMENTS + ROOK_BEAM_INCREMENTS
	for dir in all_dirs:
		var dx = dir[0]
		var dy = dir[1]
		var cx = int(king_pos.x) + dx
		var cy = int(king_pos.y) + dy
		var pinned_pos = null

		while cx >= 0 and cx < 8 and cy >= 0 and cy < 8:
			var p = grid[cx + cy * 8]
			if p != null:
				if pinned_pos == null:
					if p.color == color:
						pinned_pos = Vector2(cx, cy)
					else:
						break
				else:
					if p.color != color and _is_slider_threatening(p, dx, dy):
						pins[pinned_pos] = [dx, dy]
						break
			cx += dx
			cy += dy
	return pins

func _is_slider_threatening(piece, dx, dy):
	var is_diagonal = (dx != 0 and dy != 0)
	if is_diagonal:
		return piece.type == Globals.PIECE_TYPES.BISHOP or piece.type == Globals.PIECE_TYPES.QUEEN
	else:
		return piece.type == Globals.PIECE_TYPES.ROOK or piece.type == Globals.PIECE_TYPES.QUEEN

func get_castling_rights():
	var rights = ""
	var wk = grid[4 + 7 * 8]
	var bk = grid[4 + 0 * 8]

	if wk != null and not wk.moved:
		var rh1 = grid[7 + 7 * 8]
		if rh1 != null and rh1.type == Globals.PIECE_TYPES.ROOK and not rh1.moved:
			rights += "K"
		var ra1 = grid[0 + 7 * 8]
		if ra1 != null and ra1.type == Globals.PIECE_TYPES.ROOK and not ra1.moved:
			rights += "Q"

	if bk != null and not bk.moved:
		var rh8 = grid[7 + 0 * 8]
		if rh8 != null and rh8.type == Globals.PIECE_TYPES.ROOK and not rh8.moved:
			rights += "k"
		var ra8 = grid[0 + 0 * 8]
		if ra8 != null and ra8.type == Globals.PIECE_TYPES.ROOK and not ra8.moved:
			rights += "q"

	return rights if rights != "" else "-"

func get_opponent(color):
	return Globals.COLORS.WHITE if color == Globals.COLORS.BLACK else Globals.COLORS.BLACK

func _get_pseudo_legal_moves(piece, pos):
	match piece.type:
		Globals.PIECE_TYPES.PAWN: return _pawn_moves(piece, pos)
		Globals.PIECE_TYPES.KNIGHT: return _knight_moves(piece, pos)
		Globals.PIECE_TYPES.BISHOP: return _sliding_moves(piece, pos, BISHOP_BEAM_INCREMENTS)
		Globals.PIECE_TYPES.ROOK: return _sliding_moves(piece, pos, ROOK_BEAM_INCREMENTS)
		Globals.PIECE_TYPES.QUEEN: return _sliding_moves(piece, pos, BISHOP_BEAM_INCREMENTS + ROOK_BEAM_INCREMENTS)
		Globals.PIECE_TYPES.KING: return _king_moves(piece, pos)
	return []

func _get_threatened_squares(piece, pos):
	match piece.type:
		Globals.PIECE_TYPES.PAWN: return _pawn_threats(piece, pos)
		Globals.PIECE_TYPES.KNIGHT: return _knight_moves(piece, pos)
		Globals.PIECE_TYPES.BISHOP: return _sliding_moves(piece, pos, BISHOP_BEAM_INCREMENTS)
		Globals.PIECE_TYPES.ROOK: return _sliding_moves(piece, pos, ROOK_BEAM_INCREMENTS)
		Globals.PIECE_TYPES.QUEEN: return _sliding_moves(piece, pos, BISHOP_BEAM_INCREMENTS + ROOK_BEAM_INCREMENTS)
		Globals.PIECE_TYPES.KING: return _king_threats(piece, pos)
	return []

func _pawn_moves(piece, pos):
	var moves = []
	var dir = -1 if piece.color == Globals.COLORS.WHITE else 1
	var x = int(pos.x)
	var y = int(pos.y)

	var one = y + dir
	if one >= 0 and one < 8 and grid[x + one * 8] == null:
		moves.append(Vector2(x, one))
		if not piece.moved:
			var two = y + dir * 2
			if two >= 0 and two < 8 and grid[x + two * 8] == null:
				moves.append(Vector2(x, two))

	for dx in [-1, 1]:
		var nx = x + dx
		var ny = y + dir
		if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
			var target = grid[nx + ny * 8]
			if target != null and target.color != piece.color:
				moves.append(Vector2(nx, ny))

	if en_passant_target != null:
		for dx in [-1, 1]:
			var ep = Vector2(x + dx, y + dir)
			if ep == en_passant_target:
				moves.append(ep)

	return moves

func _pawn_threats(piece, pos):
	var threats = []
	var dir = -1 if piece.color == Globals.COLORS.WHITE else 1
	var x = int(pos.x)
	var y = int(pos.y)

	for dx in [-1, 1]:
		var nx = x + dx
		var ny = y + dir
		if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
			threats.append(Vector2(nx, ny))

	return threats

func _knight_moves(piece, pos):
	var moves = []
	var x = int(pos.x)
	var y = int(pos.y)
	for inc in KNIGHT_SPOT_INCREMENTS:
		var nx = x + inc[0]
		var ny = y + inc[1]
		if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
			var target = grid[nx + ny * 8]
			if target == null or target.color != piece.color:
				moves.append(Vector2(nx, ny))
	return moves

func _sliding_moves(piece, pos, increments):
	var moves = []
	var x = int(pos.x)
	var y = int(pos.y)
	for inc in increments:
		var nx = x + inc[0]
		var ny = y + inc[1]
		while nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
			var target = grid[nx + ny * 8]
			if target != null:
				if target.color != piece.color:
					moves.append(Vector2(nx, ny))
				break
			moves.append(Vector2(nx, ny))
			nx += inc[0]
			ny += inc[1]
	return moves

func _king_moves(piece, pos):
	var moves = []
	var x = int(pos.x)
	var y = int(pos.y)
	for inc in KING_SPOT_INCREMENTS:
		var nx = x + inc[0]
		var ny = y + inc[1]
		if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
			var target = grid[nx + ny * 8]
			if target == null or target.color != piece.color:
				moves.append(Vector2(nx, ny))

	if not piece.moved:
		var rh = grid[7 + y * 8]
		if rh != null and rh.type == Globals.PIECE_TYPES.ROOK and rh.color == piece.color and not rh.moved:
			if grid[5 + y * 8] == null and grid[6 + y * 8] == null:
				moves.append(Vector2(6, y))

		var rl = grid[0 + y * 8]
		if rl != null and rl.type == Globals.PIECE_TYPES.ROOK and rl.color == piece.color and not rl.moved:
			if grid[1 + y * 8] == null and grid[2 + y * 8] == null and grid[3 + y * 8] == null:
				moves.append(Vector2(2, y))

	return moves

func _king_threats(piece, pos):
	var threats = []
	var x = int(pos.x)
	var y = int(pos.y)
	for inc in KING_SPOT_INCREMENTS:
		var nx = x + inc[0]
		var ny = y + inc[1]
		if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
			threats.append(Vector2(nx, ny))
	return threats
