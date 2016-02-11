-- libraries
class = require 'lib.middleclass'
vector = require 'lib.vector'
state = require 'lib.state'
tween = require 'lib.tween'
serialize = require 'lib.ser'
signal = require 'lib.signal'
Camera = require 'lib.camera'
require 'lib.util'
require 'enet'

-- gamestates
require 'states.game'

-- entities
require 'entities.networkServer'
require 'entities.player'

-- ui

function love.load()
    _font = 'assets/font/OpenSans-Regular.ttf'
    _fontBold = 'assets/font/OpenSans-Bold.ttf'
    _fontLight = 'assets/font/OpenSans-Light.ttf'

    font = setmetatable({}, {
        __index = function(t,k)
            local f = love.graphics.newFont(_font, k)
            rawset(t, k, f)
            return f
        end
    })

    fontBold = setmetatable({}, {
        __index = function(t,k)
            local f = love.graphics.newFont(_fontBold, k)
            rawset(t, k, f)
            return f
        end
    })

    fontLight = setmetatable({}, {
        __index = function(t,k)
            local f = love.graphics.newFont(_fontLight, k)
            rawset(t, k, f)
            return f
        end
    })

    love.window.setIcon(love.image.newImageData('assets/img/icon.png'))
	love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setFont(font[14])

    state.registerEvents()
    state.switch(game)

    math.randomseed(os.time()/10)
end

function love.keypressed(key, code)
    if key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, mbutton)

end

function love.textinput(text)

end

function love.resize(w, h)

end

function love.update(dt)

end

function love.draw()

end
