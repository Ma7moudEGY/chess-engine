extends RefCounted
class_name BookMoves

const BOOK = {
	"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3": [
		["e7", "e5"],
		["c7", "c5"],
		["e7", "e6"],
		["c7", "c6"],
	],

	"rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq -": [
		["d7", "d5"],
		["g8", "f6"],
		["d7", "d6"],
		["e7", "e6"],
	],

	"rnbqkbnr/pppppppp/8/8/2P5/8/PP1PPPPP/RNBQKBNR b KQkq -": [
		["e7", "e5"],
		["g8", "f6"],
		["e7", "e6"],
		["c7", "c5"],
	],

	"rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -": [
		["b8", "c6"],
		["d7", "d6"],
		["e7", "e6"],
	],

	"rnbqkbnr/pp1ppppp/8/2p5/3P4/8/PPP1PPPP/RNBQKBNR b KQkq -": [
		["c5", "d4"],
		["g8", "f6"],
		["b8", "c6"],
	],

	"rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq -": [
		["d7", "d6"],
		["b8", "c6"],
		["e7", "e6"],
		["g8", "f6"],
	],

	"rnbqkbnr/pp1ppppp/8/2p5/4P3/2N5/PPPP1PPP/R1BQKBNR b KQkq -": [
		["d7", "d6"],
		["b8", "c6"],
		["e7", "e6"],
		["g8", "f6"],
	],

	"rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -": [
		["g8", "f6"],
		["b8", "c6"],
		["d8", "h4"],
	],

	"rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq -": [
		["g8", "f6"],
		["d7", "d6"],
		["b8", "c6"],
		["d8", "e7"],
		["f8", "c5"],
	],

	"rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq -": [
		["d5", "c4"],
		["e7", "e6"],
		["c7", "c6"],
		["g8", "f6"],
	],

	"rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq -": [
		["f6", "e4"],
		["f8", "c5"],
		["d7", "d6"],
	],

	"r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq -": [
		["g8", "f6"],
		["d7", "d6"],
		["f8", "c5"],
		["d8", "h4"],
	],

	"r1bqkbnr/pppp1ppp/2n5/4p3/4P3/2N5/PPPP1PPP/R1BQKBNR b KQkq -": [
		["g8", "f6"],
		["d7", "d6"],
		["f8", "c5"],
	],

	"r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq -": [
		["a7", "a6"],
		["g8", "f6"],
		["d7", "d6"],
	],

	"r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq -": [
		["f8", "c5"],
		["g8", "f6"],
		["d7", "d6"],
		["f8", "e7"],
	],

	"r1bqkbnr/pppp1ppp/2n5/4p3/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq -": [
		["c6", "d4"],
		["e5", "d4"],
		["g8", "f6"],
	],

	"r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQ1RK1 b kq -": [
		["f8", "c5"],
		["f6", "e4"],
		["d7", "d6"],
	],

	"r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/2N2N2/PPPP1PPP/R1BQ1RK1 b kq -": [
		["f8", "c5"],
		["f6", "e4"],
		["d7", "d6"],
	],

	"r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/2N2N2/PPPP1PPP/R1BQK2R b KQkq -": [
		["a7", "a6"],
		["g8", "e7"],
		["g8", "f6"],
	],

	"rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq -": [
		["d7", "d6"],
		["c5", "b6"],
		["e8", "g8"],
	],

	"r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQ1RK1 b kq -": [
		["d7", "d6"],
		["e8", "g8"],
		["d8", "e7"],
	],

	"r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq -": [
		["f8", "c5"],
		["f6", "e4"],
		["d7", "d6"],
	],

	"rnbqkbnr/pppp1ppp/8/4p3/3P4/5N2/PPP1PPPP/RNBQKB1R b KQkq -": [
		["g8", "f6"],
		["e5", "d4"],
		["f8", "e7"],
	],

	"rnbqkb1r/pp2pppp/3p4/2p5/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq -": [
		["c5", "d4"],
		["g8", "f6"],
		["e7", "e6"],
	],

	"rnbqkb1r/pp2pppp/3p4/2p5/3PP3/2N5/PPP2PPP/R1BQKBNR b KQkq -": [
		["c5", "d4"],
		["g8", "f6"],
		["e7", "e6"],
	],

	"r1bqkbnr/pp2pppp/2np4/2p5/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq -": [
		["e7", "e6"],
		["g8", "f6"],
		["e7", "e5"],
	],

	"r1bqkb1r/pp2pppp/2np1n2/2p5/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq -": [
		["e7", "e6"],
		["g7", "g6"],
		["f8", "e7"],
	],

	"r1bqkb1r/pp2pppp/2np1n2/2p5/3PP3/2N5/PPP2PPP/R1BQKBNR b KQkq -": [
		["e7", "e6"],
		["g7", "g6"],
		["f8", "e7"],
	],

	"r1bqk2r/pp2pppp/2np1n2/2p5/3PP3/2N5/PPP2PPP/R1BQKBNR b KQkq -": [
		["f8", "e7"],
		["e7", "e6"],
		["g7", "g6"],
	],
}

static func _algebraic_to_pos(sq: String) -> Vector2:
	var x = int(sq[0].unicode_at(0)) - 97
	var y = 8 - int(sq[1])
	return Vector2(x, y)

static func lookup(pos_key: String, valid_moves: Array):
	if not BOOK.has(pos_key):
		return null

	var book_moves = BOOK[pos_key]
	var valid_set = {}
	for vm in valid_moves:
		valid_set[vm[1]] = vm[0]

	var matches = []
	for um in book_moves:
		var from_pos = _algebraic_to_pos(um[0])
		var to_pos = _algebraic_to_pos(um[1])
		if valid_set.has(to_pos) and valid_set[to_pos].board_position == from_pos:
			matches.append([valid_set[to_pos], to_pos])

	if matches.is_empty():
		return null

	return matches[randi() % matches.size()]
