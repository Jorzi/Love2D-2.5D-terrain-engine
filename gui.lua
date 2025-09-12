local initLuis = require("luis.init")

-- Direct this to your widgets folder.
luis = initLuis("luis/widgets")

-- register flux in luis, some widgets need it for animations
luis.flux = require("luis.3rdparty.flux")

function loadGui()
    local width = 16
    local height = love.graphics.getHeight() / luis.gridSize
    local posX = love.graphics.getWidth() / luis.gridSize - width + 1
    local posY = 1
     local container = luis.newFlexContainer(width, height, posY, posX)

    -- Add some widgets to the container
    local button1 = luis.newButton("Raise/lower", 15, 3, function() editState.activeTool = 'changeHeight_brush' end, function()  end, 5, 2)
    local button2 = luis.newButton("Level terrain", 15, 3, function() editState.activeTool = 'levelHeight_brush' end, function()  end, 5, 2)
    local slider1 = luis.newSlider(-10, 10, 1, 10, 2, function(value)
        editState.toolStrength = math.floor(value)
    end, 10, 2)
    local slider2 = luis.newSlider(1, 20, 5, 8, 2, function(value)
        editState.radius = math.floor(value)
    end, 10, 2)
    local label1 = luis.newLabel("Tool Strength", 5, 2, 0, 10)
    local label2 = luis.newLabel("Tool Radius", 5, 2, 0, 10)
    local button3 = luis.newButton("Corn field", 15, 3, function() editState.activeTool = 'place_soil' end, function()  end, 5, 2)
    local button4 = luis.newButton("Save Game", 15, 3, function() saveGame("test") end, function()  end, 5, 2)
    local button5 = luis.newButton("Load Game", 15, 3, function() loadGame("test") end, function()  end, 5, 2)

    container:addChild(button1)
    container:addChild(button2)
    container:addChild(slider1)
    container:addChild(label1)
    container:addChild(slider2)
    container:addChild(label2)
    container:addChild(button3)
    container:addChild(button4)
    container:addChild(button5)

    luis.newLayer("main")
    luis.setCurrentLayer("main")
    
    -- Add the container to your LUIS layer
    luis.createElement(luis.currentLayer, "FlexContainer", container)

end

function resizeGuiLayout()
    luis.removeLayer("main")
    loadGui()
end