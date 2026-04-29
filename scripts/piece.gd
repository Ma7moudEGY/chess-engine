extends Node2D

@onready var sprite = $Sprite2D

const SPRITE_SIZE = 128
const CELL_SIZE = 90

const X_OFFSET = CELL_SIZE / 2.0
const Y_OFFSET = CELL_SIZE / 2.0

@export var piece_type: Globals.PIECE_TYPES
@export var color: Globals.COLORS
@export var board_position: Vector2

var value
var board_handle

@export var moved: bool

func init_piece(type: Globals.PIECE_TYPES, col: Globals.COLORS, board_pos: Vector2, board):
	piece_type = type
	color = col
	value = Globals.PIECE_VALUES[piece_type]
	board_position = board_pos
	board_handle = board
	moved = false

	update_sprite()

	update_position()


func update_position():
	if OS.get_thread_caller_id() == OS.get_main_thread_id():
		position = Vector2(X_OFFSET + board_position[0] * CELL_SIZE, Y_OFFSET + board_position[1] * CELL_SIZE) 

func update_sprite():
	if sprite and OS.get_thread_caller_id() == OS.get_main_thread_id():
		sprite.texture = load(Globals.SPRITE_MAPPING[color][piece_type])
		sprite.scale = Vector2(float(CELL_SIZE) / SPRITE_SIZE, float(CELL_SIZE) / SPRITE_SIZE)

func move_position(to_move: Vector2):
	var old_pos = board_position
	moved = true
	board_position = to_move
	board_handle.move_piece_in_map(self, old_pos, to_move)
	update_position()

	if piece_type == Globals.PIECE_TYPES.KING:
		board_handle.register_king(board_position, color)

func get_moveable_positions():
	match piece_type:
		Globals.PIECE_TYPES.PAWN: return pawn_move_pos()
		Globals.PIECE_TYPES.BISHOP: return bishop_threat_pos()
		Globals.PIECE_TYPES.ROOK: return rook_threat_pos()
		Globals.PIECE_TYPES.KNIGHT: return knight_threat_pos()
		Globals.PIECE_TYPES.QUEEN: return queen_threat_pos()
		Globals.PIECE_TYPES.KING: return king_move_pos()
		_: return []

func get_threatened_positions():
	match piece_type:
		Globals.PIECE_TYPES.PAWN: return pawn_threat_pos()
		Globals.PIECE_TYPES.BISHOP: return bishop_threat_pos()
		Globals.PIECE_TYPES.ROOK: return rook_threat_pos()
		Globals.PIECE_TYPES.KNIGHT: return knight_threat_pos()
		Globals.PIECE_TYPES.QUEEN: return queen_threat_pos()
		Globals.PIECE_TYPES.KING: return king_threat_pos()
		_: return []

const PAWN_SPOT_INCREMENTS_MOVE = [[0, 1]]
const PAWN_SPOT_INCREMENTS_FIRST_MOVE = [[0, 1], [0, 2]]
const PAWN_SPOT_INCREMENTS_TAKE = [[-1, 1], [1, 1]]

func pawn_threat_pos():
	var positions = []

	for inc in PAWN_SPOT_INCREMENTS_TAKE:
		var pos = board_handle.spot_search_threat(color, board_position[0], board_position[1],
		inc[0], inc[1] if color == Globals.COLORS.BLACK else -inc[1], true, false)

		if pos != null:
			positions.append(pos)

	return positions

func pawn_move_pos():
	var positions = []

	var increments = PAWN_SPOT_INCREMENTS_MOVE if moved else PAWN_SPOT_INCREMENTS_FIRST_MOVE
	for inc in increments:
		var pos = board_handle.spot_search_threat(color, board_position[0], board_position[1],
		inc[0], inc[1] if color == Globals.COLORS.BLACK else -inc[1], false, true)

		if pos != null:
			positions.append(pos)
		else:
			# something is blocking the move
			break

	for inc in PAWN_SPOT_INCREMENTS_TAKE:
		var pos = board_handle.spot_search_threat(color, board_position[0], board_position[1],
		inc[0], inc[1] if color == Globals.COLORS.BLACK else -inc[1], true, false)

		if pos != null:
			positions.append(pos)

	if board_handle.en_passant_target != null and board_handle.en_passant_pawn != null and board_handle.en_passant_pawn.color != color:
		for inc in PAWN_SPOT_INCREMENTS_TAKE:
			var ep_pos = Vector2(board_position[0] + inc[0], board_position[1] + (inc[1] if color == Globals.COLORS.BLACK else -inc[1]))
			if ep_pos == board_handle.en_passant_target and board_handle.get_piece(ep_pos) == null:
				positions.append(ep_pos)

	return positions

const BISHOP_BEAM_INCREMENTS = [[1, 1], [1, -1], [-1, 1], [-1, -1]]

func bishop_threat_pos():
	var positions = []

	for inc in BISHOP_BEAM_INCREMENTS:
		positions += board_handle.beam_search_threat(color, board_position[0], board_position[1],
		inc[0], inc[1])

	return positions

const ROOK_BEAM_INCREMENTS = [[1, 0], [-1, 0], [0, 1], [0, -1]]

func rook_threat_pos():
	var positions = []

	for inc in ROOK_BEAM_INCREMENTS:
		positions += board_handle.beam_search_threat(color, board_position[0], board_position[1],
		inc[0], inc[1])

	return positions

const KINGHT_SPOT_INCREMENTS = [[2, 1], [2, -1], [-2, 1], [-2, -1], [1, 2], [1, -2], [-1, 2], [-1, -2]]

func knight_threat_pos():
	var positions = []

	for inc in KINGHT_SPOT_INCREMENTS:
		var pos = board_handle.spot_search_threat(color, board_position[0], board_position[1],
		inc[0], inc[1])

		if pos != null:
			positions.append(pos)

	return positions

func queen_threat_pos():
	return rook_threat_pos() + bishop_threat_pos()

const KING_SPOT_INCREMENTS = [[1, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1]]

const KING_CASTLE_OFFSETS = [[2, 0], [-2, 0]]

func king_threat_pos():
	var positions = []

	for inc in KING_SPOT_INCREMENTS:
		var pos = board_handle.spot_search_threat(color, board_position[0], board_position[1],
			inc[0], inc[1])
		if pos != null:
			positions.append(pos)
	return positions

func king_move_pos():
	var positions = []

	check_castling(positions)
	
	return positions + king_threat_pos()

func check_castling(positions):
	if not moved and board_position.x == 4:
		var y = board_position.y
		var rook_right = board_handle.get_piece(Vector2(7, y))
		if rook_right != null and rook_right.piece_type == Globals.PIECE_TYPES.ROOK and rook_right.color == color and not rook_right.moved:
			if board_handle.get_piece(Vector2(5, y)) == null and board_handle.get_piece(Vector2(6, y)) == null:
				positions.append(Vector2(6, y))

		var rook_left = board_handle.get_piece(Vector2(0, y))
		if rook_left != null and rook_left.piece_type == Globals.PIECE_TYPES.ROOK and rook_left.color == color and not rook_left.moved:
			if board_handle.get_piece(Vector2(3, y)) == null and board_handle.get_piece(Vector2(2, y)) == null and board_handle.get_piece(Vector2(1, y)) == null:
				positions.append(Vector2(2, y))