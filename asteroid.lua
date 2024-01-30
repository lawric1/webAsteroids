local WIDTH, HEIGHT = 320, 180
local lg = love.graphics
local lp = love.physics

local Asteroid = {}

function Asteroid:new(x, y, factor) 
    asteroid = {
        vertices = {},
        x = x,
        y = y,
        speed = math.random(10, 20),
        dirAngle = math.random(-180, 180),
        turnSpeed = math.random(0.2, 1),
        factor = factor,
        radius,
        flashAlpha = 1
    }
    
    setmetatable(asteroid, self)
    self.__index = self
    return asteroid
end

function Asteroid:generateVertices()
    -- Flash effect when spawn
    self.flashAlpha = 1

    -- Generate random radius
    local radius = math.random(15, 25) / self.factor
    self.radius = radius
    local step = 360 / math.random(6, 10)

    -- Generate vertices based on radius
    for angle = 0, 360, step do
        local radAngle = math.rad(angle)
        local x = math.cos(radAngle) * radius
        local y = math.sin(radAngle) * radius

        -- Randomize the vertices to change the shape
        offsetX = math.random(-5, 5)
        x = x + offsetX 

        table.insert(asteroid.vertices, {x = x, y = y})
    end
end

function Asteroid:update(dt)
    -- Movement
    local dx = math.cos(math.rad(self.dirAngle))
    local dy = math.sin(math.rad(self.dirAngle))
    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt
    
    -- Handle Bounds
    if self.x > WIDTH then self.x = 0 end
    if self.x < 0 then self.x = WIDTH end
    if self.y > HEIGHT then self.y = 0 end
    if self.y < 0 then self.y = HEIGHT end

    -- Rotation
    local cos = math.cos(math.rad(self.turnSpeed))
    local sin = math.sin(math.rad(self.turnSpeed))
    for i, vertex in ipairs(self.vertices) do
        local newX = vertex.x * cos - vertex.y * sin
        local newY = vertex.x * sin + vertex.y * cos
        vertex.x = newX
        vertex.y = newY
    end

    -- Flash
    self.flashAlpha = self.flashAlpha - dt * 8
end

function Asteroid:draw()
    -- lg.circle("line", self.x, self.y, self.radius)

    -- Connect all the vertices
    for i=1, #self.vertices - 1 do
        local point1 = self.vertices[i]
        local point2 = self.vertices[i + 1]
        local x1 = point1.x + self.x
        local y1 = point1.y + self.y
        local x2 = point2.x + self.x
        local y2 = point2.y + self.y
        
        lg.line(x1, y1, x2, y2)
        lg.push("all")
            lg.setColor(255, 255, 255, self.flashAlpha)
            lg.line(x1, y1, x2, y2)
        lg.pop()
    end
    
    -- Close the sillhouete
    local firstPoint = self.vertices[1]
    local lastPoint = self.vertices[#self.vertices]
    local x1 = lastPoint.x + self.x 
    local y1 = lastPoint.y + self.y 
    local x2 = firstPoint.x + self.x 
    local y2 = firstPoint.y + self.y
    lg.line(x1, y1, x2, y2)
    lg.push("all")
        lg.setColor(255, 255, 255, self.flashAlpha)
        lg.line(x1, y1, x2, y2)
    lg.pop()
end

return Asteroid