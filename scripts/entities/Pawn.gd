extends Piece
class_name Pawn

func get_moves(board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var dir := -1 if color == PieceColor.WHITE else 1  # blancos suben en Y

	var one := coord + Vector2i(0, dir)
	if _is_empty(board, one):
		moves.append(one)
		# doble paso desde fila inicial (6 blancos, 1 negros en convención y=0 arriba)
		var start_row := 6 if color == PieceColor.WHITE else 1
		var two := coord + Vector2i(0, 2 * dir)
		if coord.y == start_row and _is_empty(board, two):
			moves.append(two)

	# capturas diagonales
	for dx in [-1, 1]:
		var diag := coord + Vector2i(dx, dir)
		var p : Piece = board.get_piece_at(diag)
		if p and p.color != color:
			moves.append(diag)

	# limitar a 8x8
	return moves.filter(func(c): return c.x >= 0 and c.x < board.board_size and c.y >= 0 and c.y < board.board_size)


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
