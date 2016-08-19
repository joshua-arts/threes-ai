# Threes! AI

## About

Congratulations! You've found the first Ruby implementation of a Threes! playing AI on github!

The inspiration for this AI came as I was constantly getting sub-par scores, and wanted to see if I could build an AI that could out perform my own level. I also found many other AI's that we're using algorithms that I thought could be vastly improved upon to increase the longevity of a given game.

After one-hundred runs, the highest score this AI reached was 86,472. You can see a video of the AI playing that game [here](https://www.youtube.com/watch?v=BYqph34Sdos).

<p align="center">
  <img src="http://i64.tinypic.com/r89hdl.jpg"/>
</p>

Just to put the score into perspective, here a a few stats from running the AI one-hundred times:

* The AI reached the 384 tile 82% of the time, only about 32% of players ever reach this tile.
* The AI reached the 768 tile 38% of the time, only about 8% of players ever reach this tile.
* The AI reached the 1536 tile 5% of the time, only about 0.18% of players ever reach this tile.

And now of course, the goal is to optimize this more to try and achieve the elusive 3072 tile.

## Algorithm

The AI doesn't predict what card is coming in, score boards based on what card is likily to come in, or score boards based on where likily cards could come in. The score it produces is purely from traversing the game tree for each possible move at a given depth, and generatng a heuristic score for each state (using the below algorithm).

The AI looks ahead x number of moves (set to four by default) and scores the boards based on the algorithm. It then totals and averages the scores to determine the best move path to take. It analyzes board states by 'scoring' boards based not on thier total points, but based on their longevity (a method pioneered by [Walt Destler](https://github.com/waltdestler)). In Threes!, the best way to play for a highscore is to play for the most possible moves (or the longest game possible). You need to play to survive, and this is why the AI sometimes makes moves that look like poor moves.

The algorithm for scoring boards is much like the ones used in many other Threes! AI's, but I've tweaked and added many values, including values and conditions that help the AI recognize when the overall score benefit for a move out-weighs the longevity of another move. The boards are scored as follows:

+ add 2 points for every empty space on the board.
+ add 3 points for every pair of adjacent tiles that can merge.
+ add 1 point for every card adjacent to a card twice its value.
+ add 2 more points if the adjacent card is 768 or higher.
+ subtract 5 points for every card trapped between two higher cards, or a higher card and a wall.
+ add 20 points if your highest card is in a corner.
+ force the move (add 400 points) if between moves the max tile changes, and the max tile is 384 or higher.

## Usage

This Threes AI uses the Selenium Ruby Gem in order to communicate with play.threesgame.com. Thus, in order to use it, you should have it installed. The command to do this is:

```ruby
gem install selenium-webdriver
```

Selenium uses the ChromeWebDriver to communicate with Chrome, you'll need that installed as well. To connect it to web_controller.rb simple replace the filepath at the top of the file.

```ruby
Selenium::WebDriver::Chrome.driver_path = "path to chromedriver.exe"
```

Threes AI is incredibly simple to use. In your Ruby file, you are going to want to include the game.rb file.

```ruby
require_relative 'game.rb'
```

Make sure you also have board_operations.rb and web_controller.rb in the same directory.

In your Ruby file, you can create a game like so:

```ruby
my_game = Game.new(:ai) # Create the game.
my_game.set_games(10) # Set the number of games to play, one by default.
my_game.set_moves_ahead(5) # Set the number of moves the AI thinks ahead, four by default.
my_game.start() # Start the game.
```

You can even play in the console by creating a game using the ```:console``` symbol:

```ruby
my_game = Game.new(:console) # Create the game.
my_game.start() # Start the game.
```

And lastly, if you'd like to start with a custom board or deck, you can supply the to the Game class (```:console``` only).

```ruby
my_game = Game.new(:console, my_board, my_deck)
```

## Credits

 * This wouldn't be possible without the amazing work [Asher Vollmer](https://twitter.com/AsherVo) and [Greg Wohlwend](https://twitter.com/aeiowu) did developing [Threes!](http://asherv.com/threes/)
 * The algorithm for this AI was inspired by the algorithm [Threesus](https://github.com/waltdestler/Threesus) uses, developed by [Walt Destler](https://github.com/waltdestler).
 * Some of the Javascript that the web controller uses to fetch data from play.threesgame.com was borrowed from [nneonneo's AI project](https://github.com/nneonneo/threes-ai) (with permission of course!).
