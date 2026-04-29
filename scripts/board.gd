extends Node2D

@export var pieces = []
@export var piece_scene = preload("res://scenes/Piece.tscn")
@export var marker_scene = preload("res://scenes/MoveMarker.tscn")
@export var check_marker_scene = preload("res://scenes/CheckMarker.tscn")

@export var white_king_pos: Vector2
@export var black_king_pos: Vector2

@onready var marker_layer = Node2D.new()
@onready var check_layer = Node2D.new()

var en_passant_target = null
var en_passant_pawn = null

var piece_map = {}
var white_pieces = []
var black_pieces = []

const CELL_SIZE = 90

func _ready() -> void:
	add_child(marker_layer)
	add_child(check_layer)
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

func draw_move_marker(pos):
	var marker = marker_scene.instantiate()
	marker.position = Vector2(CELL_SIZE * pos.x + CELL_SIZE / 2.0, CELL_SIZE * pos.y + CELL_SIZE / 2.0)
	marker.scale = Vector2(1 / 3.0, 1 / 3.0)
	marker.z_index = 101
	marker_layer.add_child(marker)

func draw_check_marker(pos):
	var marker = check_marker_scene.instantiate()
	marker.position = Vector2(CELL_SIZE * pos.x + CELL_SIZE / 2.0, CELL_SIZE * pos.y + CELL_SIZE / 2.0)
	marker.z_index = -1
	check_layer.add_child(marker)


func clear_move_markers():
	for child in marker_layer.get_children():
		child.queue_free()

func clear_check_marker():
	for child in check_layer.get_children():
		child.queue_free()

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
	if OS.get_thread_caller_id() == OS.get_main_thread_id():
		_unregister_piece(piece)
		
		pieces.erase(piece)
		if free_piece:
			piece.queue_free()
		else:
			piece.visible = false

func restore_piece(piece):
	if OS.get_thread_caller_id() == OS.get_main_thread_id():
		if piece == null:
			return

		if piece in pieces:
			return

		pieces.append(piece)
		_register_piece(piece)
		piece.visible = true

func clear_pieces():
	for piece in pieces:
		piece.queue_free()
	pieces.clear()
	piece_map.clear()
	white_king_pos = Vector2.ZERO
	black_king_pos = Vector2.ZERO
	en_passant_target = null
	en_passant_pawn = null

func get_fen(active_color: Globals.COLORS, halfmove_clock: int, fullmove_number: int) -> String:
	var rows = []
	for rank in range(8):
		var empty_count = 0
		var row = ""
		for file in range(8):
			var piece = get_piece(Vector2(file, rank))
			if piece == null:
				empty_count += 1
				continue
			if empty_count > 0:
				row += str(empty_count)
				empty_count = 0
			row += _piece_to_fen_char(piece)
		if empty_count > 0:
			row += str(empty_count)
		rows.append(row)

	var active = "w" if active_color == Globals.COLORS.WHITE else "b"
	var castling = _get_castling_rights()
	var ep = _coord_to_algebraic(en_passant_target) if en_passant_target != null else "-"
	return "/".join(rows) + " " + active + " " + castling + " " + ep + " " + str(halfmove_clock) + " " + str(fullmove_number)

func set_fen(fen: String) -> Dictionary:
	var fields = fen.strip_edges().split(" ")
	if fields.size() < 6:
		return {"ok": false}

	var placement = fields[0]
	var active = fields[1]
	var castling = fields[2]
	var ep = fields[3]
	var halfmove = fields[4]
	var fullmove = fields[5]
	var rows = placement.split("/")
	if rows.size() != 8:
		return {"ok": false}

	clear_pieces()

	for rank in range(8):
		var row = rows[rank]
		var file = 0
		for i in range(row.length()):
			var ch = row[i]
			if ch.is_valid_int():
				file += int(ch)
				if file > 8:
					return {"ok": false}
				continue

			var piece_type = _fen_char_to_piece_type(ch)
			if piece_type == null:
				return {"ok": false}
			var col = Globals.COLORS.WHITE if (ch.to_upper() == ch) else Globals.COLORS.BLACK
			var pos = Vector2(file, rank)
			var piece = piece_scene.instantiate()
			add_child(piece)
			piece.init_piece(piece_type, col, pos, self)
			pieces.append(piece)
			_register_piece(piece)
			if piece_type == Globals.PIECE_TYPES.KING:
				register_king(pos, col)
			file += 1

		if file != 8:
			return {"ok": false}

	var active_color = Globals.COLORS.WHITE if active == "w" else Globals.COLORS.BLACK if active == "b" else null
	if active_color == null:
		return {"ok": false}

	if not _apply_castling_rights(castling):
		return {"ok": false}

	if ep != "-":
		en_passant_target = _algebraic_to_coord(ep)
		if en_passant_target == null:
			return {"ok": false}
		en_passant_pawn = _find_en_passant_pawn(en_passant_target, active_color)

	if not halfmove.is_valid_int() or not fullmove.is_valid_int():
		return {"ok": false}

	return {"ok": true, "active_color": active_color, "halfmove": int(halfmove), "fullmove": int(fullmove)}

func _get_castling_rights() -> String:
	var rights = ""
	var white_king = _find_king(Globals.COLORS.WHITE)
	var black_king = _find_king(Globals.COLORS.BLACK)

	if white_king != null and not white_king.moved and white_king.board_position == Vector2(4, 7):
		var rook_h1 = get_piece(Vector2(7, 7))
		if rook_h1 != null and rook_h1.piece_type == Globals.PIECE_TYPES.ROOK and not rook_h1.moved and rook_h1.color == Globals.COLORS.WHITE:
			rights += "K"
		var rook_a1 = get_piece(Vector2(0, 7))
		if rook_a1 != null and rook_a1.piece_type == Globals.PIECE_TYPES.ROOK and not rook_a1.moved and rook_a1.color == Globals.COLORS.WHITE:
			rights += "Q"

	if black_king != null and not black_king.moved and black_king.board_position == Vector2(4, 0):
		var rook_h8 = get_piece(Vector2(7, 0))
		if rook_h8 != null and rook_h8.piece_type == Globals.PIECE_TYPES.ROOK and not rook_h8.moved and rook_h8.color == Globals.COLORS.BLACK:
			rights += "k"
		var rook_a8 = get_piece(Vector2(0, 0))
		if rook_a8 != null and rook_a8.piece_type == Globals.PIECE_TYPES.ROOK and not rook_a8.moved and rook_a8.color == Globals.COLORS.BLACK:
			rights += "q"

	return rights if rights != "" else "-"

func _apply_castling_rights(castling: String) -> bool:
	if castling == "-":
		castling = ""

	var white_king = _find_king(Globals.COLORS.WHITE)
	var black_king = _find_king(Globals.COLORS.BLACK)

	for piece in pieces:
		if piece.piece_type == Globals.PIECE_TYPES.KING or piece.piece_type == Globals.PIECE_TYPES.ROOK:
			piece.moved = true
		elif piece.piece_type == Globals.PIECE_TYPES.PAWN:
			var start_rank = 6 if piece.color == Globals.COLORS.WHITE else 1
			piece.moved = piece.board_position.y != start_rank
		else:
			piece.moved = true

	if white_king != null and white_king.board_position == Vector2(4, 7):
		if "K" in castling:
			var rook_h1 = get_piece(Vector2(7, 7))
			if rook_h1 != null and rook_h1.piece_type == Globals.PIECE_TYPES.ROOK and rook_h1.color == Globals.COLORS.WHITE:
				white_king.moved = false
				rook_h1.moved = false
		if "Q" in castling:
			var rook_a1 = get_piece(Vector2(0, 7))
			if rook_a1 != null and rook_a1.piece_type == Globals.PIECE_TYPES.ROOK and rook_a1.color == Globals.COLORS.WHITE:
				white_king.moved = false
				rook_a1.moved = false

	if black_king != null and black_king.board_position == Vector2(4, 0):
		if "k" in castling:
			var rook_h8 = get_piece(Vector2(7, 0))
			if rook_h8 != null and rook_h8.piece_type == Globals.PIECE_TYPES.ROOK and rook_h8.color == Globals.COLORS.BLACK:
				black_king.moved = false
				rook_h8.moved = false
		if "q" in castling:
			var rook_a8 = get_piece(Vector2(0, 0))
			if rook_a8 != null and rook_a8.piece_type == Globals.PIECE_TYPES.ROOK and rook_a8.color == Globals.COLORS.BLACK:
				black_king.moved = false
				rook_a8.moved = false

	return true

func _find_king(col: Globals.COLORS):
	for piece in pieces:
		if piece.piece_type == Globals.PIECE_TYPES.KING and piece.color == col:
			return piece
	return null

func _coord_to_algebraic(pos: Vector2) -> String:
	var file = int(pos.x)
	var rank = 8 - int(pos.y)
	return char(97 + file) + str(rank)

func _algebraic_to_coord(square: String):
	if square.length() != 2:
		return null
	var file_char = square[0].to_lower()
	var rank_char = square[1]
	if file_char < "a" or file_char > "h" or not rank_char.is_valid_int():
		return null
	var file = int(file_char.unicode_at(0) - 97)
	var rank = int(rank_char)
	if rank < 1 or rank > 8:
		return null
	return Vector2(file, 8 - rank)

func _find_en_passant_pawn(target: Vector2, active_color: Globals.COLORS):
	var pawn_y = target.y - 1 if active_color == Globals.COLORS.WHITE else target.y + 1
	var pawn_pos = Vector2(target.x, pawn_y)
	var pawn = get_piece(pawn_pos)
	if pawn != null and pawn.piece_type == Globals.PIECE_TYPES.PAWN and pawn.color != active_color:
		return pawn
	return null

func _fen_char_to_piece_type(ch: String):
	match ch.to_lower():
		"p":
			return Globals.PIECE_TYPES.PAWN
		"r":
			return Globals.PIECE_TYPES.ROOK
		"n":
			return Globals.PIECE_TYPES.KNIGHT
		"b":
			return Globals.PIECE_TYPES.BISHOP
		"q":
			return Globals.PIECE_TYPES.QUEEN
		"k":
			return Globals.PIECE_TYPES.KING
		_:
			return null

func _piece_to_fen_char(piece) -> String:
	var ch := ""
	match piece.piece_type:
		Globals.PIECE_TYPES.PAWN:
			ch = "p"
		Globals.PIECE_TYPES.ROOK:
			ch = "r"
		Globals.PIECE_TYPES.KNIGHT:
			ch = "n"
		Globals.PIECE_TYPES.BISHOP:
			ch = "b"
		Globals.PIECE_TYPES.QUEEN:
			ch = "q"
		Globals.PIECE_TYPES.KING:
			ch = "k"
	if piece.color == Globals.COLORS.WHITE:
		return ch.to_upper()
	return ch

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
