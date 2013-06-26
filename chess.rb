require 'colored'
require_relative 'board'
require_relative 'pieces'
require_relative 'human'

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