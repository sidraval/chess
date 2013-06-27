module SharedDirections
  STRAIGHTS = [[0,1],[1,0],[-1,0],[0,-1]]
  DIAGONALS = [[-1,1],[1,1],[1,-1],[-1,-1]]
end

class ChessPiece
  attr_accessor :moves, :color, :position, :symbol

  def initialize(color,board,position)
    @color = color
    @board = board
    @position = position
    set_symbol
    add_to_board
  end

  def add_to_board
    @board.set_piece(@position,self)
  end

  def position_state(position)
    y,x = position
    return :next if !((0..7).include?(x) && (0..7).include?(y))

    piece = @board.grid[y][x]
    if piece.nil?
      return :empty
    elsif piece.color == self.color
      return :next
    else
      return :opponent_piece
    end
  end

  def valid_moves
    moves = unchecked_valid_moves
    moves_to_delete = []

    moves.each do |move|
      old_piece = @board.temporary_change(move,self)
      moves_to_delete << move if @board.is_in_check?(self.color)
      @board.revert_change(move,old_piece,self)
    end

    moves = moves - moves_to_delete
  end

  private
  def add_arrays(first,second)
    first.zip(second).map { |p| p.inject(:+) }
  end

end

class SlidingPiece < ChessPiece

  # Makes moves without worrying about opponents new valid moves
  def unchecked_valid_moves
    moves = []
    directions.each do |direction|
      new_position = @position
      bad_direction = false
      until bad_direction
        new_position = add_arrays(new_position,direction)
        case position_state(new_position)
        when :next
          bad_direction = true
        when :opponent_piece
          moves << new_position
          bad_direction = true
        when :empty
          moves << new_position
        end
      end
    end

    moves
  end

end

class SteppingPiece < ChessPiece

  def unchecked_valid_moves
    moves = []
    directions.each do |direction|
      new_position = @position
      new_position = add_arrays(new_position,direction)
      moves << new_position if position_state(new_position) != :next
    end
    moves
  end

end

class King < SteppingPiece
  include SharedDirections

  def directions
    STRAIGHTS + DIAGONALS
  end

  def set_symbol
    @symbol = @color == :white ? "\u2654" : "\u265A"
  end

end

class Queen < SlidingPiece
  include SharedDirections

  def directions
    STRAIGHTS + DIAGONALS
  end

  def set_symbol
    @symbol = @color == :white ? "\u2655" : "\u265B"
  end

end

class Rook < SlidingPiece
  include SharedDirections

  def directions
    STRAIGHTS
  end

  def set_symbol
    @symbol = @color == :white ? "\u2656" : "\u265C"
  end

end

class Knight < SteppingPiece

  def directions
    [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]]
  end

  def set_symbol
    @symbol = @color == :white ? "\u2658" : "\u265E"
  end

end

class Bishop < SlidingPiece
  include SharedDirections

  def directions
    DIAGONALS
  end

  def set_symbol
    @symbol = @color == :white ? "\u2657" : "\u265D"
  end

end

class Pawn < ChessPiece
  attr_accessor :has_moved

  def directions
    if @color == :white
      [[-1,0],[-1,-1],[-1,1],[-2,0]]
    else
      [[1,0],[1,1],[1,-1],[2,0]]
    end
  end

  def initialize(color,board,position)
    super(color,board,position)
    @has_moved = false
  end

  def unchecked_valid_moves
    moves = add_forward_once
    moves += add_diagonals
    moves += add_forward_twice(moves) unless @has_moved
    moves
  end

  def add_forward_twice(legal_moves)
    moves = []
    forward_once = add_arrays(@position,directions[0])
    new_position = add_arrays(@position,directions[3])
    return [new_position] if legal_moves.include?(forward_once) && @board.get_piece(new_position).nil?
    []
  end

  def add_diagonals
    moves = []
    directions[1...3].each do |direction|
      new_position = @position
      new_position = add_arrays(new_position,direction)
      moves << new_position if position_state(new_position) == :opponent_piece
    end
    moves
  end

  def add_forward_once
    new_position = add_arrays(@position,directions[0])
    return [new_position] if position_state(new_position) == :empty
    []
  end

  def set_symbol
    @symbol = @color == :white ? "\u2659" : "\u265F"
  end
end