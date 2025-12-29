function love.conf(t)
    t.window.title = "Session_End"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true -- [NEW] Allow the window to be resized/maximized
    t.console = true       -- Attaches a console for debugging info
    t.modules.physics = false -- We don't need complex physics yet
end