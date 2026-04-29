extends RefCounted
class_name Evaluator

const PAWN_PST = [
     0,  0,  0,  0,  0,  0,  0,  0,
    10, 10, 10, 10, 10, 10, 10, 10,
     2,  2,  4,  6,  6,  4,  2,  2,
     2,  2,  2,  6,  6,  2,  2,  2,
     0,  0,  0,  4,  4,  0,  0,  0,
     2,  0,  0,  0,  0,  0,  0,  2,
     2,  2,  0, -4, -4,  0,  2,  2,
     0,  0,  0,  0,  0,  0,  0,  0,
]
const KNIGHT_PST = [
   -10, -8, -6, -6, -6, -6, -8,-10,
    -8, -4,  0,  0,  0,  0, -4, -8,
    -6,  0,  2,  4,  4,  2,  0, -6,
    -6,  2,  4,  6,  6,  4,  2, -6,
    -6,  0,  4,  6,  6,  4,  0, -6,
    -6,  2,  2,  4,  4,  2,  2, -6,
    -8, -4,  0,  2,  2,  0, -4, -8,
   -10, -8, -6, -6, -6, -6, -8,-10,
]
const BISHOP_PST = [
    -4, -2, -2, -2, -2, -2, -2, -4,
    -2,  0,  0,  0,  0,  0,  0, -2,
    -2,  0,  2,  2,  2,  2,  0, -2,
    -2,  2,  2,  3,  3,  2,  2, -2,
    -2,  0,  2,  3,  3,  2,  0, -2,
    -2,  2,  2,  3,  3,  2,  2, -2,
    -2,  0,  0,  0,  0,  0,  0, -2,
    -4, -2, -2, -2, -2, -2, -2, -4,
]
const ROOK_PST = [
     0,  0,  0,  0,  0,  0,  0,  0,
     2,  2,  2,  2,  2,  2,  2,  2,
    -2,  0,  0,  0,  0,  0,  0, -2,
    -2,  0,  0,  0,  0,  0,  0, -2,
    -2,  0,  0,  0,  0,  0,  0, -2,
    -2,  0,  0,  0,  0,  0,  0, -2,
    -2,  0,  0,  0,  0,  0,  0, -2,
     0,  0,  0,  2,  2,  0,  0,  0,
]
const QUEEN_PST = [
    -4, -2, -2, -2, -2, -2, -2, -4,
    -2,  0,  0,  0,  0,  0,  0, -2,
    -2,  0,  2,  2,  2,  2,  0, -2,
    -2,  0,  2,  2,  2,  2,  0, -2,
    -2,  0,  0,  2,  2,  0,  0, -2,
    -2,  2,  2,  2,  2,  2,  2, -2,
    -2,  0,  2,  0,  0,  0,  0, -2,
    -4, -2, -2, -2, -2, -2, -2, -4,
]
const KING_PST = [
    -6, -8, -8,-10,-10, -8, -8, -6,
    -6, -8, -8,-10,-10, -8, -8, -6,
    -6, -8, -8,-10,-10, -8, -8, -6,
    -6, -8, -8,-10,-10, -8, -8, -6,
    -4, -6, -6, -8, -8, -6, -6, -4,
    -2, -4, -4, -4, -4, -4, -4, -2,
     4,  4,  0,  0,  0,  0,  4,  4,
     4,  6,  2,  0,  0,  2,  6,  4,
]
const PST_MAP = {
    Globals.PIECE_TYPES.PAWN: PAWN_PST,
    Globals.PIECE_TYPES.KNIGHT: KNIGHT_PST,
    Globals.PIECE_TYPES.BISHOP: BISHOP_PST,
    Globals.PIECE_TYPES.ROOK: ROOK_PST,
    Globals.PIECE_TYPES.QUEEN: QUEEN_PST,
    Globals.PIECE_TYPES.KING: KING_PST,
}

func evaluate(board, color) -> int:
	var materia_score = 0
	var pst_score = 0

	for y in range(8):
		for x in range(8):
			var cell = board.grid[x + y * 8]
			if cell == null:
				continue

			var mat = board.PIECE_VALUES.get(cell.type, 0)
			if cell.color == Globals.COLORS.WHITE:
				materia_score += mat
			else:
				materia_score -= mat
			
			var pst_table = PST_MAP.get(cell.type, null)
			if pst_table != null:
				if cell.color == Globals.COLORS.WHITE:
					pst_score += pst_table[x + y * 8]
				else:
					pst_score -= pst_table[x + (7 - y) * 8]

	var total = materia_score + pst_score
	return total if color == Globals.COLORS.WHITE else -total