io.stdout:setvbuf("no")

local WIDTH, HEIGHT = 320, 180
local scale = 3

local lg = love.graphics
local lt = love.timer
local lk = love.keyboard
local lm = love.mouse

lg.setDefaultFilter('nearest', 'nearest')

--
-- Objects
--
local player = require("player")
local Asteroid = require("asteroid")
local Timer = require("timer")

local bullets = {}
local asteroids = {}
local camera = {x, y}

--
-- Game Loop
--
function love.load()  
    math.randomseed(os.time())

    gameState = "start"

    -- Draw
    lg.setLineStyle("rough")
    lg.setBackgroundColor(19/255, 18/255, 23/255)
    drawCanvas = lg.newCanvas(WIDTH, HEIGHT)

    texStart = love.graphics.newImage("assets/sprites/start1.png")
    texBG = love.graphics.newImage("assets/sprites/bg1.png")
    texGameOver = love.graphics.newImage("assets/sprites/over1.png")

    -- Font
    fontMonogram = love.graphics.newFont("assets/fonts/monogram.ttf", 16)
    fontMonogram:setFilter("nearest", "nearest")
    lg.setFont(fontMonogram)

    -- Sounds
    sfxShake = love.audio.newSource("assets/sounds/shake1.wav", "static")
    sfxFire = love.audio.newSource("assets/sounds/fire1.wav", "static")

    -- Game
    player:init()
    
    for i = 1, 7 do 
        spawnAsteroids(1, math.random(WIDTH), math.random(HEIGHT), 1)
    end
    
    score = 0
    highScore = 0
    justFired = false

    -- Timers
    shakeTimer = Timer:new()
end

function spawnAsteroids(amount, x, y, factor)
    for i = 1, amount do 
        local esteroid = Asteroid:new(x, y, factor)
        esteroid:generateVertices()
        table.insert(asteroids, esteroid)
    end
end

function pointCircleCollisionCheck(px, py, cx, cy, radius)
    a = (cx - px) ^ 2 
    b = (cy - py) ^ 2
    distanceSquared = a + b
    radiusSquared = radius ^ 2

    if distanceSquared < radiusSquared then
        return true
    end
end

function checkAsteroidCollision(bullet)
    for i, asteroid in ipairs(asteroids) do 
        if pointCircleCollisionCheck(bullet.x, bullet.y, asteroid.x, asteroid.y, asteroid.radius) then 
            score = score + 1

            -- If asteroid is big spawn smaller ones
            if asteroid.factor < 4 then 
                spawnAsteroids(math.random(2, 4), bullet.x, bullet.y, asteroid.factor * 2) 
            end
            
            -- Remove current asteroid from list
            table.remove(asteroids, i)

            shakeTimer:start(0.1, false)
            sfxShake:play()

            return true
        end 
    end

    return false
end

function checkPlayerCollision(asteroid)
    if pointCircleCollisionCheck(player.x, player.y, asteroid.x, asteroid.y, asteroid.radius) then 
        if player.isVulnerable then 
            player.isDead = true
            player.lives = player.lives - 1
            shakeTimer:start(0.2, false)
            sfxShake:play()

            return true
        end
    end

    return false
end

function love.update(dt)
    if gameState ~= "run" then 
        return
    end 

    -- Handle gameover
    if player.lives == 0 then
        if score > highScore then 
            highScore = score
        end

        gameState = "gameOver"

        -- Reset Player state
        player.x = WIDTH/2
        player.y = HEIGHT/2
        player.lives = 3
        player.isVulnerable = false
        player.spawnAnimPlaying = true

        -- Respawn asteroids
        asteroids = {}
        for i = 1, 7 do 
            spawnAsteroids(1, math.random(WIDTH), math.random(HEIGHT), 1)
        end

        return
    end

    -- Handle bullet fire, "justFired" prevents fire spam on buttom hold
    local firePressed = lk.isDown("z") or lk.isDown("x") or lk.isDown("space") or lm.isDown(1)

    if firePressed and player.isVulnerable and not justFired then
        local startX, startY = player.x, player.y
        local directionX = math.cos(math.rad(player.angle + math.random(-10, 10)))
        local directionY = math.sin(math.rad(player.angle + math.random(-10, 10)))
        
        table.insert(bullets, {
            x = startX, 
            y = startY, 
            dx = directionX, 
            dy = directionY, 
            speed = 200, 
            distanceTraveled = 0
        })


        justFired = true
        sfxFire:play()
    end

    -- Update player
    player:update(dt)

    -- Update asteroids
    for i, asteroid in ipairs(asteroids) do
        asteroid:update(dt)
        if checkPlayerCollision(asteroid) then
            bullets = {}
            break
        end
    end

    -- Update bullets and check for collisions
    for i, bullet in ipairs(bullets) do
        bullet.x = bullet.x + (bullet.dx * bullet.speed * dt)
		bullet.y = bullet.y + (bullet.dy * bullet.speed * dt)
        bullet.distanceTraveled = bullet.distanceTraveled + 1
    
        if bullet.x > WIDTH then bullet.x = 0 end
        if bullet.x < 0 then bullet.x = WIDTH end
        if bullet.y > HEIGHT then bullet.y = 0 end
        if bullet.y < 0 then bullet.y = HEIGHT end

        -- If hit asteroid spawn 2 new smaller ones and increase score
        if checkAsteroidCollision(bullet) then 
            table.remove(bullets, i)
        end

        if bullet.distanceTraveled > 60 then 
            table.remove(bullets, i)
        end
    end

    -- Spawn new asteroids when there's no one left
    if #asteroids < 1 then 
        for i = 1, 7 do 
            spawnAsteroids(1, math.random(WIDTH), math.random(HEIGHT), 1)
        end

        -- Make player invulnerable in case asteroid spawn on top
        player.isVulnerable = false
        player.spawnAnimPlaying = true
    end
end

function love.draw(dt)
    lg.setCanvas(drawCanvas)
    lg.clear()
    -- Draw other game states
    if gameState == "start" then 
        lg.draw(texStart, 0, 0)

        lg.setCanvas()
        lg.scale(scale, scale)
        lg.draw(drawCanvas)
        
        return
    elseif gameState == "gameOver" then 
        lg.draw(texGameOver, 0, 0)

        local textY = HEIGHT / 2 - fontMonogram:getHeight() / 2  -- Calculate vertical position for text
        lg.printf("score: " .. score, 0, textY + 10, WIDTH, "center")  -- Adjust textY as needed
        lg.printf("highScore: " .. highScore, 0, textY + 20, WIDTH, "center")  -- Adjust textY as needed

        lg.setCanvas()
        lg.scale(scale, scale)
        lg.draw(drawCanvas)
        
        return
    end

    lg.draw(texBG, 0, 0)

    player:draw()

    -- Bullets
    for i, bullet in ipairs(bullets) do
        lg.circle("fill", bullet.x, bullet.y, 1)
    end

    -- Asteroids
    lg.push("all")
    lg.setColor(75/255, 68/255, 102/255)
    for i, asteroid in ipairs(asteroids) do
        asteroid:draw()
    end
    lg.pop()

    -- Screenshake
    if shakeTimer:tick(lt.getDelta()) then 
        local dx = math.random(-3, 3)
        local dy = math.random(-3, 3)
        lg.translate(dx, dy)

        if shakeTimer.ticks == 1 then shakeTimer:stop() end
    end

    -- Score
    love.graphics.setLineWidth(1)
    lg.print("score: " .. score, 4, 0)
    lg.print("lives: " .. player.lives, WIDTH - 52, 0)

    -- End Draw
    lg.setCanvas()
    lg.scale(scale, scale)
    lg.draw(drawCanvas)
end

function love.keypressed(key)
    if key == "return" and gameState == "start" then 
        gameState = "run"
        score = 0
    elseif key == "return" and gameState == "gameOver" then
        gameState = "start"
    end

    -- Quit
    -- if key == "escape" then
    --     love.event.quit()
    -- end
end

function love.keyreleased(key)
    justFired = false;
end

function love.mousereleased()
    justFired = false;
end
