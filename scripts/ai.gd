extends RefCounted
class_name ai

const Search = preload("res://scripts/search.gd")
const BookMoves = preload("res://scripts/book_moves.gd")
var status = Globals.COLORS.BLACK

@export var search_depth = 4

var board
var move_generator
var search

func _init(_board, _move_generator, cache_path = "") -> void:
	board = _board
	move_generator = _move_generator
	search = Search.new(board, search_depth)
	if cache_path != "":
		search.load_cache(cache_path)

func save_cache(path):
	search.save_cache(path)

func get_best_move():
	var pos_key = _build_pos_key()
	var valid_moves = move_generator.get_valid_moves()
	var book_move = BookMoves.lookup(pos_key, valid_moves)
	if book_move != null:
		var piece = book_move[0]
		var to_pos = book_move[1]
		return [piece, to_pos]
	return search.get_best_move(status)

func _build_pos_key() -> String:
	var rows = []
	for rank in range(8):
		var empty = 0
		var row = ""
		for file in range(8):
			var p = board.get_piece(Vector2(file, rank))
			if p == null:
				empty += 1
				continue
			if empty > 0:
				row += str(empty)
				empty = 0
			row += _fen_char(p)
		if empty > 0:
			row += str(empty)
		rows.append(row)

	var placement = "/".join(rows)
	var active = "w" if status == Globals.COLORS.WHITE else "b"
	var castling = board._get_castling_rights()
	var ep = "-"
	if board.en_passant_target != null:
		var ex = int(board.en_passant_target.x)
		var ey = int(board.en_passant_target.y)
		ep = char(97 + ex) + str(8 - ey)

	return placement + " " + active + " " + castling + " " + ep

func _fen_char(piece) -> String:
	var ch = ""
	match piece.piece_type:
		Globals.PIECE_TYPES.PAWN: ch = "p"
		Globals.PIECE_TYPES.ROOK: ch = "r"
		Globals.PIECE_TYPES.KNIGHT: ch = "n"
		Globals.PIECE_TYPES.BISHOP: ch = "b"
		Globals.PIECE_TYPES.QUEEN: ch = "q"
		Globals.PIECE_TYPES.KING: ch = "k"
	return ch.to_upper() if piece.color == Globals.COLORS.WHITE else ch
