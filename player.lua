local WIDTH, HEIGHT = 320, 180
local lg = love.graphics
local lk = love.keyboard

local Timer = require("timer")

Stick = {}

function Stick:new(x, y) 
    stick = {
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        speed = 20,
        friction = 0.9,
        dirAngle = math.random(-180, 180),
        rotAngle = math.random(-180, 180),
        turnSpeed = 5,
    }

    setmetatable(stick, self)
    self.__index = self
    return stick
end

function Stick:update(dt)
    self.rotAngle = self.rotAngle + self.turnSpeed * dt 
    local angle = math.rad(self.dirAngle) -- Convert angle to radians
    local dx = math.cos(angle)
    local dy = math.sin(angle)
    self.vx = self.vx + dx * self.speed * dt
    self.vy = self.vy + dy * self.speed * dt
    self.vx = self.vx * self.friction
    self.vy = self.vy * self.friction
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function Stick:draw() 
    lg.push("all")  -- Save the current transformation state
    lg.setColor(75/255, 68/255, 102/255)
    lg.translate(self.x, self.y)  -- Move the origin to the stick's position
    lg.rotate(math.rad(self.rotAngle))  -- Rotate by the stick's direction angle
    lg.line(0, 0, 5, 5)  -- Draw the stick from (0, 0) to (5, 5) in the rotated coordinate system
    lg.pop()  -- Restore the original transformation state
end



player = {
    lives = 3,
    sprite = lg.newImage("assets/sprites/ship.png"),
    width,
    height,
    x = WIDTH/2,
    y = HEIGHT/2,
    speed = 0,
    vx = 0,
    vy = 0,
    angle = 0,
    turnSpeed = 5,
    friction = 0.98,
    isVisible = true,
    isVulnerable = true,
    isDead = false,
    deadTime = 2,
    spawnAnimPlaying = false,
    spawnAnimBlinks = 0,
    spawnAnimMaxBlinks = 8,
    sticks = {}
}


function player:init()
    self.width = self.sprite:getWidth()
    self.height = self.sprite:getHeight()
    self.deadTimer = Timer:new()
    self.spawnTimer = Timer:new()

    self.isVulnerable = false
    self.spawnAnimPlaying = true
end

function player:update(dt)
    -- Update sticks when dead
    for i, stick in ipairs(self.sticks) do
        stick:update(dt)
    end
    
    -- Delay before respawn
    if (self.isDead) then
        self:spawnSticks(8)
        self.isVulnerable = false
        
        self.deadTimer:start(self.deadTime, false, function() 
            self.spawnAnimPlaying = true
            self.isDead = false
            self.x = WIDTH/2
            self.y = HEIGHT/2
        end)
        
        self.deadTimer:tick(dt)
        return
    end
    -- Blink animation on spawn
    if self.spawnAnimPlaying then 
        self.spawnTimer:start(0.2, true, function()
            self.isVisible = not self.isVisible
            
            self.spawnAnimBlinks = self.spawnAnimBlinks + 1
            
            if self.spawnAnimBlinks >= self.spawnAnimMaxBlinks then
                self.spawnAnimPlaying = false
                self.isVisible = true
                self.isVulnerable = true
                self.spawnAnimBlinks = 0
                self.sticks = {}
            end
        end)
        
        self.spawnTimer:tick(dt)
    end
    
    
    -- Input
    local left = lk.isDown("left") or lk.isDown("a")
    local right = lk.isDown("right") or lk.isDown("d")
    local foward = lk.isDown("up") or lk.isDown("w")
    if left then self.angle = self.angle - self.turnSpeed end
    if right then self.angle = self.angle + self.turnSpeed end
    if foward then self.speed = 200
    else self.speed = 0 end
    
    -- Movement
    local angle = math.rad(self.angle) -- Convert angle to radians
    local dx = math.cos(angle)
    local dy = math.sin(angle)
    self.vx = self.vx + dx * self.speed * dt
    self.vy = self.vy + dy * self.speed * dt
    self.vx = self.vx * self.friction
    self.vy = self.vy * self.friction
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Handle Bounds
    if self.x > WIDTH then self.x = 0 end
    if self.x < 0 then self.x = WIDTH end
    if self.y > HEIGHT then self.y = 0 end
    if self.y < 0 then self.y = HEIGHT end
end

function player:spawnSticks(amount)
    if #self.sticks == 0 then 
        for i = 1, amount do 
            table.insert(self.sticks, Stick:new(self.x, self.y))
        end
    end
end

function player:draw() 
    for i, stick in ipairs(self.sticks) do 
        stick:draw()
    end
    
    if self.isDead or not self.isVisible then return end
    lg.draw(self.sprite, self.x, self.y, math.rad(self.angle), 1, 1, self.width/2, self.height/2);
end

return player