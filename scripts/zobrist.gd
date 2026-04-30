extends RefCounted
class_name Zobrist

const PIECE_COUNT = 6
const COLOR_COUNT = 2
const SQUARE_COUNT = 64

var piece_keys = []
var side_key: int
var ep_keys = []
var castle_keys = []

const CACHE_SEED = 98273541

func _init() -> void:
	seed(CACHE_SEED)

	piece_keys = []
	for i in range(PIECE_COUNT):
		var color_arr = []
		for j in range(COLOR_COUNT):
			var sqaure_arr = []
			for k in range(SQUARE_COUNT):
				sqaure_arr.append(_rand64())
			color_arr.append(sqaure_arr)
		piece_keys.append(color_arr)

	side_key = _rand64()

	ep_keys = []
	for i in range(8):
		ep_keys.append(_rand64())

	castle_keys = {
		"K": _rand64(),
		"Q": _rand64(),
		"k": _rand64(),
		"q": _rand64()
	}

func compute_hash(board, active_color, en_passant_target, castling_rights: String) -> int:
	var _hash = 0
	for piece in board.pieces:
		var type_idx = _piece_type_to_index(piece.piece_type)
		var color_idx = _color_to_index(piece.color)
		var sqaure_idx = _square_index(piece.board_position)
		_hash ^= piece_keys[type_idx][color_idx][sqaure_idx]

	if active_color == Globals.COLORS.BLACK:
		_hash ^= side_key

	if en_passant_target != null:
		_hash ^= ep_keys[int(en_passant_target.x)]

	for ch in castling_rights:
		if castle_keys.has(ch):
			_hash ^= castle_keys[ch]

	return _hash

func get_castling_rights(board) -> String:
	return board._get_castling_rights()

func _find_king(board, color):
	return board._find_king(color)


func _piece_type_to_index(piece_type):
	match piece_type:
		Globals.PIECE_TYPES.ROOK: return 0
		Globals.PIECE_TYPES.KNIGHT: return 1
		Globals.PIECE_TYPES.BISHOP: return 2
		Globals.PIECE_TYPES.KING: return 3
		Globals.PIECE_TYPES.QUEEN: return 4
		Globals.PIECE_TYPES.PAWN: return 5
	return -1

func _color_to_index(color):
	return 0 if color == Globals.COLORS.BLACK else 1

func _square_index(pos):
	return int(pos.x) + int(pos.y) * 8

func _rand64():
	var low = randi()
	var high = randi()

	return (high << 32) | low