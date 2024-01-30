function love.conf(t)
    local scale = 3

    t.window.title = "snakegame"
    t.window.icon = nil    
    t.window.width = 320 * scale
    t.window.height = 180 * scale
    t.window.resizable = true

	t.console = true
    t.joystick = false
end