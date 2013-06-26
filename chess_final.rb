# encoding: UTF-8
require 'colored'

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

  def valid_moves
    moves = unchecked_valid_moves
    moves_to_delete = []

    moves.each do |move|
      old_piece = @board.temporary_change(move,self)
      moves_to_delete << move if @board.placed_in_check?(self.color)
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
        case validity(new_position)
        when "Next direction"
          bad_direction = true
        when "Opponents piece"
          moves << new_position
          bad_direction = true
        when "Empty spot"
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
      moves << new_position if validity(new_position) != "Next direction"
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
    @symbol = @color == "white" ? "\u2654" : "\u265A"
  end

end

class Queen < SlidingPiece
  include SharedDirections

  def directions
    STRAIGHTS + DIAGONALS
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2655" : "\u265B"
  end

end

class Rook < SlidingPiece
  include SharedDirections

  def directions
    STRAIGHTS
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2656" : "\u265C"
  end

end

class Knight < SteppingPiece

  def directions
    [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]]
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2658" : "\u265E"
  end

end

class Bishop < SlidingPiece
  include SharedDirections

  def directions
    DIAGONALS
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2657" : "\u265D"
  end

end

class Pawn < ChessPiece
  attr_accessor :has_moved

  def directions
    if @color == "white"
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
      moves << new_position if validity(new_position) == "Opponents piece"
    end
    moves
  end

  def add_forward_once
    new_position = add_arrays(@position,directions[0])
    return [new_position] if validity(new_position) == "Empty spot"
    []
  end

  def set_symbol
    @symbol = @color == "white" ? "\u2659" : "\u265F"
  end
end

class Board
  attr_accessor :grid

  def initialize
    @grid = Array.new(8){Array.new(8)}
    set_pieces
  end

  def set_pieces
    2.times do |number|
      color = number == 0 ? "black" : "white"
      row = number * 7

      pieces = [Rook,Knight,Bishop,Queen,King,Bishop,Knight,Rook]
      pieces.each_with_index do |piece,column|
        piece.new(color,self,[row,column])
      end

      row == 7 ? row -= 1 : row += 1
      8.times do |index|
        Pawn.new(color,self,[row,index])
      end
    end
  end

  def placed_in_check?(color)
    opponents_color = color == "white" ? "black" : "white"
    opponents_pieces = gather_pieces(opponents_color)

    opponents_pieces.any? do |piece|
      piece.unchecked_valid_moves
      is_checked?(piece,color)
    end
  end

  def is_checked?(piece,kings_color)
    piece.unchecked_valid_moves.each do |position|
      y,x = position
      return true if @grid[y][x].class == King && @grid[y][x].color == kings_color
    end
    false
  end

  def temporary_change(move,moving_piece)
    old_piece = get_piece(move)
    set_piece(move,moving_piece)
    set_piece(moving_piece.position,nil)
    old_piece
  end

  def revert_change(move,old_piece,moving_piece)
    set_piece(move,old_piece)
    set_piece(moving_piece.position,moving_piece)
  end

  def change_board(player_move)
    start,finish = player_move
    sy,sx = start
    fy,fx = finish
    piece = @grid[sy][sx]

    kill_piece(@grid[fy][fx])
    @grid[sy][sx], @grid[fy][fx] = nil, piece
    piece.position = [fy,fx]

    if piece.class == Pawn
      piece.has_moved = true
      promote_pawn(piece) if piece.position[0] == 7 || piece.position[0] == 0
    end

    display
  end

  def promote_pawn(pawn)
    y,x = pawn.position
    print "What piece would you like to promote to? Q K B R: "
    new_piece = gets.chomp
    case new_piece
    when "Q"
      @grid[y][x] = Queen.new(pawn.color,self,pawn.position)
    when "K"
      @grid[y][x] = Knight.new(pawn.color,self,pawn.position)
    when "B"
      @grid[y][x] = Bishop.new(pawn.color,self,pawn.position)
    when "R"
      @grid[y][x] = Rook.new(pawn.color,self,pawn.position)
    end
    kill_piece(pawn)
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

  def gather_pieces(color)
    pieces = []
    @grid.each do |row|
      row.each do |square|
        next if square.nil?
        pieces << square if square.color == color
      end
    end
    pieces
  end

  def kill_piece(old_piece)
    old_piece.position = [-1000,-1000] unless old_piece.nil?
  end

  def get_piece(position)
    y,x = position
    return nil if y < 0 || x < 0
    @grid[y][x]
  end

  def set_piece(position,piece)
    y,x = position
    @grid[y][x] = piece
  end

  def in_mate?(color)
    my_pieces = gather_pieces(color)
    valid_moves = []
    my_pieces.each do |piece|
      valid_moves += piece.valid_moves
    end
    valid_moves.empty?
  end

end

class Chess
  attr_accessor :board

  def initialize
    @board = Board.new
    @player1 = Human.new("white")
    @player2 = Human.new("black")
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

  def type_of_end_game
    p1_check = @board.placed_in_check?(@player2.color)
    p2_check = @board.placed_in_check?(@player1.color)
    p1_mate = @board.in_mate?(@player2.color)
    p2_mate = @board.in_mate?(@player1.color)
    if (p1_check || p2_check) && (p1_mate || p2_mate)
      puts "Checkmate!"
    elsif !(p1_check && p2_check) && (p1_mate || p2_mate)
      puts "Stalemate!"
    end
  end

  def turn(player)
    puts "Check!" if @board.placed_in_check?(player.color)
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
    @board.in_mate?(@player1.color) || @board.in_mate?(@player2.color)
  end

end

class Human
  attr_accessor :color

  def initialize(color)
    @color = color
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