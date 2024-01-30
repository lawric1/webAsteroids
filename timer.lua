Timer = {}

function Timer:new() 
    timer = {
        enabled = false, 
        elapsed = 0, 
        interval = 0,
        oneshot = false,
        callback,
        ticks = 0
    }
    
    setmetatable(timer, self)
    self.__index = self
    return timer
end

function Timer:start(interval, oneshot, callback)
    self.interval = interval
    self.oneshot = oneshot
    self.callback = callback or nil
    self.enabled = true
    self.ticks = 0
end

function Timer:stop() 
    self.enabled = false
    self.elapsed = 0
    self.ticks = 0
end

function Timer:tick(dt)
    if self.enabled then 
        self.elapsed = self.elapsed + dt

        if self.elapsed >= self.interval then
            self.elapsed = 0
            self.ticks = self.ticks + 1
            
            if self.callback then 
                self.callback() 
            end
            
            if self.oneshot then 
                self.enabled = false 
            end

            return true            
        end
    end

    return false
end

return Timer