require 'debugger'
require 'colored'
module SharedDirections
  def straight_directions
    @directions += [[0,1],[1,0],[-1,0],[0,-1]]
  end

  def diagonal_directions
    @directions += [[-1,1],[1,1],[1,-1],[-1,-1]]
  end
end

class ChessPiece
  attr_accessor :directions, :moves, :color, :position, :symbol

  def initialize(color,board,position)
    @color = color
    @board = board
    @position = position
    @moves = []
    @directions = []
    set_symbol
    set_directions
    add_to_board
  end

  def add_to_board
    set_piece(@position,self)
  end

  def get_piece(position)
    y,x = position
    return nil if y < 0 || x < 0
    @board.grid[y][x]
  end

  def set_piece(position,piece)
    y,x = position
    @board.grid[y][x] = piece
  end

  def add_arrays(first,second)
    first.zip(second).map { |p| p.inject(:+) }
  end

  # Worries about opponent's newly available moves
  def valid_moves
    unchecked_valid_moves
    moves_to_delete = []

    @moves.each do |move|
      old_piece = temporary_board(move)
      moves_to_delete << move if placed_in_check?
      revert_board(move,old_piece)
    end

    @moves = @moves - moves_to_delete
  end

  def placed_in_check?
    opponents_color = self.color == "white" ? "black" : "white"
    opponents_pieces = gather_pieces(opponents_color)

    opponents_pieces.any? do |piece|
      piece.unchecked_valid_moves
      is_checked?(piece)
    end
  end

  def is_checked?(piece)
    our_color = self.color
    piece.moves.each do |position|
      y,x = position
      return true if @board.grid[y][x].class == King && @board.grid[y][x].color == our_color
    end
    false
  end

  def temporary_board(move)
    old_piece = get_piece(move)
    set_piece(move,self)
    set_piece(self.position,nil)
    old_piece
  end

  def revert_board(move,old_piece)
    set_piece(move,old_piece)
    set_piece(self.position,self)
  end

  def gather_pieces(color)
    pieces = []
    @board.grid.each do |row|
      row.each do |square|
        next if square.nil?
        pieces << square if square.color == color
      end
    end
    pieces
  end

  def validity(position)
    y,x = position
    return "Next direction" if !((0..7).include?(x) && (0..7).include?(y))

    piece = @board.grid[y][x]
    if piece.nil?
      return "Empty spot"
    elsif piece.color == self.color
      return "Next direction"
    else
      return "Opponents piece"
    end
  end
end

class SlidingPiece < ChessPiece

  # Makes moves without worrying about opponents new valid moves
  def unchecked_valid_moves
    @moves = []
    @directions.each do |direction|
      new_position = @position
      bad_direction = false
      until bad_direction
        new_position = add_arrays(new_position,direction)
        case validity(new_position)
        when "Next direction"
          bad_direction = true
        when "Opponents piece"
          @moves << new_position
          bad_direction = true
        when "Empty spot"
          @moves << new_position
        end
      end
    end
  end

end

class SteppingPiece < ChessPiece

  def unchecked_valid_moves
    @moves = []
    @directions.each do |direction|
      new_position = @position
      new_position = add_arrays(new_position,direction)
      @moves << new_position if validity(new_position) != "Next direction"
    end
  end

end

class King < SteppingPiece
  include SharedDirections

  def set_directions
    straight_directions
    diagonal_directions
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2654" : "\u265A"
  end

end

class Queen < SlidingPiece
  include SharedDirections
  def set_directions
    straight_directions
    diagonal_directions
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2655" : "\u265B"
  end

end

class Rook < SlidingPiece
  include SharedDirections

  def set_directions
    straight_directions
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2656" : "\u265C"
  end

end

class Knight < SteppingPiece

  def set_directions
    [-2, -1, 1, 2].each do |n|
      [-2, -1, 1, 2].each do |m|
        next if n.abs == m.abs
        directions << [n,m]
      end
    end
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2658" : "\u265E"
  end

end

class Bishop < SlidingPiece
  include SharedDirections

  def set_directions
    diagonal_directions
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2657" : "\u265D"
  end

end

class Pawn < ChessPiece
  attr_accessor :has_moved
  def unchecked_valid_moves
    @moves = []
    add_forward_once
    add_diagonals
    add_forward_twice unless @has_moved
  end

  def add_forward_twice
    forward_once = add_arrays(@position,@directions[0])
    new_position = add_arrays(@position,@directions[3])
    @moves << new_position if @moves.include?(forward_once) && get_piece(new_position).nil?
  end

  def add_diagonals
    @directions[1...3].each do |direction|
      new_position = @position
      new_position = add_arrays(new_position,direction)
      @moves << new_position if validity(new_position) == "Opponents piece"
    end
  end

  def add_forward_once
    new_position = add_arrays(@position,@directions[0])
    @moves << new_position if validity(new_position) == "Empty spot"
  end

  def initialize(color,board,position)
    super(color,board,position)
    @has_moved = false
  end

  def set_directions
    if @color == "white"
      @directions += [[-1,0],[-1,-1],[-1,1],[-2,0]]
    else
      @directions += [[1,0],[1,1],[1,-1],[2,0]]
    end
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2659" : "\u265F"
  end
end

class Board
  attr_accessor :grid

  def initialize
    @grid = make_board
  end

  def make_board
    board = []
    8.times do |row|
      row = []
      8.times { row << nil }
      board << row
    end
    board
  end

  # Separate into methods
  def change_board(player_move)
    start,finish = player_move
    piece = pick_piece_up(start)
    put_piece_down(piece,finish)
    piece.has_moved = true if piece.class == Pawn
    display
  end

  def put_piece_down(piece,position)
    y,x = position
    kill_piece(@grid[y][x])
    piece.position = position
    @grid[y][x] = piece
  end

  def pick_piece_up(position)
    y,x = position
    piece = @grid[y][x]
    @grid[y][x] = nil
    piece
  end

  def kill_piece(old_piece)
    old_piece.position = [-1000,-1000] unless old_piece.nil?
  end

  def display
    @grid.each_with_index do |row,row_index|
      print " #{8 - row_index} "
      row.each_with_index do |square,square_index|
        set_color = (row_index + square_index) % 2
        if square.nil?
          print "   ".white_on_red if set_color == 0
          print "   ".white_on_black if set_color != 0
        else
          print " #{square.symbol} ".white_on_red if set_color == 0
          print " #{square.symbol} ".white_on_black if set_color != 0
        end
      end
      print "\n"
    end
    print "    a  b  c  d  e  f  g  h \n"
  end

end

class Chess
  attr_accessor :board, :player1, :player2

  def initialize
    @board = Board.new
    @player1 = Human.new("white",@board)
    @player2 = Human.new("black",@board)
  end

  def play
    @board.display

    until game_over?
      turn(@player1)
      break if game_over?
      turn(@player2)
    end

    type_of_end_game
  end

  def type_of_endgame
    if (@player1.king.placed_in_check? || @player2.king.placed_in_check?) &&
      (@player1.in_mate? || @player2.in_mate?)
      puts "Checkmate!"
    else
      !(@player1.king.placed_in_check? && @player2.king.placed_in_check?) &&
      (@player1.in_mate? || @player2.in_mate?)
      puts "Stalemate!"
    end
  end

  def turn(player)
    puts "Check!" if player.king.placed_in_check?
    player_move = move(player)
    @board.change_board(player_move)
  end

  def move(player)
    begin
      player_move = player.move
      unless is_valid?(player,player_move)
        raise ArgumentError.new "Invalid move try again"
      end
    rescue ArgumentError => e
      puts "Error was: #{e.message}"
      retry
    end
    player_move
  end

  def is_valid?(player,move)
    start,finish = move
    y,x = start
    piece = @board.grid[y][x]
    return false if piece.nil?
    piece.valid_moves.include?(finish) && player.color == piece.color
  end

  def game_over?
    @player1.in_mate? || @player2.in_mate?
  end

end

class Human
  attr_accessor :king, :queen, :bishop1, :bishop2, :knight1, :knight2, :color,
  :rook1, :rook2, :pawn1, :pawn2, :pawn3, :pawn4, :pawn5, :pawn6, :pawn7, :pawn8

  def initialize(color,board)
    @color = color
    set_pieces(board)
  end

  def set_pieces(board)
    # debugger
    y = @color == "white" ? 7 : 0

    @king = King.new(@color,board,[y,4])
    @queen = Queen.new(@color,board,[y,3])
    @bishop1 = Bishop.new(@color,board,[y,2])
    @bishop2 = Bishop.new(@color,board,[y,5])
    @knight1 = Knight.new(@color,board,[y,1])
    @knight2 = Knight.new(@color,board,[y,6])
    @rook1 = Rook.new(@color,board,[y,0])
    @rook2 = Rook.new(@color,board,[y,7])

    (y == 7) ? (y -= 1) : (y += 1)
    8.times do |index|
      instance_variable_set("@pawn#{index+1}",Pawn.new(@color,board,[y,index]))
    end
  end

  def pieces
    [@king,@queen,@bishop1,@bishop2,@knight1,@knight2,@rook1,@rook2,
      @pawn1, @pawn2, @pawn3, @pawn4, @pawn5, @pawn6, @pawn7, @pawn8]
  end

  def in_mate?
    valid_moves = []
    pieces.each do |piece|
      valid_moves += piece.valid_moves
    end
    valid_moves.empty?
  end

  def move
    print "coordinates of the piece you want to move: "
    start = chess_to_array_notation(gets.chomp)
    print "coordinates of where you want it to go: "
    finish = chess_to_array_notation(gets.chomp)
    [start,finish]
  end

  def chess_to_array_notation(chess_string)
    column_conversion = Hash[('a'..'h').to_a.zip((0..7).to_a)]
    eight_to_one = 8.downto(1).to_a.map(&:to_s)
    row_conversion = Hash[eight_to_one.zip((0..7).to_a)]
    split_string = chess_string.split(//)
    [row_conversion[split_string.last],column_conversion[split_string.first]]
  end

end


