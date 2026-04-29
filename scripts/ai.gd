extends RefCounted
class_name ai

const Search = preload("res://scripts/search.gd")
var status = Globals.COLORS.BLACK

@export var search_depth = 3

var board
var search

func _init(_board) -> void:
	board = _board
	search = Search.new(board, search_depth)

func get_best_move():
	return search.get_best_move(status)