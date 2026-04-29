extends RefCounted
class_name Move

const IDX_FROM = 0
const IDX_TO = 1
const IDX_MOVED = 2
const IDX_CAPTURED = 3
const IDX_PREV_TYPE = 4
const IDX_ROOK = 5
const IDX_ROOK_FROM = 6
const IDX_ROOK_TO = 7
const IDX_ROOK_PREV_MOVED = 8
const IDX_PREV_EP_TARGET = 9
const IDX_PREV_EP_PAWN = 10
const IDX_WAS_IN_CHECK = 11
const IDX_PREV_HALFMOVE = 12
const IDX_PREV_FULLMOVE = 13

var from_pos: Vector2
var to_pos: Vector2
var moved: bool
var captured
var prev_type
var rook
var rook_from
var rook_to
var rook_prev_moved
var prev_ep_target
var prev_ep_pawn
var was_in_check: bool
var prev_halfmove: int
var prev_fullmove: int

func _init(from_pos_: Vector2, to_pos_: Vector2, moved_: bool, captured_, prev_type_, rook_, rook_from_, rook_to_, rook_prev_moved_, prev_ep_target_, prev_ep_pawn_, was_in_check_: bool, prev_halfmove_: int, prev_fullmove_: int) -> void:
	from_pos = from_pos_
	to_pos = to_pos_
	moved = moved_
	captured = captured_
	prev_type = prev_type_
	rook = rook_
	rook_from = rook_from_
	rook_to = rook_to_
	rook_prev_moved = rook_prev_moved_
	prev_ep_target = prev_ep_target_
	prev_ep_pawn = prev_ep_pawn_
	was_in_check = was_in_check_
	prev_halfmove = prev_halfmove_
	prev_fullmove = prev_fullmove_

static func from_array(arr: Array) -> Move:
	return Move.new(
		arr[IDX_FROM],
		arr[IDX_TO],
		arr[IDX_MOVED],
		arr[IDX_CAPTURED],
		arr[IDX_PREV_TYPE],
		arr[IDX_ROOK],
		arr[IDX_ROOK_FROM],
		arr[IDX_ROOK_TO],
		arr[IDX_ROOK_PREV_MOVED],
		arr[IDX_PREV_EP_TARGET],
		arr[IDX_PREV_EP_PAWN],
		arr[IDX_WAS_IN_CHECK],
		arr[IDX_PREV_HALFMOVE],
		arr[IDX_PREV_FULLMOVE]
	)

func to_array() -> Array:
	return [
		from_pos,
		to_pos,
		moved,
		captured,
		prev_type,
		rook,
		rook_from,
		rook_to,
		rook_prev_moved,
		prev_ep_target,
		prev_ep_pawn,
		was_in_check,
		prev_halfmove,
		prev_fullmove,
	]
