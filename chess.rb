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

    end_game
  end

  def end_game
    p1_check = @board.is_in_check?(@player1.color)
    p2_check = @board.is_in_check?(@player2.color)
    p1_mate = @board.in_mate?(@player1.color)
    p2_mate = @board.in_mate?(@player2.color)
    if (p1_check || p2_check) && (p1_mate || p2_mate)
      puts "Checkmate!"
    elsif !(p1_check && p2_check) && (p1_mate || p2_mate)
      puts "Stalemate!"
    end
  end

  def turn(player)
    puts "Check!" if @board.is_in_check?(player.color)
    chosen_move = move(player)
    @board.change_board(chosen_move)
  end

  def move(player)
    begin
      chosen_move = player.move
      unless @board.is_valid?(player,chosen_move)
        raise ArgumentError.new "Invalid move try again"
      end
    rescue ArgumentError => e
      puts "Error was: #{e.message}"
      retry
    end
    chosen_move
  end

  def game_over?
    @board.in_mate?(@player1.color) || @board.in_mate?(@player2.color)
  end

end