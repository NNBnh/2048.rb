require "io/console"
require "tty-reader"

class Game2048
  def initialize(width = 4, height = width)
    @width = width
    @height = height
    @board = Array.new(@height) { Array.new(@width) }
    2.times { self.add }
    @score = 0
  end

  def board() @board end
  def score() @score end

  def add
    loop do
      x = rand(0..(@width - 1))
      y = rand(0..(@height - 1))

      unless @board[y][x]
        @board[y][x] = [2, 4].sample
        break
      end

      return unless @board.flatten.include?(nil)
    end
  end

  def move_left(board = @board, score_add: false)
    board.map do |line|
      line.compact
      .inject([]) do |moved, tile|
        if tile == moved.last
          combined = tile * 2
          @score += combined if score_add
          moved[0..-2] + [combined.to_s]
        else
          moved + [tile]
        end
      end
      .map(&:to_i).append(*[nil] * @width).first(@width)
    end
  end

  def move_right(board = @board, score_add: false)
    self.move_left(board.map(&:reverse), score_add: score_add)
    .map(&:reverse)
  end

  def move_up(board = @board, score_add: false)
    self.move_left(board.transpose, score_add: score_add)
    .transpose.first(@height)
  end

  def move_down(board = @board, score_add: false)
    self.move_left(board.transpose.map(&:reverse), score_add: score_add)
    .map(&:reverse).transpose.last(@height)
  end

  def move_left! () @board = self.move_left(  score_add: true) end
  def move_right!() @board = self.move_right( score_add: true) end
  def move_up!   () @board = self.move_up(    score_add: true) end
  def move_down! () @board = self.move_down(  score_add: true) end

  def draw
    {
      top:    "┌─┬┐",
      blank:  "│ ││",
      middle: "├─┼┤",
      bottom: "└─┴┘"
    }
    .map do |type, chars|
      [
        type,
        chars[0] + ([chars[1] * 8] * @width).join(chars[2]) + chars[3] + "\n"
      ]
    end
    .to_h => board_line

    @board.map do |line|
      line_display = line.map { |tile| tile.to_s.center(6) }.join(" │ ")
      board_line[:blank]* 1 + ("│ " + line_display + " │\n") + board_line[:blank] * 1
    end
    .join(board_line[:middle]) => board_display

    board_line[:top] + board_display + board_line[:bottom]
  end

  def play
    prompt = TTY::Reader.new

    loop do
      IO.console.clear_screen
      print "\n" * (($stdout.winsize[0] - @height * 4 + 2) / 2) if @height * 4 + 2 <= $stdout.winsize[0]
      puts self.draw.lines.map { _1.chomp.center($stdout.winsize[1]) }.join("\n")
      print @score.to_s.center($stdout.winsize[1])

      return @score if [self.move_left, self.move_right, self.move_up, self.move_down].uniq.size == 1

      current_board = @board

      case prompt.read_keypress
      when "\e[A" then self.move_up!
      when "\e[B" then self.move_down!
      when "\e[C" then self.move_right!
      when "\e[D" then self.move_left!
      when "\e"   then return self
      else next
      end

      self.add if @board != current_board
    end
  end

  def won?
    ! @board.flatten.select { _1.to_i >= 2048 }.empty?
  end
end
