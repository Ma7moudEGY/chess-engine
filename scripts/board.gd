extends Node2D

@export var pieces = []
@export var piece_scene = preload("res://scenes/Piece.tscn")

@export var white_king_pos: Vector2
@export var black_king_pos: Vector2

var piece_map = {}

const CELL_SIZE = 90

func _ready() -> void:
	draw_board()
	init_pieces()


func draw_board():
	for x in range(8):
		for y in range(8):
			draw_cell(x, y)

func draw_cell(x, y):
	var rect = ColorRect.new()
	rect.color = Color(0.8, 0.6, 0.4) if (x + y) % 2 == 0 else Color(0.4, 0.3, 0.2)
	rect.size = Vector2(CELL_SIZE, CELL_SIZE)
	rect.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
	rect.z_index = -100
	add_child(rect)

func init_pieces():
	for piece_tuple in Globals.INITIAL_PIECE_SET_SINGLE:
		var piece_type = piece_tuple[0]
		var black_piece_pos = Vector2(piece_tuple[1], piece_tuple[2])
		var white_piece_pos = Vector2(piece_tuple[1], 8 - 1 - piece_tuple[2])

		var black_piece = piece_scene.instantiate()
		add_child(black_piece)
		black_piece.init_piece(piece_type, Globals.COLORS.BLACK, black_piece_pos, self)
		pieces.append(black_piece)
		_register_piece(black_piece)

		var white_piece = piece_scene.instantiate()
		add_child(white_piece)
		white_piece.init_piece(piece_type, Globals.COLORS.WHITE, white_piece_pos, self)
		pieces.append(white_piece)
		_register_piece(white_piece)

		if piece_type == Globals.PIECE_TYPES.KING:
			register_king(white_piece_pos, Globals.COLORS.WHITE)
			register_king(black_piece_pos, Globals.COLORS.BLACK)

func register_king(pos, col):
	match col:
		Globals.COLORS.WHITE:
			white_king_pos = pos

		Globals.COLORS.BLACK:
			black_king_pos = pos

func get_piece(pos: Vector2):
	return piece_map.get(_key(pos), null)

func _key(pos):
	return Vector2i(int(pos.x), int(pos.y))

func _register_piece(piece):
	piece_map[_key(piece.board_position)] = piece

func _unregister_piece(piece):
	piece_map.erase(_key(piece.board_position))

func move_piece_in_map(piece, from_pos, to_pos):
	piece_map.erase(_key(from_pos))
	piece_map[_key(to_pos)] = piece

func delete_piece(piece, free_piece):
	_unregister_piece(piece)
	pieces.erase(piece)
	if free_piece:
		piece.queue_free()
	else:
		piece.visible = false

func restore_piece(piece):
	if piece == null:
		return

	if piece in pieces:
		return

	pieces.append(piece)
	_register_piece(piece)
	piece.visible = true

func beam_search_threat(own_color, cur_x, cur_y, inc_x, inc_y):
	var threat_pos = []

	cur_x += inc_x
	cur_y += inc_y

	while cur_x >= 0 and cur_x < 8 and cur_y >= 0 and cur_y < 8:
		var cur_pos = Vector2(cur_x, cur_y)
		var cur_piece = get_piece(cur_pos)
		if cur_piece != null:
			if cur_piece.color != own_color:
				threat_pos.append(cur_pos)
			break
		threat_pos.append(cur_pos)
		cur_x += inc_x
		cur_y += inc_y

	return threat_pos

func spot_search_threat(own_color, cur_x, cur_y, inc_x, inc_y, threat_only = false, free_only = false):
	cur_x += inc_x
	cur_y += inc_y

	if cur_x >= 8 or cur_x < 0 or cur_y >= 8 or cur_y < 0:
		return

	var cur_pos = Vector2(cur_x, cur_y)
	var cur_piece = get_piece(cur_pos)

	if cur_piece != null:
		if free_only:
			return
		return cur_pos if cur_piece.color != own_color else null
	return cur_pos if not threat_only else null


func clone():
	var board = self.duplicate()
	for i in range(len(pieces)):
		var piece = pieces[i].clone(board)
		board.pieces[i] = piece

	return board