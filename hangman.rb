# projects/hangman
require "yml"

class Dictionary
    attr_accessor :dictionary 

    def initialize(filename)
        @dictionary = []
        prepare_dictionary(filename)
    end

    def prepare_dictionary(filename)
        @dictionary = File.read(filename).gsub(/\r\n/, " ").split
        @dictionary = @dictionary.select { |word| word.length > 2 && word.length < 18 }
    end

    def sample
        @dictionary.sample
    end
end

class Player
    def input
        gets.chomp.downcase
    end
end

class Game
    attr_accessor :hidden_word
    attr_reader   :secret_word, :guesses_left, :player,
                  :game_file, :game_finished

    def initialize
        @dictionary         = Dictionary.new("dictionary.txt")
        @secret_word        = @dictionary.sample.split("")
        @hidden_word        = create_hidden_word
        @wrong_characters   = ["-"]
        @guesses_left       = @secret_word.length
        @player             = Player.new
        @game_file          = "saved_game.yaml"
        @game_saved         = false
        @game_finished      = false
    end

    def setup
        print_home_screen
        check_action(player.input)
    rescue Interrupt
        exit_game
    end

    def start
        loop do
            print_board
            check_guess(check_input(player.input))
            player_loses if @guesses_left.zero?
        end
    end

    def create_hidden_word
        @secret_word.map { |letter| "_" if letter }
    end

    def check_action(input)
        start if input == ""

        case input
        when "load" then load_game
        when "exit" then exit_game
        else start
        end
    end

    def check_input(input)
        return input if input.length == secret_word.length

        case input
        when "exit" then exit_game
        when "save" then saved_game
        when ""     then "_"
        else input[0]
        end
    end

    def check_guess(input)
        if input_is_a_word(input)
            check_introduced_word(input)
        elsif character_is_in_secret_word(input)
            add_characters(input)
            player_wins if secret_word_is_equal_to(hidden_word.join)
        else
            add_character_to_wrong_characters(input)
            @guesses_left -= 1
        end
    end

    def input_is_a_word(input)
        input.length == secret_word.length
    end

    def check_introduced_word(input)
        secret_word_is_equal_to(input) ? player_wins : player_loses
    end

    def secret_word_is_equal_to(input)
        secret_word.join("").casecmp(input).zero?
    end

    def character_is_in_secret_word(input)
        secret_word.any? { |character| character.casecmp(input).zero? }
    end

    def add_characters(input)
        indexes =  secret_word.map
                              .with_index { |char, idx| idx if char.casecmp(input).zero? }
                              .compact

        indexes.each { |index| hidden_word[index] = input }
    end

    def add_character_to_wrong_characters(input)
        @wrong_characters = [] if @guesses_left == @secret_word.length
        @wrong_characters << input unless @wrong_characters.include?(input)
    end

    def load_game
        yaml = YAML.safe_load(File.open(game_file))

        @secret_word        = yaml["secret_word"]
        @hidden_word        = yaml["hidden_word"]
        @wrong_characters   = yaml["wrong_characters"]
        @guesses_left       = yaml["guesses_left"]

        start
    end

    def saved_game
        data = { "secret_word"      => @secret_word,
                 "hidden_word"      => @hidden_word,
                 "wrong_characters" => @wrong_characters,
                 "guesses_left"     => @guesses_left }

        yaml = YAML.dump(data)

        File.open(game_file, "w") { |file| file.puts yaml }

        @game_saved = true

        start
    end

    def player_wins
        result("player_wins")
    end

    def player_loses
        result("player_loses")
    end

    def result(result)
        @game_finished = true

        print_board

        if result == "player_wins"
            puts "You WIN!\n\n"
        else
            puts "You lose.\n\n"
        end

        puts "The correct word was: #{secret_word.join}\n\n"
        print "Play again? (Y,n)?\n>"

        play_again
    end

    def play_again
        loop do
            case gets.chomp.downcase
            when "y" then Game.new.start
            when "n" then exit_game
            else
                print_board
                print "Please type 'Y' or 'n'.\n>"
            end
        end
    end

    def exit_game
        clear_screen
        puts "Thanks for playing. Hope you like it!\n\n"
        exit
    end

    def print_home_screen
        clear_screen
        print_game_title
        puts "Type 'load' to open the last saved game."
        puts "Type 'save' during gameplay to save the game."
        puts "Type 'exit' to close the game.\n\n"
        puts "Press 'enter' to start."
    end

    def print_game_title
        puts " _    _"
        puts "| |  | |"
        puts "| |__| | __ _ _ __   __ _ _ __ ___   __ _ _ __"
        puts "|  __  |/ _` | '_ \\ / _` | '_ ` _ \\ / _` | '_ \\"
        puts "| |  | | (_| | | | | (_| | | | | | | (_| | | | |"
        puts "|_|  |_|\\__,_|_| |_|\\__, |_| |_| |_|\\__,_|_| |_|"
        puts "                     __/ |"
        puts "                    |___/"
        puts "\n"
    end

    def print_board
        clear_screen
        print_guesses
        print_wrong_characters
        empty_line
        print_hidden_word
        print_game_saved
        empty_line
        print_input_message
    end
    
    def clear_screen
        system "clear" || "cls"
    end

    def print_guesses
        puts "Guesses left: #{@guesses_left}"
    end

    def empty_line
        puts "\n"
    end

    def print_hidden_word
        puts hidden_word.join(" ")
    end

    def print_wrong_characters
        puts "Wrong characters: #{@wrong_characters.join(" ")}"
    end

    def print_input_message
        return if @game_finished
        print "Introduce a letter:\n> "
    end
end

Game.new.setup 