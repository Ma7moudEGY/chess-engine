extends Node2D

@export var pieces = []
@export var piece_scene = preload("res://scenes/Piece.tscn")

@export var white_king_pos: Vector2
@export var black_king_pos: Vector2

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

		var white_piece = piece_scene.instantiate()
		add_child(white_piece)
		white_piece.init_piece(piece_type, Globals.COLORS.WHITE, white_piece_pos, self)
		pieces.append(white_piece)

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
	for piece in pieces:
		if piece.board_position == pos:
			return piece