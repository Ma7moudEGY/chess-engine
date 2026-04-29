extends Node

enum PLAYER {ONE, TWO}
enum PLAYER_2_TYPE {HUMAN, AI}

enum COLORS {BLACK, WHITE}

enum PIECE_TYPES {ROOK, KNIGHT, BISHOP, KING, QUEEN, PAWN}

const SPRITE_MAPPING = {
	COLORS.BLACK : {
		PIECE_TYPES.ROOK: "res://assets/black-rook.png",
		PIECE_TYPES.KNIGHT: "res://assets/black-knight.png",
		PIECE_TYPES.BISHOP: "res://assets/black-bishop.png",
		PIECE_TYPES.QUEEN: "res://assets/black-queen.png",
		PIECE_TYPES.KING: "res://assets/black-king.png",
		PIECE_TYPES.PAWN: "res://assets/black-pawn.png"
	},
	COLORS.WHITE:{
		PIECE_TYPES.ROOK: "res://assets/white-rook.png",
		PIECE_TYPES.KNIGHT: "res://assets/white-knight.png",
		PIECE_TYPES.BISHOP: "res://assets/white-bishop.png",
		PIECE_TYPES.QUEEN: "res://assets/white-queen.png",
		PIECE_TYPES.KING: "res://assets/white-king.png",
		PIECE_TYPES.PAWN: "res://assets/white-pawn.png"
	},
}

const INITIAL_PIECE_SET_SINGLE = [
	[PIECE_TYPES.ROOK, 0, 0],
	[PIECE_TYPES.KNIGHT, 1, 0],
	[PIECE_TYPES.BISHOP, 2, 0],
	[PIECE_TYPES.QUEEN, 3, 0],
	[PIECE_TYPES.KING, 4, 0],
	[PIECE_TYPES.BISHOP, 5, 0],
	[PIECE_TYPES.KNIGHT, 6, 0],
	[PIECE_TYPES.ROOK, 7, 0],
	[PIECE_TYPES.PAWN, 0, 1],
	[PIECE_TYPES.PAWN, 1, 1],
	[PIECE_TYPES.PAWN, 2, 1],
	[PIECE_TYPES.PAWN, 3, 1],
	[PIECE_TYPES.PAWN, 4, 1],
	[PIECE_TYPES.PAWN, 5, 1],
	[PIECE_TYPES.PAWN, 6, 1],
	[PIECE_TYPES.PAWN, 7, 1]
]

const PIECE_VALUES = {
	PIECE_TYPES.PAWN: 1,
	PIECE_TYPES.KNIGHT: 3,
	PIECE_TYPES.BISHOP: 3,
	PIECE_TYPES.ROOK: 5,
	PIECE_TYPES.QUEEN: 9,
	PIECE_TYPES.KING: 100,
}