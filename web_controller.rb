# Opens a Chrome browser window and runs the AI on threesjs.com .

# Special thanks to github user nneonneo, the JavaScript this web controller uses was borrowed from his AI (with permission).

require "selenium-webdriver"

Selenium::WebDriver::Chrome.driver_path = "path to chromedriver here"

class WebController
    
    attr_reader :driver

    # World record is the 6144 tile, virtually impossible to exceed.
    # 12288 support just incase somehow...
    TILES = [0,1,2,3,6,12,24,48,96,192,384,768,1536,3072,6144,12288]
    
    DIRECTIONS = ["left", "right", "up", "down"]
    
    def initialize
        @driver = Selenium::WebDriver.for :chrome
    end
    
    def setup
        # Wait to ensure page is fully loaded.
        sleep(4)
        
        @driver.execute_script('''
        window.win = window.requestAnimationFrame;
        window.requestAnimationFrame = function(f) { window.ThreesWebCore = f.scope; window.win.apply(this, arguments); }
        ''')
        
        while @driver.execute_script("typeof(window.ThreesWebCore)") == 'undefined'
            time.sleep(0.01)
        end
        
        @driver.execute_script('''
        window.requestAnimationFrame = window.win;
        window.ThreesState = window.ThreesWebCore.app.host.game.__class__.state;
        window.ThreesGame = window.ThreesState._states.get("game");
        0;
        ''')

        puts "Setup complete. \n---------------"
    end
    
    # Executes a move on play.threesgame.com .
    def make_move(move)
        if DIRECTIONS.include? move
            key = {'up' => :up, 'down' => :down, 'left' => :left, 'right'=> :right}[move]
            @driver.action.send_keys(key).perform
            sleep(0.02)
        else
            puts "ERROR: Invalid move."
        end
    end

    # Gets the current state of the game from play.threesgame.com .
    def get_state
        return @driver.execute_script('''var a = window.ThreesGame.__class__.state
        return a[0]''')
    end
    
    # Gets the board from play.threesgame.com .
    def get_board
        board = @driver.execute_script('''
            b = window.ThreesGame.grid.map(function(t) { return t.value; });
            return b
            ''')
        
        board = board.each_slice(4).to_a
        board
    end
    
    # Gets the next tile from play.threesgame.com .
    def get_next_tile()
        toptile = @driver.execute_script('''c =  window.ThreesGame.futureValue
        return c''')
        return toptile
    end
    
    # Starts the web controller and navigates to play.threesgame.com .
    def start
        @driver.navigate.to "http://play.threesgame.com"
        sleep(0.5)
    end
    
    # Restarts a game from the scoring screen.
    def restart
        while get_state() == 'LOST'
            # Press a key to get score.
            @driver.action.send_keys(:up).perform
            sleep(0.2)
        end

        while get_state() == 'MENU'
            @driver.action.send_keys(:space).perform
            sleep(0.2)
        end

        @driver.action.send_keys(:space).perform
    end
    
    # Sends a key input to play.threesgame.com .
    def input_key(key)
        @driver.action.send_keys(key).perform
    end
    
end
