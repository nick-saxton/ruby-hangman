require 'yaml'

class Game
  # Create the game object
  # Can optionally be passed starting parameters - used for loading a save game
  def initialize(args = {})
    words = []

    File.open("5desk.txt", "r") do |f|
      f.each_line do |line|
        if line.strip!.length >= 5 and line.length <= 12
          words << line
        end
      end
    end

    @secret_word = words.sample.upcase

    @incorrect_guesses = 0
    @guessed_letters = []
    @word_state = ("_" * @secret_word.length).split("")
  end

  # Performs basic validation on the user input and checks if it's a correct or incorrect guess
  def check_input guessed_letter
    if guessed_letter =~ /^[A-Za-z]$/ and !@guessed_letters.include? guessed_letter.upcase
      # Convert the guessed letter to uppercase
      guessed_letter = guessed_letter.upcase

      # Add to the list of letters that have been guessed so far
      @guessed_letters << guessed_letter
      
      # See if the guessed letter is in the secret word
      if @secret_word.include? guessed_letter
        # ...and update the word state if it is
        offset = 0
        while !@secret_word.index(guessed_letter, offset).nil?
          position = @secret_word.index(guessed_letter, offset)
          @word_state[position] = guessed_letter
          offset = position + 1
        end
      else
        @incorrect_guesses += 1
      end
    elsif guessed_letter.upcase == "SAVE"
      save_game
    end
  end

  # Checks to see if the user has won the game
  def check_win
    if !@word_state.include? "_"
      puts "You've guessed the secret word and avoided death. For now..."
      puts
      exit
    end
  end

  # Updates game instance from YAML file
  def from_yaml(string)
    data = YAML.load string

    @secret_word = data[:secret_word]
    @incorrect_guesses = data[:incorrect_guesses]
    @guessed_letters = data[:guessed_letters]
    @word_state = data[:word_state]
  end

  # Gets the user's input
  def get_input
    print "\nGuess a letter (or type \"save\" to save the game): "
    gets.chomp
  end

  # Prints the instructions for the game
  def instructions
    puts
    puts "Welcome to Hangman!"
    puts "-------------------"
    puts "You're headed to the gallows!"
    puts "But you can still change your"
    puts "fate if you guess the secret"
    puts "word one letter at a time."
    puts "Each incorrect guess sends"
    puts "you a step closer to your"
    puts "doom. Six incorrect guesses"
    puts "and you hang!"
    puts
  end

  # The main play method for the game
  # Loops until the user wins or loses
  def play
    instructions

    show_options

    while @incorrect_guesses < 6
      guessed_letter = get_input
      check_input guessed_letter
      render      
      check_win
    end

    puts "You're out of guesses. Time to hang!"
    puts
  end

  # Renders the current state of the game
  def render
    head = @incorrect_guesses > 0 ? "o" : " "
    left_arm = @incorrect_guesses > 1 ? "/" : " "
    torso = @incorrect_guesses > 2 ? "|" : " "
    right_arm = @incorrect_guesses > 3 ? "\\" : " "
    left_leg = @incorrect_guesses > 4 ? "/" : " "
    right_leg = @incorrect_guesses > 5 ? "\\" : " "

    puts %{
      ______
     |      |
     #{head}      |
    #{left_arm}#{torso}#{right_arm}     |
    #{left_leg} #{right_leg}     |
         -------
    }
    puts "\n#{@word_state.join(" ")}"
    puts "\nGuessed letters: #{@guessed_letters.sort().join(", ")}"
    puts "\n"
  end

  # Saves the current game to a YAML file
  def save_game
    File.open("save.yml", "w") do |file|
      file.puts(self.to_yaml)
    end
  end

  def show_options
    choice = nil

    while choice != "1" and choice != "2"
      puts
      puts "Options:"
      puts " 1 - New game"
      puts " 2 - Load saved game"
      print "What would you like to do: "

      choice = gets.chomp

      if choice == "2" and !File.exist?("save.yml")
        puts
        puts "There is not a saved game to load. Please select option 1 for a new game."
        choice = nil
      end
    end

    if choice == "2"
      if File.exist?("save.yml")
        from_yaml File.read("save.yml")
      end
    end
  end

  # Dumps the game state to YAML for saving
  def to_yaml
    YAML.dump({
      :secret_word => @secret_word,
      :incorrect_guesses => @incorrect_guesses,
      :guessed_letters => @guessed_letters,
      :word_state => @word_state
    })
  end
end


game = Game.new
game.play