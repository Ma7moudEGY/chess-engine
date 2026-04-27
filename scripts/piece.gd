extends Node2D

@onready var sprite = $Sprite2D

const SPRITE_SIZE = 128
const CELL_SIZE = 90

const X_OFFSET = CELL_SIZE / 2.0
const Y_OFFSET = CELL_SIZE / 2.0

@export var piece_type: Globals.PIECE_TYPES
@export var color: Globals.COLORS
@export var board_position: Vector2

var board_handle

@export var moved: bool

func init_piece(type: Globals.PIECE_TYPES, col: Globals.COLORS, board_pos: Vector2, board):
	piece_type = type
	color = col
	board_position = board_pos
	board_handle = board
	moved = false

	update_sprite()

	update_position()


func update_position():
	position = Vector2(X_OFFSET + board_position[0] * CELL_SIZE, Y_OFFSET + board_position[1] * CELL_SIZE) 

func update_sprite():
	if sprite:
		sprite.texture = load(Globals.SPRITE_MAPPING[color][piece_type])
		sprite.scale = Vector2(float(CELL_SIZE) / SPRITE_SIZE, float(CELL_SIZE) / SPRITE_SIZE)

func move_position(pos: Vector2):
	moved = true
	board_position = pos
	update_position()