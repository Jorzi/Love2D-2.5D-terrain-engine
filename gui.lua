local initLuis = require("luis.init")

-- Direct this to your widgets folder.
luis = initLuis("luis/widgets")

-- register flux in luis, some widgets need it for animations
luis.flux = require("luis.3rdparty.flux")

function loadGui()
    local width = 20
    local height = love.graphics.getHeight() / luis.gridSize
    local posX = love.graphics.getWidth() / luis.gridSize - width
    local posY = 0
     local container = luis.newFlexContainer(width, height, posY, posX)

    -- Add some widgets to the container
    local button1 = luis.newButton("Raise/lower", 15, 3, function() editState.activeTool = 'changeHeight_brush' end, function()  end, 5, 2)
    local button2 = luis.newButton("Level terrain", 15, 3, function() editState.activeTool = 'levelHeight_brush' end, function()  end, 5, 2)
    local slider = luis.newSlider(-10, 10, 1, 10, 2, function(value)
        editState.toolStrength = value
    end, 10, 2)

    container:addChild(button1)
    container:addChild(button2)
    container:addChild(slider)

    luis.newLayer("main")
    luis.setCurrentLayer("main")
    
    -- Add the container to your LUIS layer
    luis.createElement(luis.currentLayer, "FlexContainer", container)

end

function resizeGuiLayout()
    luis.removeLayer("main")
    loadGui()
end