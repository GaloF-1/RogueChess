extends Piece
class_name Pawn

func get_moves(board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var dir := -1 if color == PieceColor.WHITE else 1

	var one_step := coord + Vector2i(0, dir)
	if board.is_coord_empty(one_step):
		moves.append(one_step)
		var start_row := 6 if color == PieceColor.WHITE else 1
		var two_step := coord + Vector2i(0, 2 * dir)
		if coord.y == start_row and board.is_coord_empty(two_step):
			moves.append(two_step)

	for dx in [-1, 1]:
		var diag := coord + Vector2i(dx, dir)
		var piece_at := board.get_piece_at(diag)
		if piece_at and piece_at.color != color:
			moves.append(diag)

	return moves.filter(func(c: Vector2i) -> bool: 
		return c.x >= 0 and c.x < board.board_size and c.y >= 0 and c.y < board.board_size)


func _is_empty(board, c: Vector2i) -> bool:
	return c.x >= 0 and c.x < board.board_size and c.y >= 0 and c.y < board.board_size and board.get_piece_at(c) == null


func _apply_sprite() -> void:
	if _sprite == null:
		push_error("[Piece] Falta un hijo Sprite2D (ruta: 'Sprite2D').")
		return
	var tex: Texture2D = sprite_white if color == PieceColor.WHITE else sprite_black
	_sprite.texture = tex
	_sprite.centered = true
	_sprite.position = Vector2.ZERO

	# Opcional: auto–escalar a la casilla
	var board: Board = _get_board()
	if board and tex:
		var tex_size: Vector2 = tex.get_size()
		var target := board.tile_px * 0.7 # un 90% para dejar margen
		var s = (target / max(tex_size.x, tex_size.y)) if tex_size.x > 0 and tex_size.y > 0 else 1.0
		_sprite.scale = Vector2(s, s)
