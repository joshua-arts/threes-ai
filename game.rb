require_relative 'web_controller.rb'
require_relative 'board_opertations.rb'

class Game
    
    attr_reader :board, :deck, :mode, :playing, :next_tile, :games, :moves_ahead
    
    # Point values & multipliers for scoring boards.
    EMPTY_POINTS   = 2   # Points per empty space.
    MERGE_POINTS   = 3   # Points per mergeable pair of tiles.
    DOUBLE_POINTS  = 1   # Points per tile next to a tile double it's value.
    TRAPPED_POINTS = 5   # Points lost per tile trapped by larger tiles.
    CORNER_BONUS   = 20  # Bonus points for having your largest tile in a corner.
    
    # NOTE: Basically force it to make the merge move if it can merge a tile above 192.
    MAX_TILE_BONUS = 400 # Bonus points for having a new max tile (only when above 192).
    
    # Sample starting board.
    EMPTY_BOARD = [[0,0,0,0],
                   [0,0,0,0],
                   [0,0,0,0],
                   [0,0,0,0]]
    
    # The 12 card repeating deck the game uses.
    STARTING_DECK = [1,1,1,1,2,2,2,2,3,3,3,3]
    
    # Indicies represent rank value - 1 for calculating final score.
    SCORE_VALUES = [3,6,12,24,48,96,192,384,768,1536,3072,6144]
    
    def initialize(mode = :console, board = EMPTY_BOARD, deck = STARTING_DECK)
        @mode = mode
        @board = board
        @deck = deck
        @playing = false
        @games = 1
        @moves_ahead = 4
    end
    
    # Set the number of games the AI plays.
    def set_games(games)
        @games = games 
    end
    
    # Sets the number of moves ahead the AI thinks.
    def set_moves_ahead(moves_ahead)
        @moves_ahead = moves_ahead 
    end
    
    # Determines if two tiles can merge.
    def can_merge?(a, b)
        low = [a,b].min
        return true if low == 0
        high = [a,b].max
        return true if a == b and a != 1 and b != 2
        return true if low == 1 and high == 2
        false
    end
    
    # Determines if two tiles can merge not including moving to empty space.
    def can_merge_exclude_empty?(a, b)
        can_merge?(a, b) and a > 0 and b > 0       
    end

    # Determines if a tile is trapped vertically by a wall or larger tile.
    # NOTE: 6145 represents wall (has to be larger than higihest tile of 6144).
    def is_trapped_vertical?(board, row, col)
        if row == 3
            around = [board[row - 1][col], 6145]
        elsif row == 0
            around = [6145, board[row + 1][col]]
        else
            around = [board[row - 1][col], board[row + 1][col]]
        end
        board[row][col] < around[0] and board[row][col] < around[1] and around[0] > 2 and around[1] > 2
    end
       
    # Determines if a tile is trapped horizontally by a wall or larger tile.
    # NOTE: 6145 represents wall (has to be larger than higihest tile of 6144).
    def is_trapped_horizontal?(board, row, col)
        if col == 3
            around = [board[row][col - 1], 6145]
        elsif col == 0
            around = [6145, board[row][col + 1]]
        else
            around = [board[row][col - 1], board[row][col + 1]]
        end
        board[row][col] < around[0] and board[row][col] < around[1] and around[0] > 2 and around [1] > 2
    end
    
    # Determines if a tile is next to a tile double its value.
    def check_adjacent?(board, row, col)
        val = board[row][col]
        return true if row < 3 and board[row + 1][col] == (val * 2)
        return true if row > 0 and board[row - 1][col] == (val * 2)
        return true if col < 3 and board[row][col + 1] == (val * 2)
        return true if col > 0 and board[row][col - 1] == (val * 2)
        false
    end
    
    # Counts how many of a given tile is on a board.
    def tile_count(board, tile)
        board.flatten.count(tile)
    end
    
    # Converts a path number to a move.
    def move_by_number(num, board)
        return move_right(board) if num == 0
        return move_left(board) if num == 1
        return move_down(board) if num == 2
        return move_up(board) if num == 3
        puts "ERROR: Invalid move number."
    end
    
    # Prompts the user for a move (:console only).
    def prompt_move()
        puts "Enter a move (up, down, left, right) or 'quit' to quit:"
        return gets.chomp.downcase
    end
    
    # Makes a move on the board (:console only).
    def make_move(dir)
        case dir
            when "right" then shifted = move_right(@board)
            when "left" then shifted = move_left(@board)
            when "down" then shifted = move_down(@board)
            when "up" then shifted = move_up(@board)
            when "quit" then 
                @playing = false
                return
            else 
                puts "ERROR: #{dir} is not a valid move."
                return
        end
        if not compare_boards?(@board, shifted)
            @board = add_card(shifted, dir, @next_tile)
            @next_tile = get_next_tile()
        else
            puts "Can't move that direction!"
        end
    end
    
    # Gets the next tile from the deck.
    def get_next_tile
        @deck = [1,1,2,2,3,3,6,6,12,12,24,24] if @deck.length == 0
        tile_num = Random.rand(0...@deck.length)
        @next_tile =  @deck.delete_at(tile_num)      
    end
    
    # Detemines if there are no valid moves on a board.
    def game_over?(board)
        return false if board_full?(board)
        mergeable = 0
        (0...4).each{|row|
            (0...3).each{|col|
                return false if can_merge?(board[row][col], board[row][col+1])
            }
        }
        (0...3).each{|row|
            (0...4).each{|col|
                return false if can_merge?(board[row][col], board[row+1][col])
            }
        }
        true
    end
    
    # Generates a starting game board.
    # I'm not sure how Threes! does this exactly, but from my tests this should be more than accurate enough.
    def gen_board
        checking = true
        board = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
        tiles = [1,2,3].shuffle
        fills = (Random.rand(1..2) == 1 ? [3,3,3] : [4,3,2])
        tiles.each_with_index{|tile, i|
            fills[i].times{
                while checking do
                    a = Random.rand(0...4)
                    b = Random.rand(0...4)
                    if board[a][b] == 0
                        board[a][b] = tile
                        checking = false
                    end
                end
                checking = true
            }
        }
        board
    end
    
    # NOTE: Redo.
                
    # Scores a board state based on it's longevity.
    def score_board(board, curr_max)
        empty_squares = 0
        mergeable = 0
        next_double = 0
        trapped = 0
        
        empty_squares = tile_count(board, 0)
        
        (0...4).each{|row|
            (0...3).each{|col|
                mergeable += 1 if can_merge_exclude_empty?(board[row][col], board[row][col + 1])
            }
        }
        
        (0...3).each{|row|
            (0...4).each{|col|
                mergeable += 1 if can_merge_exclude_empty?(board[row][col], board[row + 1][col])
            }
        }
        
        (0...4).each{|row|
            (0...4).each{|col|
                next_double += 1 if check_adjacent?(board, row, col)
                next_double += 2 if board[row][col] > 192
            }    
        }
        
        (0...4).each{|row|
            (0...4).each{|col|
                trapped += 1 if board[row][col] > 0 and (is_trapped_vertical?(board, row, col) or is_trapped_horizontal?(board, row, col))
            }    
        }
        
        bonus = 0
        max_tile = board.flatten.max
        bonus += CORNER_BONUS if board[0][0] == max_tile || board[0][3] == max_tile || board[3][0] == max_tile || board[3][3] == max_tile
        
        bonus += MAX_TILE_BONUS if max_tile > curr_max and curr_max > 192
        
        score = (empty_squares * EMPTY_POINTS) + (mergeable * MERGE_POINTS) + (DOUBLE_POINTS * 2) - (trapped * TRAPPED_POINTS) + bonus
        score
    end
            
    # Scores a path of moves of @move_ahead length.
    def get_path_score(path, board, next_tile)
        curr_max = board.flatten.max
        curr_board = board
        total_score = 0
        (0...@moves_ahead).each{|i|
            new_board = move_by_number(path[i], curr_board)
            new_board = add_card(new_board, MOVES[path[0]], next_tile) if i == 0
            total_score += (score_board(new_board, curr_max))
            curr_board = new_board
        }
        (total_score / path.length)
    end
       
    # Detemines if a path of moves can be executed.
    def valid_path?(path, board)
        if path[0] == 0
            new_board = move_right(board)
        elsif path[0] == 1
            new_board = move_left(board)
        elsif path[0] == 2
            new_board = move_down(board)
        elsif path[0] == 3
            new_board = move_up(board)
        end
        compare_boards?(board, new_board)
    end            
    
    # Gets the best possible move as scored by the AI.
    def get_best_move(board, next_tile)
        max_score = 0
        max_path = []
        
        mult_arr = [0,1,2,3]

        # Set up all possible paths to take.
        paths = @moves_ahead==1 ? mult_arr : mult_arr.product(*[mult_arr]*(@moves_ahead-1))
        
        all_scores = []
        paths.each{|path|
            path_score = get_path_score(path, board, next_tile)
            all_scores << path_score
        }
        
        ind_of_max = all_scores.index(all_scores.max)
        max_path = paths[ind_of_max]
        
        while valid_path?(max_path, board) do
            all_scores.delete_at(ind_of_max)
            paths.delete_at(ind_of_max)
            ind_of_max = all_scores.index(all_scores.max)
            max_path = paths[ind_of_max]
        end
        
        MOVES[max_path[0]]
    end        
    
    # Calculates the final score of a board at the end game.
    def score_endgame(board)
        points = 0
        (0...4).each{|row|
            (0...4).each{|col|
                points += (3**(SCORE_VALUES.index(board[row][col]) + 1)) if SCORE_VALUES.include? board[row][col]
            }    
        }
        points + 3
    end
    
    # Generic start method for starting a game.
    def start        
        @playing = true
        mode == :console ? play_console() : play_ai()
    end
                
    # Game loop for playing in the console (:ai only).
    def play_console
        
        # Generate a board if none specified.
        @board = gen_board() if @board == EMPTY_BOARD
        
        print_board(@board)
        
        # Get a next tile.
        @next_tile = get_next_tile()
        
        # Run game loop.
        while @playing do
            
            puts "NEXT TILE IS: #{@next_tile}"
            make_move(prompt_move())
            
            # Check for game over.
            if game_over?(@board)
                @playing = false
                puts "GAME OVER."
                puts "Final score: #{score_endgame(@board)}"
            end
            
            print_board(@board)
        end      
    end
                
    # Game loop for playing with the AI (:ai only).
    def play_ai
        
        # Setup WebController.
        web = WebController.new()
        puts "Connecting to play.threesgame.com, please wait."
        web.start()
        web.setup()
        
        puts "Before the AI can play, you need to play the tutorial!\n" +
        "Once you finish, start a new game.\n" + 
        "Then, enter something into the console to start the AI!"
        
        # Get any user input to start the AI.
        gets.chomp.downcase
        
        all_scores = []
        max_tiles = []
        @board = mirror_board_vertical(web.get_board())
        begin_time = Time.now
        
        # Run @games times.
        (0...@games).each{|game_num|
            
            # Setup game.
            game_start_time = Time.now
            puts "---------------\n" +
            "STARTING GAME #{game_num + 1}..."
            moves = 0
            
            # Start new game.
            while @playing do
                
                @board = mirror_board_vertical(web.get_board())
                @next_tile = web.get_next_tile()
                web.make_move(get_best_move(@board, @next_tile))
                moves += 1
                
                if web.get_state == "LOST"
                    @playing = false
                    final_score = score_endgame(@board)
                    all_scores << final_score
                    max_tiles << @board.flatten.max
                    
                    # Display game stats.
                    puts "SCORE: #{final_score}\n" +
                    "MOVES: #{moves}\n" +
                    "MAX TILE: #{@board.flatten.max}\n" +
                    "GAME TIME: #{(Time.now - game_start_time)} seconds.\n" +
                    "---------------"
                    
                    # Reset game state.
                    web.restart()
                end
            end
            
            @playing = true
        }
        
        # Display overall AI stats.
        puts "Played #{@games} total games in #{(Time.now - begin_time)} seconds.\n" +
        "The highest score reached was: #{all_scores.max}\n" + 
        "The average score was: #{all_scores.inject(0){|sum,x| sum + x } / all_scores.length}"
        
        puts "\nMax tile distribution:"
        SCORE_VALUES.each{|tile|
            num = max_tiles.count(tile)
            puts "#{tile}: #{num} -- #{((num.to_f/@games)*100).to_i}% of games."
        }
    end

end            