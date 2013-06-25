require 'colored'

module SharedDirections
  def straight_directions
    (-7..7).each do |n|
      unless n == 0
        possible_directions << [0,n]
        possible_directions << [n,0]
      end
    end
  end

  def diagonal_directions
    (-7..7).each do |n|
      unless n == 0
        possible_directions << [-n,n]
        possible_directions << [n,n]
      end
    end
  end
end

class ChessPiece
  attr_accessor :position, :possible_directions, :symbol

  def initialize(position)
    @possible_directions = []
    @position = position
    set_symbol(position[0])
    make_directions
  end

  def possible_movements
    possible_movements = []
    possible_directions.each do |direction|
      new_coordinate = @position.zip(direction).map { |item| item.inject(:+) }
      possible_movements << new_coordinate
    end
    #check if it's on the board
    possible_movements.select do |coord|
      y = coord[0]
      x = coord[1]
      (0..7).include?(x) && (0..7).include?(y)
    end
  end

end

class King < ChessPiece

  def set_symbol(y)
    @symbol = y == 7 ? "\u2654" : "\u265A"
  end

  def make_directions
    (-1..1).each do |n|
      (-1..1).each do |m|
        next if n == 0 && m == 0
        possible_directions << [n,m]
      end
    end
  end
end

class Queen < ChessPiece
  include SharedDirections

  def set_symbol(y)
    @symbol = y == 7 ? "\u2655" : "\u265B"
  end

  def make_directions
    diagonal_directions
    straight_directions
  end
end

class Rook < ChessPiece
  include SharedDirections

  def set_symbol(y)
    @symbol = y == 7 ? "\u2656" : "\u265C"
  end

  def make_directions
    straight_directions
  end
end

class Knight < ChessPiece

  def set_symbol(y)
    @symbol = y == 7 ? "\u2658" : "\u265E"
  end

  def make_directions
    [-2, -1, 1, 2].each do |n|
      [-2, -1, 1, 2].each do |m|
        next if n.abs == m.abs
        possible_directions << [n,m]
      end
    end
  end
end

class Bishop < ChessPiece
  include SharedDirections

  def set_symbol(y)
    @symbol = y == 7 ? "\u2657" : "\u265D"
  end

  def make_directions
    diagonal_directions
  end
end

class Pawn < ChessPiece

  def set_symbol(y)
    @symbol = y == 6 ? "\u2659" : "\u265F"
  end

  def make_directions
    @possible_directions += [[-1,0],[-1,-1],[-1,1],[-2,0],[1,0],[1,1],[1,-1],[2,0]]
  end
end

class Board
  attr_accessor :grid

  def initialize
    @grid = make_board
  end

  # player1.king.position[0] => row
  # player1.king.position[1] => column

  def make_board
    board = []
    8.times do |row|
      row = []
      8.times { row << nil }
      board << row
    end
    board
  end

  def change_board(player_move)
    start,finish = player_move
    y,x = start
    piece = @grid[y][x]
    @grid[y][x] = nil
    y,x = finish
    @grid[y][x] = piece
  end

  def display
    @grid.each do |row|
      row.each do |char|
        if char.nil?
          print "   "
        else
          print " #{char.symbol} "
        end
      end
      print "\n"
    end
  end

  def check_mate?
  end

  def populate(white,black)
    white.each do |piece|
      y,x = piece.position
      @grid[y][x] = piece
    end
    black.each do |piece|
      y,x = piece.position
      @grid[y][x] = piece
    end
  end

end

class Chess
  attr_accessor :player1, :player2, :board

  def initialize
    @player1 = HumanPlayer.new("white")
    @player2 = HumanPlayer.new("black")
    @board = Board.new
    @board.populate(@player1.pieces,@player2.pieces)
  end

  def play
    until game_over?
      turn
    end
  end

  def game_over?
    # @board.check_mate?
  end

  def turn
    player1_move = move(@player1)
    @board.change_board(player1_move)
    player2_move = move(@player2)
    @board.change_board(player2_move)
  end

  def move(player)
    begin
      player_move = player.move
      unless is_valid?(player,player_move)
        raise "Error. Try Again."
      end
    rescue
      retry
    end
    player_move
  end

  #Rules of Chess- Methods


  def is_valid?(player,position)
    valid_starting_square?(player,position) &&
    ending_square?(player,position) &&
    unblocked?(position)
  end

  def valid_starting_square?(player,position)
    y,x = position.first
    player.pieces.include?(@board.grid[y][x])
  end

  def ending_square?(player,position)
    #set piece as the piece being moved
    y,x = position.first
    piece = @board.grid[y][x]

    #checks that it's a possible move and not occupied
    #by one of the player's own pieces
    y,x = position.last
    piece.possible_movements.include?([y,x]) &&
    !player.pieces.include?(@board.grid[y][x])
  end

  # check if positions between the start and finish is empty
  # straight movements and diagonal movements only
  def unblocked?(position)
    start = position.first
    y,x = start
    piece = @board.grid[y][x]
    return true unless piece.class == Queen || piece.class == Rook || piece.class == Bishop
    finish = position.last
    direction = difference(start,finish)
    before_finish = finish.zip(direction).map { |item| item.inject(:-) }

    # go through the spots between and return false if there is
    # a piece in one of those spots
    until start == before_finish
      start = start.zip(direction).map { |item| item.inject(:+) }
      y,x = start
      return false unless @board.grid[y][x].nil?
    end

    true
  end


  #takes two array and returns a direction from start to finish
  def difference(start,finish)
    difference = finish.zip(start).map { |item| item.inject(:-) }
    difference.map do |item|
      if item == 0
        0
      elsif item > 0
        1
      else
        -1
      end
    end
  end

end

class HumanPlayer
  attr_accessor :king, :queen, :bishop1, :bishop2, :knight1, :knight2,
  :rook1, :rook2, :pawn1, :pawn2, :pawn3, :pawn4, :pawn5, :pawn6, :pawn7, :pawn8

  def initialize(side)
    set_pieces(side)
  end

  def set_pieces(side)
    side.downcase == "black" ? make_pieces(0) : make_pieces(7)
  end

  def pieces
    [@king,@queen,@bishop1,@bishop2,@knight1,@knight2,@rook1,@rook2,
      @pawn1, @pawn2, @pawn3, @pawn4, @pawn5, @pawn6, @pawn7, @pawn8]
  end

  def make_pieces(y)
    @king = King.new([y,4])
    @queen = Queen.new([y,3])
    @bishop1 = Bishop.new([y,2])
    @bishop2 = Bishop.new([y,5])
    @knight1 = Knight.new([y,1])
    @knight2 = Knight.new([y,6])
    @rook1 = Rook.new([y,0])
    @rook2 = Rook.new([y,7])

    (y == 7) ? (y -= 1) : (y += 1)
    8.times do |index|
      instance_variable_set("@pawn#{index+1}",Pawn.new([y,index]))
    end
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