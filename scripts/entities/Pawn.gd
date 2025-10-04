extends Piece
class_name Pawn

# REFACTOR: Sobreescritura de get_moves. Añadimos comentarios para claridad.
func get_moves(board: Board) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var dir := -1 if color == PieceColor.WHITE else 1  # Blancos bajan (asumiendo y=0 top), negros suben

	# Avance simple
	var one_step := coord + Vector2i(0, dir)
	if board.is_coord_empty(one_step):
		moves.append(one_step)
		
		# Avance doble desde posición inicial
		var start_row := 6 if color == PieceColor.WHITE else 1
		var two_step := coord + Vector2i(0, 2 * dir)
		if coord.y == start_row and board.is_coord_empty(two_step):
			moves.append(two_step)

	# Capturas diagonales (solo si hay enemigo)
	for dx in [-1, 1]:
		var diag := coord + Vector2i(dx, dir)
		var piece_at := board.get_piece_at(diag)
		if piece_at and piece_at.color != color:
			moves.append(diag)

	# Filtrar bounds (por si acaso, aunque lo chequeamos implícitamente)
	return moves.filter(func(c: Vector2i) -> bool: 
		return c.x >= 0 and c.x < board.board_size and c.y >= 0 and c.y < board.board_size)

# REFACTOR: Removimos _is_empty (redundante, usamos board.is_coord_empty). _apply_sprite queda igual, pero lo movimos a base si posible en futuro.
func _apply_sprite() -> void:
	super._apply_sprite()  # Llama a base para consistencia
