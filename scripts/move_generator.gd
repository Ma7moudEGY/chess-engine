extends RefCounted
class_name MoveGenerator

var board
var status

func _init(_board, _status) -> void:
	board = _board
	status = _status

func get_valid_moves():
	var valid_moves = []
	for piece in board.pieces:
		if piece.color == status:
			var candi_pos = piece.get_moveable_positions()
			candi_pos = unique(candi_pos)
			for pos in candi_pos:
				if valid_move(piece.board_position, pos):
					valid_moves.append([piece, pos])

	return valid_moves

func valid_move(from_pos, to_pos):
	var src_piece = board.get_piece(from_pos)
	if src_piece == null:
		return false

	if (to_pos not in src_piece.get_moveable_positions() and to_pos not in src_piece.get_threatened_positions()):
		return false

	if src_piece.piece_type == Globals.PIECE_TYPES.KING and abs(to_pos.x - from_pos.x) == 2:
		var enemy = Globals.COLORS.BLACK if status == Globals.COLORS.WHITE else Globals.COLORS.WHITE
		if is_square_attacked(from_pos, enemy):
			return false

		var step = 1 if to_pos.x > from_pos.x else -1
		var pass_sqaure = from_pos + Vector2(step, 0)
		if is_square_attacked(pass_sqaure, enemy):
			return false
		if is_square_attacked(to_pos, enemy):
			return false

	var state = simulate_move(from_pos, to_pos)
	var illegal = is_king_in_check(status)
	undo_simulated_move(state)

	return not illegal

func simulate_move(from_pos, to_pos):
	var piece = board.get_piece(from_pos)
	var dest_piece = board.get_piece(to_pos)
	var moved = piece.moved
	var prev_pos = piece.board_position
	var prev_type = piece.piece_type
	var rook = null
	var rook_from = null
	var rook_to = null
	var rook_prev_moved = null

	if piece.piece_type == Globals.PIECE_TYPES.PAWN and dest_piece == null and board.en_passant_target != null:
		if to_pos == board.en_passant_target and board.en_passant_pawn != null and board.en_passant_pawn.color != piece.color:
			dest_piece = board.en_passant_pawn

	if dest_piece != null:
		board.delete_piece(dest_piece, false)

	if piece.piece_type == Globals.PIECE_TYPES.KING and abs(to_pos.x - from_pos.x) == 2:
		var y = from_pos.y
		if to_pos.x > from_pos.x:
			rook_from = Vector2(7, y)
			rook_to = Vector2(from_pos.x + 1, y)
		else:
			rook_from = Vector2(0, y)
			rook_to = Vector2(from_pos.x - 1, y)

		rook = board.get_piece(rook_from)
		if rook != null:
			rook_prev_moved = rook.moved
			rook.move_position(rook_to)
			rook.moved = true

	piece.move_position(to_pos)

	return {
		"piece": piece,
		"dest_piece": dest_piece,
		"moved": moved,
		"prev_pos": prev_pos,
		"prev_type": prev_type,
		"rook": rook,
		"rook_from": rook_from,
		"rook_to": rook_to,
		"rook_prev_moved": rook_prev_moved
	}

func undo_simulated_move(state: Dictionary):
	var piece = state["piece"]
	var prev_pos = state["prev_pos"]
	var prev_moved = state["moved"]
	var prev_type = state["prev_type"]

	piece.move_position(prev_pos)
	piece.moved = prev_moved
	piece.piece_type = prev_type
	piece.update_sprite()

	var dest_piece = state["dest_piece"]
	if dest_piece != null:
		board.restore_piece(dest_piece)

	var rook = state["rook"]
	if rook != null:
		rook.move_position(state["rook_from"])
		rook.moved = state["rook_prev_moved"]

func is_king_in_check(to_check: Globals.COLORS):
	var king_pos = board.white_king_pos if to_check == Globals.COLORS.WHITE else board.black_king_pos

	for piece in board.pieces:
		if piece.color != to_check and king_pos in piece.get_threatened_positions():
			return true

	return false

func is_square_attacked(pos, col):
	for piece in board.pieces:
		if piece.color == col and pos in piece.get_threatened_positions():
			return true
	return false

func unique(arr: Array) -> Array:
	var dict = {}
	for a in arr:
		dict[a] = 1
	return dict.keys()