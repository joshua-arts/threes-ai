# Contains a bunch of operations to perform on a board.

MOVES = ["right", "left", "down", "up"]

# Moves the board right.
def move_right(arr)
    new_board = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
    arr.each_with_index{|row, row_num|
           3.downto(1){|wall|
             if can_merge?(row[wall], row[wall - 1])
                  (0...wall).each{|i|
                     new_board[row_num][i + 1] = row[i]
                 }
                 new_board[row_num][wall] = row[wall] + row[wall - 1]

                ((wall + 1)...4).each{|i|
                    new_board[row_num][i] = row[i]
                }
                break
            end
        }
    }

    (0...4).each{|row_num|
        row_all_zeros = true
        (0...4).each{|col|
            if new_board[row_num][col] != 0
                row_all_zeros = false
                break
            end
        }
        if row_all_zeros
            (0...4).each{|col|
                new_board[row_num][col] = arr[row_num][col]
            } 
        end
    }
    new_board
end

# Moves the board left.
def move_left(arr)
    mirror_board_horizontal(move_right(mirror_board_horizontal(arr)))
end

# Moves the board down.
def move_down(arr)
    rotate_right(move_right(rotate_left(arr)))
end

# Moves the board up.
def move_up(arr)
    rotate_left(move_right(rotate_right(arr)))
end

# Rotates the board right.
def rotate_right(arr)
    mirror_board_horizontal(arr.transpose)
end

# Rotates the board left.
def rotate_left(arr)
    mirror_board_horizontal(arr).transpose
end

# Compares two board.
def compare_boards?(a, b)
    (0...4).each{|row|
        (0...4).each{|col|
            return false if a[row][col] != b[row][col]
        }  
    }
    true
end

# Prints a board.
def print_board(board)
    board.each{|row|
        puts row.inspect   
    }
end

# Copies a board.
def copy_board(board)
    new_board = [[],[],[],[]]
    (0...4).each{|row|
        (0...4).each{|col|
            new_board[row][col] = board[row][col]
        }
    }
    new_board
end

# Mirrors the board horizontally.
def mirror_board_horizontal(board)
    new_board = []
    (0...4).each{|row|
        new_board[row] = board[row].reverse
    }
     new_board
end
    
# Mirrors the board vertically.
def mirror_board_vertical(board)
    rotate_right(rotate_right(mirror_board_horizontal(board)))
end

# Adds a card to a board in a given direction.
def add_card(board, dir, tile)
    return if not MOVES.include? dir
    row_lists = [board.transpose[0], board.transpose[3], board[0], board[3]]
        
    row_list = row_lists[MOVES.index(dir)]
        
    possible_spots = []
    row_list.each_with_index{|val, i|
        possible_spots << i if val == 0
    }
    return board if possible_spots.length == 0
    pos = possible_spots.sample
    if dir == "right"
        board[pos][0] = tile
    elsif dir == "left"
        board[pos][3] = tile
    elsif dir == "down"
        board[0][pos] = tile
    elsif dir == "up"
        board[3][pos] = tile
    end
    board
end
    
# Determines if the board is full.
def board_full?(board)
    board.flatten.count(0) > 0
end