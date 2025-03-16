
-- gg.antiv2 better leaked by flanch

-- change this linoria ui 
    repo = 'https://raw.githubusercontent.com/HexploitUI/Hexploit/refs/heads/main/'
    

    Library = loadstring(game:HttpGet(repo .. 'UIlib.lua'))()
    ThemeManager = loadstring(game:HttpGet(repo .. 'UIthememanager.lua'))()
    SaveManager = loadstring(game:HttpGet(repo .. 'UIsavemanager.lua'))()

    Window = Library:CreateWindow({
    -- Set Center to true if you want the menu to appear in the center
    -- Set AutoShow to true if you want the menu to appear when it is created
    -- Position and Size are also valid options here
    -- but you do not need to define them unless you are changing them :)

    Title = 'Hexploit V2 by Affeboy',
    Center = true,
    AutoShow = true,
    TabPadding = 9
    })

    -- CALLBACK NOTE:
    -- Passing in callback functions via the initial element parameters (i.e. Callback = function(Value)...) works
    -- HOWEVER, using Toggles/Options.INDEX:OnChanged(function(Value) ... ) is the RECOMMENDED way to do this.
    -- I strongly recommend decoupling UI code from logic code. i.e. Create your UI elements FIRST, and THEN setup :OnChanged functions later.

    -- You do not have to set your tabs & groups up this way, just a prefrence.

    Tabs = {
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'),
    Movement = Window:AddTab('Movement'),
    Misc = Window:AddTab('Misc'),
    Teleport = Window:AddTab('Teleport'),
    D = Window:AddTab('D'),
    ['UI Settings'] = Window:AddTab('UI Settings'),  -- This is fine with proper syntax
    }

LeftGroupBox = Tabs.Main:AddLeftGroupbox('Aimlock')


    -- Services and Variables
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Camera = workspace.CurrentCamera
    local Workspace = game:GetService("Workspace")
    
    local LocalPlayer = Players.LocalPlayer
    
    local cursorLocked = false
    local targetHead = nil
    local targetPlayer = nil
    local previewHighlight = nil
    local lockedHighlight = nil
    local predictionLevel = 0 -- Default prediction level, can be changed (higher value = more prediction)
    local currentKeybind = Enum.KeyCode.C
    local previewColor = Color3.fromRGB(0, 0, 255) -- Default preview color
    local lockedHighlightColor = Color3.fromRGB(255, 0, 0) -- Default locked highlight color
    local smoothness = 0 -- Default smoothness value
    local highlightsEnabled = false -- Default value for highlights toggle
    
    local ragelock = false  -- Default value for ragelock
    local orbitActive = false  -- Flag for orbit feature
    local orbitSpeed = 10 -- Orbit speed
    local radius = 8 -- Orbit size
    local rotation = CFrame.Angles(0, 0, 0) -- Rotation angles
    
    -- Ensure aimlock state is toggled correctly on each execution
    if _G.aimlock == nil then
        _G.aimlock = false  -- Default value if not previously set
    end
    
    -- Function to check if the player is knocked or grabbed
    local function IsPlayerKnockedOrGrabbed(player)
        local character = player.Character
        if character then
            local bodyEffects = character:FindFirstChild("BodyEffects")
            local grabbingConstraint = character:FindFirstChild("GRABBING_CONSTRAINT")
            if bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value or grabbingConstraint then
                return true
            end
        end
        return false
    end
    
    -- Function to calculate the predicted position based on velocity
    local function GetPredictedPosition(player)
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            local head = character:FindFirstChild("Head")
            if humanoid and head then
                local velocity = humanoid.RootPart.AssemblyLinearVelocity
                return head.Position + velocity * predictionLevel
            end
        end
        return nil
    end
    
    -- Function to find the closest player's head, with prediction
    local function FindClosestPlayerHead()
        local closestPlayer = nil
        local closestDistance = math.huge
        local mousePosition = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                local character = player.Character
                local humanoid = character:FindFirstChild("Humanoid")
    
                if humanoid and humanoid.Health > 0 then
                    if IsPlayerKnockedOrGrabbed(player) then continue end  -- Skip locked/knocked/grabbed players
                    local head = character.Head
                    local predictedHeadPosition = GetPredictedPosition(player) or head.Position
                    local screenPoint = Camera:WorldToScreenPoint(predictedHeadPosition)
                    local distance = (mousePosition - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
                    local playerDistance = (Camera.CFrame.Position - predictedHeadPosition).Magnitude
    
                    local ray = Ray.new(Camera.CFrame.Position, predictedHeadPosition - Camera.CFrame.Position)
                    local hitPart, hitPosition = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
    
                    -- Lock even through walls for players within 100 studs
                    if playerDistance <= 100 or (not hitPart or hitPart.Parent == character) then
                        if distance < closestDistance then
                            closestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    
        if closestPlayer then
            return closestPlayer.Character.Head, closestPlayer
        end
        return nil, nil
    end
    
    -- Function to add a preview highlight for the closest player
    local function AddPreviewHighlight(player)
        if not highlightsEnabled then return end -- Skip if highlights are disabled
    
        -- If preview highlight already exists for this player, return early
        if previewHighlight and previewHighlight.Parent == player.Character then
            previewHighlight.FillColor = previewColor
            return
        end
    
        -- Destroy previous preview highlight if it exists
        if previewHighlight then
            previewHighlight:Destroy()
        end
    
        -- Create a new preview highlight for the closest player
        if player and player.Character then
            previewHighlight = Instance.new("Highlight")
            previewHighlight.Parent = player.Character
            previewHighlight.FillTransparency = 0.5
            previewHighlight.FillColor = previewColor
        end
    end
    
    -- Function to add a red highlight to the locked player
    local function AddLockedHighlight(player)
        if not highlightsEnabled then return end -- Skip if highlights are disabled
    
        -- If locked highlight already exists for this player, return early
        if lockedHighlight and lockedHighlight.Parent == player.Character then
            lockedHighlight.FillColor = lockedHighlightColor
            return
        end
    
        -- Destroy previous locked highlight if it exists
        if lockedHighlight then
            lockedHighlight:Destroy()
        end
    
        -- Create a new locked highlight for the locked player
        if player and player.Character then
            lockedHighlight = Instance.new("Highlight")
            lockedHighlight.Parent = player.Character
            lockedHighlight.FillTransparency = 0.5
            lockedHighlight.FillColor = lockedHighlightColor
        end
    end
    
    -- Lock the cursor to the nearest player's head
    local function LockCursorToHead()
        targetHead, targetPlayer = FindClosestPlayerHead()
        if targetHead then
            AddLockedHighlight(targetPlayer)  -- Add highlight to locked player
            if previewHighlight then previewHighlight:Destroy() end  -- Destroy preview highlight if it exists
            UserInputService.MouseIconEnabled = false
        end
    end
    
    -- Unlock the cursor
    local function UnlockCursor()
        UserInputService.MouseIconEnabled = true
        targetHead = nil
        targetPlayer = nil
        if lockedHighlight then lockedHighlight:Destroy() end
    end
    
    -- Function to activate orbiting around the target player
    local function ActivateOrbit(player)
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            targetPlayer = player
        end
    end
    
    -- Function to deactivate orbiting
    local function DeactivateOrbit()
        targetPlayer = nil
    end
    
    -- Function to handle automatic targeting for RageLock
    local function HandleRageLock()
        -- Ensure RageLock only locks onto the target if it's valid
        if ragelock then
            -- Check if targetPlayer is invalid or knocked
            if targetPlayer and IsPlayerKnockedOrGrabbed(targetPlayer) then
                -- If the locked target is knocked or grabbed, unlock and search for the next target
                cursorLocked = false
                UnlockCursor()
                DeactivateOrbit()
                print("[RageLock] Target is knocked/grabbed, unlocking and searching for next target.")
                targetHead, targetPlayer = FindClosestPlayerHead()
                if targetPlayer then
                    cursorLocked = true
                    LockCursorToHead()
                    AddLockedHighlight(targetPlayer)  -- Add highlight to new target
                end
                return
            end
    
            -- If no valid target is locked, search for a new one
            if not targetPlayer then
                targetHead, targetPlayer = FindClosestPlayerHead()
                if targetPlayer then
                    cursorLocked = true
                    LockCursorToHead()
                    AddLockedHighlight(targetPlayer)  -- Add highlight to new target
                end
            end
        end
    end
    
    -- Orbit update loop (only runs when orbit toggle is true)
    RunService.Stepped:Connect(function(_, dt)
        if orbitActive then
            -- Only update orbit if the toggle is true and the player is locked onto a valid target
            if cursorLocked and targetPlayer then
                -- Only update orbit if the target is locked (Aimlock or RageLock)
                local targetHumanoidRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHumanoidRootPart then
                    local rot = tick() * orbitSpeed
                    local lpr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if lpr then
                        -- Orbit calculation (only orbits if locked onto target)
                        lpr.CFrame = CFrame.new(
                            targetHumanoidRootPart.Position + Vector3.new(math.sin(rot) * radius, 0, math.cos(rot) * radius)
                        )
                    end
                end
            end
        end
    
        -- Update loop to continuously follow the locked target for aimlock
        if cursorLocked and _G.aimlock and targetHead then
            -- Handle ragelock to auto lock onto next target if necessary
            if ragelock then
                HandleRageLock()  -- Call the function to handle RageLock auto-targeting
            end
    
            -- Check if the locked player is knocked or grabbed and unlock if necessary
            if IsPlayerKnockedOrGrabbed(targetPlayer) then
                cursorLocked = false
                UnlockCursor()
                DeactivateOrbit()
                print("[Auto Unlock] Target player is knocked or grabbed, unlocking cursor.")
            else
                        -- Proceed with the normal aimlock and orbit
        local predictedHeadPosition = GetPredictedPosition(targetPlayer) or targetHead.Position
        -- Smoothly interpolate the camera's CFrame
        local alpha = 1 - smoothness
        alpha = math.max(alpha, 0.01)  -- Ensure alpha is never 0
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedHeadPosition), alpha)
            end
        elseif not cursorLocked and _G.aimlock then
            local closestHead, closestPlayer = FindClosestPlayerHead()
            if closestPlayer ~= targetPlayer then
                AddPreviewHighlight(closestPlayer)
            end
        end
    end)
    
    -- Handle key press (C) for locking the cursor
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKeybind then
            if _G.aimlock then
                cursorLocked = not cursorLocked
                if cursorLocked then
                    LockCursorToHead()
                    if orbitActive then
                        ActivateOrbit(targetPlayer)  -- Activate orbit when locking onto a player and orbiting is enabled
                    end
                else
                    UnlockCursor()
                    DeactivateOrbit()  -- Deactivate orbit when unlocking
                end
            end
        end
    end)
    
    -- UI Controls for setting various values like keybinds and highlight colors
    LeftGroupBox:AddToggle('Aimlock', {
        Text = 'Aimlock',
        Default = false,
        Tooltip = 'Locks your aim onto players heads',
        Callback = function(Value)
            _G.aimlock = Value
            print('[cb] Aimlock changed to:', Value)
            if _G.aimlock then
                cursorLocked = false  -- Ensure cursor is not locked when aimlock is turned on
            end
        end
    })
    
    LeftGroupBox:AddToggle('RageLock', {
        Text = 'RageLock',
        Default = false,
        Tooltip = 'Automatically locks onto the next available player',
        Callback = function(Value)
            ragelock = Value
            print('[cb] RageLock changed to:', Value)
        end
    })
    
    LeftGroupBox:AddToggle('OrbitFeature', {
        Text = 'Orbit Around Target',
        Default = false,
        Tooltip = 'Toggle to start orbiting around the player you lock onto.',
        Callback = function(value)
            orbitActive = value  -- Directly set orbitActive based on toggle state
            if orbitActive and cursorLocked then
                ActivateOrbit(targetPlayer) -- Activate orbit only if locked onto a player
            else
                DeactivateOrbit()  -- Deactivate orbit when the toggle is off
            end
        end
    })
    
    -- Add Toggle for Highlights
    LeftGroupBox:AddToggle('HighlightsToggle', {
        Text = 'Highlights',
        Default = highlightsEnabled,
        Tooltip = 'Toggle to enable or disable highlights',
        Callback = function(Value)
            highlightsEnabled = Value
            print('[cb] Highlights toggled:', Value)
            if not Value then
                -- Destroy highlights if they exist
                if previewHighlight then
                    previewHighlight:Destroy()
                    previewHighlight = nil
                end
                if lockedHighlight then
                    lockedHighlight:Destroy()
                    lockedHighlight = nil
                end
            end
        end
    })
    
    LeftGroupBox:AddLabel('Keybind'):AddKeyPicker('KeyPicker', {
        Default = 'C',
        SyncToggleState = false,
        Mode = 'Toggle',
        Text = 'Aimlock',
        ChangedCallback = function(New)
            print('[cb] Keybind changed!', New)
            currentKeybind = New
        end
    })
    
    LeftGroupBox:AddLabel('Preview Color'):AddColorPicker('PreviewColorPicker', {
        Default = previewColor,
        Title = 'Preview Color',
        Transparency = 0,
        Callback = function(Value)
            print('[cb] Preview Color changed!', Value)
            previewColor = Value
            if previewHighlight then
                previewHighlight.FillColor = Value
            end
        end
    })
    
    LeftGroupBox:AddLabel('Locked Highlight Color'):AddColorPicker('LockedColorPicker', {
        Default = lockedHighlightColor,
        Title = 'Locked Player Highlight Color',
        Transparency = 0,
        Callback = function(Value)
            print('[cb] Locked Highlight Color changed!', Value)
            lockedHighlightColor = Value
            if lockedHighlight then
                lockedHighlight.FillColor = Value
            end
        end
    })
    
    -- Add Smoothness Slider
    LeftGroupBox:AddSlider('SmoothnessSlider', {
        Text = 'Smoothness',
        Default = smoothness,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(Value)
            print('[cb] Smoothness changed!', Value)
            smoothness = Value
        end
    })
    
    LeftGroupBox:AddSlider('Orbit Speed', {
        Text = 'Orbit Speed',
        Default = orbitSpeed,
        Min = 0,
        Max = 100,
        Rounding = 1,
        Callback = function(Value)
            print('[cb] Orbit Speed changed!', Value)
            orbitSpeed = Value
        end
    })
    
    LeftGroupBox:AddSlider('PredictionSlider', {
        Text = 'Prediction',
        Default = predictionLevel,
        Min = 0,
        Max = 1,
        Rounding = 1,
        Callback = function(Value)
            print('[cb] Prediction changed!', Value)
            predictionLevel = Value
        end
    })

LeftGroupBox = Tabs.Main:AddLeftGroupbox('Triggerbot')

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
local mouse = lp:GetMouse()

local EnumKeyCode = Enum.KeyCode -- Store Enum values for reuse
local EnumUserInputType = Enum.UserInputType

local Script = {
    Functions = {},
    Table = {
        Start = {
            TriggerBot = {
                Keybind = "Z", -- Default keybind, can be changed via UI
                Delay = 0.1, -- Default delay, can be changed via UI
                Blacklisted = {} -- Add blacklisted tool names here
            }
        }
    },
    Connections = {}
}

-- Use Object Pooling for frequently accessed properties like BodyEffects
Script.Functions.isDead = function(player)
    local character = player.Character
    if not character then return false end

    local bodyEffects = character:FindFirstChild("BodyEffects")
    if not bodyEffects then return false end

    local ko = bodyEffects:FindFirstChild("K.O") or bodyEffects:FindFirstChild("KO")
    return ko and ko.Value or false
end

Script.Functions.getTarget = function(instance)
    if not instance then return false end

    for _, player in next, Players:GetPlayers() do
        if player.Character and (instance == player.Character or instance:IsDescendantOf(player.Character)) then
            if not Script.Functions.isDead(player) then
                return player
            end
        end
    end

    return false
end

Script.Functions.isToolBlacklisted = function(tool)
    for _, toolName in ipairs(Script.Table.Start.TriggerBot.Blacklisted) do
        if tool.Name == toolName then
            return true
        end
    end
    return false
end

-- Flag to toggle triggerbot state
local JAIROUGH = false
local hotkeyEnabled = false -- Flag to control if the hotkey is enabled or not

-- Update delay when slider is changed
Script.Functions.updateDelay = function(Value)
    Script.Table.Start.TriggerBot.Delay = Value
end

-- Toggle triggerbot state on keypress, but only if hotkey is enabled
Script.Functions.onKeyPress = function(input, gameProcessed)
    if gameProcessed then return end

    -- Only allow the hotkey to toggle triggerbot if the hotkey is enabled
    if hotkeyEnabled and input.UserInputType == EnumUserInputType.Keyboard and input.KeyCode == EnumKeyCode[Script.Table.Start.TriggerBot.Keybind] then
        JAIROUGH = not JAIROUGH
    end
end

-- Keybind handler to change keybind via UI
Script.Functions.updateKeybind = function(NewKey)
    Script.Table.Start.TriggerBot.Keybind = NewKey.Name
    print('[cb] Keybind changed!', NewKey.Name)
end

UserInputService.InputBegan:Connect(Script.Functions.onKeyPress)

-- TriggerBot activation logic
Script.Functions.triggerBot = function()
    local con
    con = RunService.Heartbeat:Connect(function()
        if JAIROUGH then
            local target = mouse.Target
            if target and Script.Functions.getTarget(target) then
                if lp.Character then
                    local tool = lp.Character:FindFirstChildWhichIsA('Tool')
                    if tool and not Script.Functions.isToolBlacklisted(tool) then
                        task.wait(Script.Table.Start.TriggerBot.Delay)
                        tool:Activate()
                    end
                end
            end
        end
    end)

    Script.Connections.triggerBot = con
end

Script.Functions.triggerBot()

-- Disable function to disconnect triggerbot and cleanup
getgenv().disable = function()
    getgenv().disable = nil
    if Script.Connections.triggerBot then
        Script.Connections.triggerBot:Disconnect()
    end
end

-- UI Integration
LeftGroupBox:AddToggle('MyToggle', {
    Text = 'Enable Hotkey',
    Default = false, -- Default value (true / false)
    Tooltip = 'Enable or Disable the hotkey for TriggerBot', -- Information shown when you hover over the toggle
    Callback = function(Value)
        -- Enable or disable hotkey based on toggle state
        hotkeyEnabled = Value
        
        -- If hotkey is disabled, immediately disable the TriggerBot as well
        if not hotkeyEnabled then
            JAIROUGH = false
        end
    end
})

LeftGroupBox:AddLabel('Keybind'):AddKeyPicker('KeyPicker', {
    Default = Script.Table.Start.TriggerBot.Keybind, -- Default keybind value
    SyncToggleState = false, -- Keybind is independent of toggle state
    Mode = 'Toggle', -- Modes: Always, Toggle, Hold
    Text = 'Triggerbot Keybind', -- Text to display in the keybind menu
    NoUI = false, -- Set to true if you want to hide from the Keybind menu,
    ChangedCallback = function(New)
        Script.Functions.updateKeybind(New)
    end
})

LeftGroupBox:AddSlider('MySlider', {
    Text = 'Delay Slider',
    Default = Script.Table.Start.TriggerBot.Delay, -- Default delay value
    Min = 0,
    Max = 1,
    Rounding = 3,
    Compact = false,
    Callback = function(Value)
        Script.Functions.updateDelay(Value)
    end
})

    RightGroupBox = Tabs.Main:AddRightGroupbox('Rapid Fire v1')

    RightGroupBox:AddToggle('MyToggle', {
        Text = 'Rapid Fire v1',
        Default = false, -- Default value (true / false)
        Tooltip = 'Rapid Fire v1 is better for some', -- Information shown when you hover over the toggle
    
        Callback = function(Value)
        -- Ensure script state is toggled correctly on each execution
        if _G.RapidFirev1 == nil then
        _G.RapidFirev1 = false  -- Default value if not previously set
        end
    
        -- If the script is already active, turn it off; if it's inactive, turn it on
        _G.RapidFirev1 = not _G.RapidFirev1
    
        if _G.RapidFirev1 then
        local player = game.Players.LocalPlayer
        local userInputService = game:GetService("UserInputService")
        local isActive = false  -- Tracks whether the gun activation is enabled or not
    
        -- Function to continuously activate the held item (gun)
        local function continuouslyActivateHeldItem()
            while _G.RapidFirev1 do  -- Stop the loop if the script is unloaded
                if isActive then
                    -- Ensure the player is holding a tool (gun)
                    local character = player.Character or player.CharacterAdded:Wait()
                    local gunTool = character:FindFirstChildOfClass("Tool")
    
                    if gunTool then
                        gunTool:Activate()  -- Only activate if a tool is already equipped
                    end
                end
                wait(0.01)  -- Shorter delay for faster activation
            end
        end
    
        -- Function to detect when the left mouse button is pressed or held
        local function onMouseClick(input, gameProcessedEvent)
            if gameProcessedEvent then return end
    
            -- Check for left mouse button (MouseButton1)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isActive = true
            end
        end
    
        -- Function to detect when the left mouse button is released
        local function onMouseRelease(input, gameProcessedEvent)
            if gameProcessedEvent then return end
    
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isActive = false
            end
        end
    
        -- Connect the mouse click and release functions and start the continuous loop
        _G.mouseClickConnection = userInputService.InputBegan:Connect(onMouseClick)
        _G.mouseReleaseConnection = userInputService.InputEnded:Connect(onMouseRelease)
        spawn(continuouslyActivateHeldItem)
        else
        if _G.mouseClickConnection then
            _G.mouseClickConnection:Disconnect()  -- Disconnect the mouse click listener
            _G.mouseClickConnection = nil
        end
        if _G.mouseReleaseConnection then
            _G.mouseReleaseConnection:Disconnect()  -- Disconnect the mouse release listener
            _G.mouseReleaseConnection = nil
        end
        end
        end
    })    

    RightGroupBox = Tabs.Main:AddRightGroupbox('Rapid Fire v2')

    RightGroupBox:AddToggle('MyToggle', {
        Text = 'Rapid Fire v2',
        Default = false, -- Default value (true / false)
        Tooltip = 'Rapid Fire v2 is better for some', -- Information shown when you hover over the toggle
    
        Callback = function(Value)
    
            -- Ensure script state is toggled correctly on each execution
            if _G.gunActivation == nil then
                _G.gunActivation = false  -- Default value if not previously set
            end
    
            -- Toggle script state
            _G.gunActivation = not _G.gunActivation
    
            -- Store frequently used Enum values in variables
            local UserInputType = Enum.UserInputType
            local MouseButton1 = UserInputType.MouseButton1
    
            if _G.gunActivation then
                local player = game.Players.LocalPlayer
                local userInputService = game:GetService("UserInputService")
                local runService = game:GetService("RunService")
                local isActive = false  -- Tracks whether the gun activation is enabled or not
    
                -- Function to continuously activate the held item (gun) at the fastest rate possible
                local function continuouslyActivateHeldItem()
                    while _G.gunActivation and runService.Heartbeat:Wait() do
                        if isActive then
                            local character = player.Character
                            if character then
                                local gunTool = character:FindFirstChildOfClass("Tool")
                                if gunTool then
                                    gunTool:Activate()
                                end
                            end
                        end
                    end
                end
    
                -- Function to detect when the left mouse button is pressed or held
                local function onMouseClick(input, gameProcessedEvent)
                    if gameProcessedEvent then return end
    
                    -- Check for left mouse button (MouseButton1)
                    if input.UserInputType == MouseButton1 then
                        isActive = true
                    end
                end
    
                -- Function to detect when the left mouse button is released
                local function onMouseRelease(input, gameProcessedEvent)
                    if gameProcessedEvent then return end
    
                    if input.UserInputType == MouseButton1 then
                        isActive = false
                    end
                end
    
                -- Connect the mouse click and release functions and start the continuous loop
                _G.mouseClickConnection = userInputService.InputBegan:Connect(onMouseClick)
                _G.mouseReleaseConnection = userInputService.InputEnded:Connect(onMouseRelease)
                spawn(continuouslyActivateHeldItem)
            else
                if _G.mouseClickConnection then
                    _G.mouseClickConnection:Disconnect()
                    _G.mouseClickConnection = nil
                end
                if _G.mouseReleaseConnection then
                    _G.mouseReleaseConnection:Disconnect()
                    _G.mouseReleaseConnection = nil
                end
            end
        end
    })    

    RightGroupBox = Tabs.Main:AddRightGroupbox('Hitbox Expander')

    repeat wait() until game:IsLoaded()

-- Cache services and constants
Players = game:GetService('Players')
RunService = game:GetService('RunService')
EnumMaterial = Enum.Material.Neon  -- Enum value for Material

-- Initialize global state
_G.ToggleState = _G.ToggleState or false -- Default state
_G.HITBOX_SIZE = Vector3.new(16, 16, 16)  -- Default hitbox size
_G.HitboxColor = Color3.fromRGB(0, 0, 0)  -- Default hitbox color Black
_G.HitboxTransparency = 0.8  -- Default transparency
_G.OutlineColor = Color3.fromRGB(108, 59, 170) -- Default outline color Royal Purple
_G.OutlineTransparency = 0  -- Default outline transparency
_G.Disabled = not _G.ToggleState

-- UI setup (skip UI references here)
RightGroupBox:AddToggle('MyToggle', {
    Text = 'Hitbox Expander',
    Default = false,
    Tooltip = 'Increases size of player Hitboxes for easier targeting',
    Callback = function(Value)
        _G.ToggleState = Value
        _G.Disabled = not Value
    end
})

-- Color Pickers and Sliders for customization
RightGroupBox:AddLabel('Outline Color'):AddColorPicker('OutlineColorPicker', {
    Default = Color3.new(0.4235, 0.2314, 0.6667), -- Royal Purple
    Title = 'Outline Color',
    Callback = function(Value) _G.OutlineColor = Value end
})

RightGroupBox:AddLabel('Hitbox Color'):AddColorPicker('HitboxColorPicker', {
    Default = Color3.new(0, 0, 0), -- Default Black
    Title = 'Hitbox Color',
    Callback = function(Value) _G.HitboxColor = Value end
})

RightGroupBox:AddSlider('HitboxSizeSlider', {
    Text = 'Size of the hitbox',
    Default = 16,
    Min = 5,
    Max = 37.5,
    Rounding = 1,
    Callback = function(Value) _G.HITBOX_SIZE = Vector3.new(Value, Value, Value) end
})

RightGroupBox:AddSlider('TransparencySlider', {
    Text = 'Transparency of the hitbox',
    Default = _G.HitboxTransparency,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(Value) _G.HitboxTransparency = Value end
})

RightGroupBox:AddSlider('OutlineTransparencySlider', {
    Text = 'Transparency of the outline',
    Default = _G.OutlineTransparency,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(Value) _G.OutlineTransparency = Value end
})

-- Object pooling for outlines
outlinePool = {}

-- Function to get the outline or create it
getOutline = function(part)
    local outline = part:FindFirstChild("Outline")
    if not outline then
        outline = #outlinePool > 0 and table.remove(outlinePool) or Instance.new("SelectionBox")
        outline.LineThickness = 0.05
        outline.Color3 = _G.OutlineColor
        outline.Name = "Outline"
    end
    outline.Adornee = part
    outline.Parent = part
    outline.Transparency = _G.OutlineTransparency
    return outline
end

-- Function to release the outline
releaseOutline = function(outline)
    outline.Adornee = nil
    outline.Parent = nil
    table.insert(outlinePool, outline)
end

-- Throttle updates
local lastUpdate = tick()

-- Function to batch and optimize updates
updateHitboxes = function()
    local now = tick()
    if now - lastUpdate < 0.2 then -- Update every 0.2 seconds (5 times per second)
        return
    end
    lastUpdate = now

    -- Loop through players and update hitboxes
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local character = player.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local bodyEffects = character:FindFirstChild("BodyEffects")
                    local isKOd = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
                    local isGrabbed = character:FindFirstChild("GRABBING_CONSTRAINT") ~= nil

                    -- Only modify the hitbox if not KO'd or grabbed
                    if isKOd or isGrabbed then
                        if humanoidRootPart.Size ~= Vector3.new(0, 0, 0) then
                            humanoidRootPart.Size = Vector3.new(0, 0, 0)
                            humanoidRootPart.Transparency = 1
                            local outline = humanoidRootPart:FindFirstChild("Outline")
                            if outline then releaseOutline(outline) end
                        end
                    else
                        -- Update size, color, transparency, and outline dynamically
                        if humanoidRootPart.Size ~= _G.HITBOX_SIZE then
                            humanoidRootPart.Size = _G.HITBOX_SIZE
                            humanoidRootPart.Transparency = _G.HitboxTransparency
                            humanoidRootPart.BrickColor = BrickColor.new(_G.HitboxColor)
                            humanoidRootPart.Material = EnumMaterial
                            humanoidRootPart.CanCollide = false
                            getOutline(humanoidRootPart)
                        else
                            -- Dynamically update color and transparency based on the UI changes
                            humanoidRootPart.BrickColor = BrickColor.new(_G.HitboxColor)
                            humanoidRootPart.Transparency = _G.HitboxTransparency
                        end
                        
                        -- Update outline color and transparency dynamically based on the selected Outline settings
                        local outline = humanoidRootPart:FindFirstChild("Outline")
                        if outline then
                            outline.Color3 = _G.OutlineColor
                            outline.Transparency = _G.OutlineTransparency
                        end
                    end
                end
            end
        end
    end
end

-- Use Heartbeat for smoother updates
RunService.Heartbeat:Connect(function()
    if not _G.Disabled then
        updateHitboxes()
    else
        -- Reset the hitboxes if disabled
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                local character = player.Character
                if character then
                    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        humanoidRootPart.Size = Vector3.new(2, 2, 1)
                        humanoidRootPart.Transparency = 1
                        local outline = humanoidRootPart:FindFirstChild("Outline")
                        if outline then releaseOutline(outline) end
                    end
                end
            end
        end
    end
end)

LeftGroupBox = Tabs.Visuals:AddLeftGroupbox('Cham Esp')

-- The actual cham effect
Players = game:GetService("Players")
RunService = game:GetService("RunService")
LocalPlayer = Players.LocalPlayer
highlightColor = Color3.fromRGB(255, 255, 255)  -- Default color for chams

-- Function to create a cham (highlight) effect for a player
function CreateCham(player)
    local character = player.Character or player.CharacterAdded:Wait()
    if not character:FindFirstChild("HumanoidRootPart") then return end

    -- Create the highlight object for the player's character
    local highlight = Instance.new("Highlight")
    highlight.Name = "ChamHighlight"
    highlight.Parent = character
    highlight.Adornee = character  -- Set the highlight target to the entire character
    highlight.FillColor = highlightColor  -- Set color to chosen value
    highlight.FillTransparency = 0.5  -- Make the highlight semi-transparent
    highlight.OutlineTransparency = 1  -- Fully transparent outline (no outline)

    -- Clean up when the character is removed
    character:WaitForChild("HumanoidRootPart").AncestryChanged:Connect(function()
        highlight:Destroy()  -- Remove the highlight when the player leaves or the character is destroyed
    end)
end

-- UI Toggle for Chams
LeftGroupBox:AddToggle('ChamsToggle', {
    Text = 'Chams',
    Default = false, -- Default value (true / false)
    Tooltip = 'Toggles cham effect for players',

    Callback = function(Value)
        _G.chams = Value
        -- Apply or remove the cham effect based on the toggle state
        if _G.chams then
            -- Apply cham effect for players when enabled
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    CreateCham(player)
                end
            end
        else
            -- Remove cham effect for players when disabled
            for _, player in pairs(Players:GetPlayers()) do
                local character = player.Character
                if character then
                    local highlight = character:FindFirstChild("ChamHighlight")
                    if highlight then
                        highlight:Destroy()
                    end
                end
            end
        end
    end
})

-- Add color picker UI for Chams
LeftGroupBox:AddLabel('Color'):AddColorPicker('ColorPicker', {
    Default = Color3.fromRGB(255, 255, 255), -- White color (default)
    Title = 'Cham Color', -- Title of the color picker
    Transparency = 0, -- Disables transparency changing for this color picker

    Callback = function(Value)
        highlightColor = Value  -- Update the highlight color when the user picks a color
        -- Update the cham color for existing players
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = player.Character:FindFirstChild("ChamHighlight")
                if highlight then
                    highlight.FillColor = highlightColor  -- Apply the new color to the existing highlight
                end
            end
        end
    end
})

-- Handle player join to ensure chams are applied
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        -- Wait until the character's root part is available before applying chams
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        if _G.chams and player ~= LocalPlayer then
            CreateCham(player)  -- Apply cham if enabled and not the local player
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    -- Remove cham when player leaves
    if player.Character then
        local highlight = player.Character:FindFirstChild("ChamHighlight")
        if highlight then
            highlight:Destroy()
        end
    end
end)

-- Periodically update chams for players when enabled using RunService.Heartbeat
RunService.Heartbeat:Connect(function()
    if _G.chams then
        -- Loop through all players and ensure chams are applied
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                -- Create cham if it doesn't exist for the player
                local character = player.Character
                if not character:FindFirstChild("ChamHighlight") then
                    CreateCham(player)
                end
            end
        end
    else
        -- Disable the cham effect if _G.chams is false
        for _, player in pairs(Players:GetPlayers()) do
            local character = player.Character
            if character then
                local highlight = character:FindFirstChild("ChamHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end)

-- Ensure chams are applied to players who have respawned
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        -- In case a player respawns
        if _G.chams and player ~= LocalPlayer then
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            CreateCham(player)
        end
    end)
end)

-- Execute the toggle when the script is first run
if _G.chams then
    -- Enable the cham effect for players (not including local player)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CreateCham(player)
        end
    end
else
    -- Disable the cham effect for all players
    for _, player in pairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local highlight = character:FindFirstChild("ChamHighlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end
end

LeftGroupBox = Tabs.Visuals:AddLeftGroupbox('Name Esp')

Players = game:GetService("Players")
RunService = game:GetService("RunService")
Debris = game:GetService("Debris")  -- For cleanup
LocalPlayer = Players.LocalPlayer

displayOption = 'Username'  -- Default display option
nameTagESPEnabled = false  -- Default for the name tag ESP toggle

-- Function to create a name tag for a player
function CreateNameTag(player)
    -- Skip the local player
    if player == LocalPlayer then return end

    local character = player.Character or player.CharacterAdded:Wait()
    local head = character:WaitForChild("Head")

    -- Create BillboardGui and TextLabel for the name tag
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Parent = character
    billboardGui.Size = UDim2.new(0, 100, 0, 30)  -- Adjust the size for the name tag
    billboardGui.AlwaysOnTop = true
    billboardGui.Adornee = head
    billboardGui.StudsOffset = Vector3.new(0, 6, 0)  -- Adjust position

    local nameTag = Instance.new("TextLabel")
    nameTag.Parent = billboardGui
    nameTag.Size = UDim2.new(1, 0, 1, 0)  -- Full size of the BillboardGui
    nameTag.BackgroundTransparency = 1
    nameTag.TextColor3 = Color3.new(1, 1, 1)  -- White text color
    nameTag.TextStrokeTransparency = 0.6  -- Adjust outline visibility
    nameTag.TextStrokeColor3 = Color3.new(0, 0, 0)  -- Black stroke for visibility
    nameTag.TextSize = 10  -- Smaller base text size

    -- Set the name text based on the selected option
    if displayOption == "Username" then
        nameTag.Text = player.Name  -- Display the player's username
    else
        nameTag.Text = player.DisplayName  -- Display the player's display name
    end

    -- Cleanup when the player leaves
    Debris:AddItem(billboardGui, 5)  -- Automatically cleanup after 5 seconds
end

-- Function to remove name tags
function RemoveNameTags()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local character = player.Character
            local billboardGui = character:FindFirstChildOfClass("BillboardGui")
            if billboardGui then
                -- Cleanup with Debris service
                Debris:AddItem(billboardGui, 0)
            end
        end
    end
end

-- Add the toggle to enable or disable the Name Tag ESP
LeftGroupBox:AddToggle('MyToggle', {
    Text = 'Enable Name Tag ESP',
    Default = false,  -- Default value (true / false)
    Tooltip = 'Toggles the name tag ESP visibility.',
    Callback = function(Value)
        nameTagESPEnabled = Value
        if nameTagESPEnabled then
            -- Update name tags immediately if ESP is enabled
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    CreateNameTag(player)
                end
            end
        else
            -- If ESP is disabled, remove all name tags
            RemoveNameTags()
        end
    end
})

-- Add the dropdown for selecting between Username or DisplayName
LeftGroupBox:AddDropdown('NameDisplayOption', {
    Values = { 'DisplayName', 'Username' },
    Default = 1,  -- Default to "Username"
    Multi = false, -- Single selection only
    Text = 'Name Display Option',
    Tooltip = 'Choose whether to display the player\'s Username or DisplayName',
    Callback = function(Value)
        displayOption = Value  -- Update the display option based on dropdown selection
        if nameTagESPEnabled then
            -- Reapply name tags immediately when the dropdown value changes
            RemoveNameTags()  -- Remove existing name tags
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    CreateNameTag(player)
                end
            end
        end
    end
})

-- Periodically update name tags every heartbeat (for new players)
RunService.Heartbeat:Connect(function()
    if nameTagESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and not player.Character:FindFirstChildOfClass("BillboardGui") then
                CreateNameTag(player)
            end
        end
    end
end)

LeftGroupBox = Tabs.Visuals:AddLeftGroupbox('Tracers')

-- Optimized Tracer Script with Toggling, Mouse Follow, and Object Pooling

-- Services
Players = game:GetService("Players")
RunService = game:GetService("RunService")
Debris = game:GetService("Debris")

player = Players.LocalPlayer
camera = workspace.CurrentCamera
mouse = player:GetMouse()

-- Settings for Tracers
Settings = {
    Tracer_Color = Color3.fromRGB(255, 255, 255),
    Tracer_Thickness = 1,
    Tracer_Origin = "Bottom",
    Tracer_FollowMouse = false
}

-- Global toggle variables
_G.TracersEnabled = false
_G.TracersFollowMouse = false

-- Tracer pool to reuse tracers
tracerPool = {}

-- Function to get or create a new tracer line
function GetTracer()
    local tracer = table.remove(tracerPool) -- Reuse if available
    if not tracer then
        tracer = Drawing.new("Line")
        tracer.Visible = false
        tracer.Color = Settings.Tracer_Color
        tracer.Thickness = Settings.Tracer_Thickness
        tracer.Transparency = 1
    end
    return tracer
end

-- Function to return tracers to the pool
function ReturnTracer(tracer)
    tracer.Visible = false
    table.insert(tracerPool, tracer)
end

-- Function to determine tracer origin point
function GetTracerOrigin()
    local viewportSize = camera.ViewportSize
    if _G.TracersFollowMouse then
        return Vector2.new(mouse.X, mouse.Y + 60)
    end
    if Settings.Tracer_Origin == "Middle" then
        return viewportSize * 0.5
    elseif Settings.Tracer_Origin == "Bottom" then
        return Vector2.new(viewportSize.X * 0.5, viewportSize.Y)
    elseif Settings.Tracer_Origin == "Top" then
        return Vector2.new(viewportSize.X * 0.5, 0)
    elseif Settings.Tracer_Origin == "Left" then
        return Vector2.new(0, viewportSize.Y * 0.5)
    elseif Settings.Tracer_Origin == "Right" then
        return Vector2.new(viewportSize.X, viewportSize.Y * 0.5)
    end
    return viewportSize * 0.5
end

-- Table to store active tracers
activeTracers = {}

-- Function to update tracers
function UpdateTracers()
    if not _G.TracersEnabled then
        for plr, tracer in pairs(activeTracers) do
            ReturnTracer(tracer)
            activeTracers[plr] = nil
        end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if not activeTracers[plr] then
                activeTracers[plr] = GetTracer()
            end

            local tracer = activeTracers[plr]
            local char = plr.Character
            if char then
                local rootPart = char:FindFirstChild("HumanoidRootPart")
                local humanoid = char:FindFirstChild("Humanoid")

                if rootPart and humanoid and humanoid.Health > 0 then
                    local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                    if onScreen then
                        tracer.From = GetTracerOrigin()
                        tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                        tracer.Visible = true
                    else
                        tracer.Visible = false
                    end
                else
                    ReturnTracer(tracer)
                    activeTracers[plr] = nil
                end
            end
        end
    end
end

-- Function to handle new players
function OnPlayerAdded(plr)
    if _G.TracersEnabled then
        activeTracers[plr] = GetTracer()
    end
end

-- Function to handle player removal
function OnPlayerRemoving(plr)
    local tracer = activeTracers[plr]
    if tracer then
        ReturnTracer(tracer)
        activeTracers[plr] = nil
    end
end

-- Event connections
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- RunService loop for updating tracers
tracerConnection = nil
function ToggleTracers(enabled)
    _G.TracersEnabled = enabled

    if enabled then
        tracerConnection = RunService.RenderStepped:Connect(UpdateTracers)
    else
        if tracerConnection then
            tracerConnection:Disconnect()
            tracerConnection = nil
        end
        -- Cleanup all tracers
        for plr, tracer in pairs(activeTracers) do
            ReturnTracer(tracer)
            activeTracers[plr] = nil
        end
    end
end

-- UI Elements
LeftGroupBox:AddToggle('TracersToggle', {
    Text = 'Enable Tracers',
    Default = false,
    Tooltip = 'Toggle to enable or disable tracers',
    Callback = ToggleTracers
})

LeftGroupBox:AddToggle('MouseFollowToggle', {
    Text = 'Enable Mouse Follow for Tracers',
    Default = false,
    Tooltip = 'Toggle to enable or disable tracers following the mouse',
    Callback = function(Value)
        _G.TracersFollowMouse = Value
    end
})

LeftGroupBox:AddDropdown('TracerPositionDropdown', {
    Values = { 'Bottom', 'Top', 'Left', 'Right' },
    Default = 1,
    Multi = false,
    Text = 'Tracer Position',
    Tooltip = 'Select the starting position of the tracers',
    Callback = function(Value)
        Settings.Tracer_Origin = Value
    end
})

Options.TracerPositionDropdown:OnChanged(function()
    print('Tracer position changed. New value:', Options.TracerPositionDropdown.Value)
end)

LeftGroupBox = Tabs.Visuals:AddLeftGroupbox('Cash Esp')

cashESPEnabled = false
textSize = 20

-- Caching frequently used Enum values
Workspace = game:GetService("Workspace")
Ignored = Workspace:WaitForChild("Ignored")
Drop = Ignored:WaitForChild("Drop")
Debris = game:GetService("Debris")
RunService = game:GetService("RunService")

-- Function to create or update BillboardGui for MoneyDrop
function cham(object)
    if object.Name == "MoneyDrop" then
        local bill = object:FindFirstChild("BillboardGui")
        
        if bill then
            if cashESPEnabled then
                bill.AlwaysOnTop = true
                bill.Size = UDim2.new(textSize, 0, textSize / 2, 0)
                bill.Enabled = true
            else
                bill.Enabled = false
            end
        end
    end
end

-- Apply Cash ESP toggle
LeftGroupBox:AddToggle('MyToggle', {
    Text = 'Cash Esp',
    Default = false, 
    Tooltip = 'Shows cash through walls', 
    Callback = function(Value)
        cashESPEnabled = Value
    end
})

-- Apply Text Size slider functionality
LeftGroupBox:AddSlider('MySlider', {
    Text = 'Text size slider',
    Default = 20,
    Min = 5,
    Max = 100,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        textSize = Value
    end
})

-- Function to check and update ESP for all Money Drops
function updateCashESP()
    for _, v in pairs(Drop:GetChildren()) do
        cham(v)
    end
end

-- Initial check for existing Money Drops on script load
updateCashESP()

-- Connect ChildAdded event to efficiently handle new Money Drops
Drop.ChildAdded:Connect(function(child)
    -- Debris cleanup for objects not needed anymore
    Debris:AddItem(child, 60)  -- Set a lifetime for ESP objects if necessary
    cham(child)
end)

-- Use RunService.Heartbeat to periodically check and update ESP for existing Money Drops
RunService.Heartbeat:Connect(function()
    if cashESPEnabled then
        updateCashESP()  -- Continually apply the Cash ESP effect
    end
end)

    RightGroupBox = Tabs.Visuals:AddRightGroupbox('Low GFX')

    MyButton = RightGroupBox:AddButton({
    Text = 'Low GFX CANT BE REVERTED',
    Func = function()
        if not _G.Ignore then
            _G.Ignore = {} -- Add Instances to this table to ignore them (e.g. _G.Ignore = {workspace.Map, workspace.Map2})
        end
        if not _G.WaitPerAmount then
            _G.WaitPerAmount = 500 -- Set Higher or Lower depending on your computer's performance
        end
        if _G.SendNotifications == nil then
            _G.SendNotifications = true -- Set to false if you don't want notifications
        end
        if _G.ConsoleLogs == nil then
            _G.ConsoleLogs = false -- Set to true if you want console logs (mainly for debugging)
        end
        
        
        
        if not game:IsLoaded() then
            repeat
                task.wait()
            until game:IsLoaded()
        end
        if not _G.Settings then
            _G.Settings = {
                Players = {
                    ["Ignore Me"] = true,
                    ["Ignore Others"] = true,
                    ["Ignore Tools"] = true
                },
                Meshes = {
                    NoMesh = false,
                    NoTexture = false,
                    Destroy = false
                },
                Images = {
                    Invisible = true,
                    Destroy = false
                },
                Explosions = {
                    Smaller = true,
                    Invisible = false, -- Not recommended for PVP games
                    Destroy = false -- Not recommended for PVP games
                },
                Particles = {
                    Invisible = true,
                    Destroy = false
                },
                TextLabels = {
                    LowerQuality = false,
                    Invisible = false,
                    Destroy = false
                },
                MeshParts = {
                    LowerQuality = true,
                    Invisible = false,
                    NoTexture = false,
                    NoMesh = false,
                    Destroy = false
                },
                Other = {
                    ["FPS Cap"] = true, -- Set this true to uncap FPS
                    ["No Camera Effects"] = true,
                    ["No Clothes"] = true,
                    ["Low Water Graphics"] = true,
                    ["No Shadows"] = true,
                    ["Low Rendering"] = false,
                    ["Low Quality Parts"] = true,
                    ["Low Quality Models"] = true,
                    ["Reset Materials"] = true,
                    ["Lower Quality MeshParts"] = true
                }
            }
        end
        local Players, Lighting, StarterGui, MaterialService = game:GetService("Players"), game:GetService("Lighting"), game:GetService("StarterGui"), game:GetService("MaterialService")
        local ME, CanBeEnabled = Players.LocalPlayer, {"ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles"}
        local function PartOfCharacter(Instance)
            for i, v in pairs(Players:GetPlayers()) do
                if v ~= ME and v.Character and Instance:IsDescendantOf(v.Character) then
                    return true
                end
            end
            return false
        end
        local function DescendantOfIgnore(Instance)
            for i, v in pairs(_G.Ignore) do
                if Instance:IsDescendantOf(v) then
                    return true
                end
            end
            return false
        end
        local function CheckIfBad(Instance)
            if not Instance:IsDescendantOf(Players) and (_G.Settings.Players["Ignore Others"] and not PartOfCharacter(Instance) or not _G.Settings.Players["Ignore Others"]) and (_G.Settings.Players["Ignore Me"] and ME.Character and not Instance:IsDescendantOf(ME.Character) or not _G.Settings.Players["Ignore Me"]) and (_G.Settings.Players["Ignore Tools"] and not Instance:IsA("BackpackItem") and not Instance:FindFirstAncestorWhichIsA("BackpackItem") or not _G.Settings.Players["Ignore Tools"])--[[not PartOfCharacter(Instance)]] and (_G.Ignore and not table.find(_G.Ignore, Instance) and not DescendantOfIgnore(Instance) or (not _G.Ignore or type(_G.Ignore) ~= "table" or #_G.Ignore <= 0)) then
                if Instance:IsA("DataModelMesh") then
                    if _G.Settings.Meshes.NoMesh and Instance:IsA("SpecialMesh") then
                        Instance.MeshId = ""
                    end
                    if _G.Settings.Meshes.NoTexture and Instance:IsA("SpecialMesh") then
                        Instance.TextureId = ""
                    end
                    if _G.Settings.Meshes.Destroy or _G.Settings["No Meshes"] then
                        Instance:Destroy()
                    end
                elseif Instance:IsA("FaceInstance") then
                    if _G.Settings.Images.Invisible then
                        Instance.Transparency = 1
                        Instance.Shiny = 1
                    end
                    if _G.Settings.Images.LowDetail then
                        Instance.Shiny = 1
                    end
                    if _G.Settings.Images.Destroy then
                        Instance:Destroy()
                    end
                elseif Instance:IsA("ShirtGraphic") then
                    if _G.Settings.Images.Invisible then
                        Instance.Graphic = ""
                    end
                    if _G.Settings.Images.Destroy then
                        Instance:Destroy()
                    end
                elseif table.find(CanBeEnabled, Instance.ClassName) then
                    if _G.Settings["Invisible Particles"] or _G.Settings["No Particles"] or (_G.Settings.Other and _G.Settings.Other["Invisible Particles"]) or (_G.Settings.Particles and _G.Settings.Particles.Invisible) then
                        Instance.Enabled = false
                    end
                    if (_G.Settings.Other and _G.Settings.Other["No Particles"]) or (_G.Settings.Particles and _G.Settings.Particles.Destroy) then
                        Instance:Destroy()
                    end
                elseif Instance:IsA("PostEffect") and (_G.Settings["No Camera Effects"] or (_G.Settings.Other and _G.Settings.Other["No Camera Effects"])) then
                    Instance.Enabled = false
                elseif Instance:IsA("Explosion") then
                    if _G.Settings["Smaller Explosions"] or (_G.Settings.Other and _G.Settings.Other["Smaller Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Smaller) then
                        Instance.BlastPressure = 1
                        Instance.BlastRadius = 1
                    end
                    if _G.Settings["Invisible Explosions"] or (_G.Settings.Other and _G.Settings.Other["Invisible Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Invisible) then
                        Instance.BlastPressure = 1
                        Instance.BlastRadius = 1
                        Instance.Visible = false
                    end
                    if _G.Settings["No Explosions"] or (_G.Settings.Other and _G.Settings.Other["No Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Destroy) then
                        Instance:Destroy()
                    end
                elseif Instance:IsA("Clothing") or Instance:IsA("SurfaceAppearance") or Instance:IsA("BaseWrap") then
                    if _G.Settings["No Clothes"] or (_G.Settings.Other and _G.Settings.Other["No Clothes"]) then
                        Instance:Destroy()
                    end
                elseif Instance:IsA("BasePart") and not Instance:IsA("MeshPart") then
                    if _G.Settings["Low Quality Parts"] or (_G.Settings.Other and _G.Settings.Other["Low Quality Parts"]) then
                        Instance.Material = Enum.Material.Plastic
                        Instance.Reflectance = 0
                    end
                elseif Instance:IsA("TextLabel") and Instance:IsDescendantOf(workspace) then
                    if _G.Settings["Lower Quality TextLabels"] or (_G.Settings.Other and _G.Settings.Other["Lower Quality TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.LowerQuality) then
                        Instance.Font = Enum.Font.SourceSans
                        Instance.TextScaled = false
                        Instance.RichText = false
                        Instance.TextSize = 14
                    end
                    if _G.Settings["Invisible TextLabels"] or (_G.Settings.Other and _G.Settings.Other["Invisible TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.Invisible) then
                        Instance.Visible = false
                    end
                    if _G.Settings["No TextLabels"] or (_G.Settings.Other and _G.Settings.Other["No TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.Destroy) then
                        Instance:Destroy()
                    end
                elseif Instance:IsA("Model") then
                    if _G.Settings["Low Quality Models"] or (_G.Settings.Other and _G.Settings.Other["Low Quality Models"]) then
                        Instance.LevelOfDetail = 1
                    end
                elseif Instance:IsA("MeshPart") then
                    if _G.Settings["Low Quality MeshParts"] or (_G.Settings.Other and _G.Settings.Other["Low Quality MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.LowerQuality) then
                        Instance.RenderFidelity = 2
                        Instance.Reflectance = 0
                        Instance.Material = Enum.Material.Plastic
                    end
                    if _G.Settings["Invisible MeshParts"] or (_G.Settings.Other and _G.Settings.Other["Invisible MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.Invisible) then
                        Instance.Transparency = 1
                        Instance.RenderFidelity = 2
                        Instance.Reflectance = 0
                        Instance.Material = Enum.Material.Plastic
                    end
                    if _G.Settings.MeshParts and _G.Settings.MeshParts.NoTexture then
                        Instance.TextureID = ""
                    end
                    if _G.Settings.MeshParts and _G.Settings.MeshParts.NoMesh then
                        Instance.MeshId = ""
                    end
                    if _G.Settings["No MeshParts"] or (_G.Settings.Other and _G.Settings.Other["No MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.Destroy) then
                        Instance:Destroy()
                    end
                end
            end
        end
        coroutine.wrap(pcall)(function()
            if (_G.Settings["Low Water Graphics"] or (_G.Settings.Other and _G.Settings.Other["Low Water Graphics"])) then
                if not workspace:FindFirstChildOfClass("Terrain") then
                    repeat
                        task.wait()
                    until workspace:FindFirstChildOfClass("Terrain")
                end
                workspace:FindFirstChildOfClass("Terrain").WaterWaveSize = 0
                workspace:FindFirstChildOfClass("Terrain").WaterWaveSpeed = 0
                workspace:FindFirstChildOfClass("Terrain").WaterReflectance = 0
                workspace:FindFirstChildOfClass("Terrain").WaterTransparency = 0
                if sethiddenproperty then
                    sethiddenproperty(workspace:FindFirstChildOfClass("Terrain"), "Decoration", false)
                else
                    warn("Your exploit does not support sethiddenproperty, please use a different exploit.")
                end
                if _G.ConsoleLogs then
                    warn("Low Water Graphics Enabled")
                end
            end
        end)
        coroutine.wrap(function()
            pcall(function()
                if _G.Settings["No Shadows"] or (_G.Settings.Other and _G.Settings.Other["No Shadows"]) then
                    Lighting.GlobalShadows = false
                    Lighting.FogEnd = 9e9
                    Lighting.ShadowSoftness = 0
                    if sethiddenproperty then
                        sethiddenproperty(Lighting, "Technology", 2)
                    end
                    if _G.ConsoleLogs then
                        warn("No Shadows Enabled")
                    end
                end
            end)
        end)()
        
        -- Low Rendering
        coroutine.wrap(function()
            pcall(function()
                if _G.Settings["Low Rendering"] or (_G.Settings.Other and _G.Settings.Other["Low Rendering"]) then
                    settings().Rendering.QualityLevel = 1
                    settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
                    if _G.ConsoleLogs then
                        warn("Low Rendering Enabled")
                    end
                end
            end)
        end)()
        
        -- Reset Materials
        coroutine.wrap(function()
            pcall(function()
                if _G.Settings["Reset Materials"] or (_G.Settings.Other and _G.Settings.Other["Reset Materials"]) then
                    for i, v in pairs(MaterialService:GetChildren()) do
                        v:Destroy()
                    end
                    if _G.ConsoleLogs then
                        warn("Reset Materials Enabled")
                    end
                end
            end)
        end)()
        coroutine.wrap(function()
            pcall(function()
                if _G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"]) then
                    local fpsCapSetting = _G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"])
        
                    if type(fpsCapSetting) == "string" or type(fpsCapSetting) == "number" then
                        if setfpscap then
                            setfpscap(tonumber(fpsCapSetting))
                            if _G.ConsoleLogs then
                                warn("FPS Capped to " .. tostring(fpsCapSetting))
                            end
                        end
                    elseif fpsCapSetting == true then
                        if setfpscap then
                            setfpscap(1e6)
                            if _G.ConsoleLogs then
                                warn("FPS Uncapped")
                            end
                        end
                    end
                else
                    warn("FPS Cap Failed")
                end
            end)
        end)()
        game.DescendantAdded:Connect(function(value)
            wait(_G.LoadedWait or 1)
            CheckIfBad(value)
        end)
        
        local Descendants = game:GetDescendants()
        local StartNumber = _G.WaitPerAmount or 500
        local WaitNumber = _G.WaitPerAmount or 500
        if _G.ConsoleLogs then
            warn("Checking " .. #Descendants .. " Instances...")
        end
        for i, v in pairs(Descendants) do
            CheckIfBad(v)
            if i == WaitNumber then
                task.wait()
                if _G.ConsoleLogs then
                    print("Loaded " .. i .. "/" .. #Descendants)
                end
                WaitNumber = WaitNumber + StartNumber
            end
        end
        
        StarterGui:SetCore("SendNotification", {
            Title = "Fps Booster Loaded",
            Text = "🎭  Hexploit 🎭",
            Duration = 5,
        })
        
        warn("FPS Booster Loaded!")
        --game.DescendantAdded:Connect(CheckIfBad)
        --[[game.DescendantAdded:Connect(function(value)
            CheckIfBad(value)
        end)]]
    end,
    DoubleClick = true,
    Tooltip = 'Makes your Gfx low CANT BE REVERTED'
    })

    RightGroupBox = Tabs.Visuals:AddRightGroupbox('No Fog')

    local lighting = game:GetService("Lighting")
    local StarterGui = game:GetService("StarterGui")
    local debris = game:GetService("Debris")

    -- Store common values in variables to minimize repetitive calls
    local fogEnd = lighting.FogEnd
    local fogStart = lighting.FogStart

    -- Create the toggle button (integrated from your provided example)
    RightGroupBox:AddToggle('MyToggle', {
    Text = 'No Fog',
    Default = false, -- Default value (true / false)
    Tooltip = 'This removes any kind of Fog from the game', -- Information shown when you hover over the toggle

    Callback = function(Value)
        if Value then
            -- Check if the fog removal has been executed before
            if not _G.FogRemovalExecuted then
                -- Store original fog settings
                _G.OriginalFogSettings = {
                    FogEnd = fogEnd,
                    FogStart = fogStart,
                }

                -- Remove fog by setting extreme values for FogEnd and FogStart
                lighting.FogEnd = 100000  -- Set this to a high value to push fog far away
                lighting.FogStart = 0     -- Set this to 0 to ensure fog doesn't start close

                -- Optionally remove any atmosphere if present
                local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
                if atmosphere then
                    atmosphere:Destroy()
                end

                -- Set the flag to indicate it has been executed
                _G.FogRemovalExecuted = true
            end
        else
            -- Reset the fog settings back to the original values
            if _G.FogRemovalExecuted then
                lighting.FogEnd = _G.OriginalFogSettings.FogEnd
                lighting.FogStart = _G.OriginalFogSettings.FogStart

                -- Reset the flag to indicate it's no longer executed
                _G.FogRemovalExecuted = false
            end
        end

        -- Print the toggle status to the console
        print('[cb] MyToggle changed to:', Value)
    end
    })

    RightGroupBox = Tabs.Visuals:AddRightGroupbox('Fullbright')

    RightGroupBox:AddToggle('MyToggle', {
        Text = 'Fullbright',
        Default = false, -- Default value (true / false)
        Tooltip = 'Removes shadows and increases brightness', -- Information shown when you hover over the toggle
    
        Callback = function(Value)
            if not _G.FullBrightExecuted then
                _G.FullBrightEnabled = false
    
                local Lighting = game:GetService("Lighting")
                
                -- Store default settings in a table
                _G.NormalLightingSettings = {
                    Brightness = Lighting.Brightness,
                    ClockTime = Lighting.ClockTime,
                    GlobalShadows = Lighting.GlobalShadows,
                    Ambient = Lighting.Ambient
                }
    
                -- Full Bright settings
                local FullBrightSettings = {
                    Brightness = 1,
                    ClockTime = 12,
                    GlobalShadows = false,
                    Ambient = Color3.fromRGB(178, 178, 178)
                }
    
                -- Set lighting properties
                local function setLightingProperties(properties)
                    for property, value in pairs(properties) do
                        Lighting[property] = value
                    end
                end
    
                -- Initial setup
                setLightingProperties(FullBrightSettings)
    
                -- Create a single function to handle property changes
                local function createPropertyChangeListener(property, defaultValue, newValue)
                    Lighting:GetPropertyChangedSignal(property):Connect(function()
                        if Lighting[property] ~= defaultValue and Lighting[property] ~= _G.NormalLightingSettings[property] then
                            _G.NormalLightingSettings[property] = Lighting[property]
                            if not _G.FullBrightEnabled then
                                repeat wait() until _G.FullBrightEnabled
                            end
                            Lighting[property] = newValue
                        end
                    end)
                end
    
                -- Set up property listeners
                for property, newValue in pairs(FullBrightSettings) do
                    createPropertyChangeListener(property, newValue, newValue)
                end
    
                -- Periodically toggle FullBright settings
                local LatestValue = true
                spawn(function()
                    while wait() do
                        if _G.FullBrightEnabled ~= LatestValue then
                            if not _G.FullBrightEnabled then
                                setLightingProperties(_G.NormalLightingSettings)
                            else
                                setLightingProperties(FullBrightSettings)
                            end
                            LatestValue = not LatestValue
                        end
                    end
                end)
            end
    
            -- Toggle full bright state
            _G.FullBrightExecuted = true
            _G.FullBrightEnabled = Value -- directly using Value here to toggle the state
        end
    })    

    RightGroupBox = Tabs.Visuals:AddRightGroupbox('Ambience')

    -- Place this script in LocalScript or StarterPlayer -> StarterPlayerScripts

local lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local runService = game:GetService("RunService")
local debris = game:GetService("Debris")

-- Store original lighting settings and ClockTime
if not _G.OriginalLightingSettings then
    _G.OriginalLightingSettings = {
        Ambient = lighting.Ambient,
        OutdoorAmbient = lighting.OutdoorAmbient,
        Brightness = lighting.Brightness,
        ColorShift_Bottom = lighting.ColorShift_Bottom,
        ColorShift_Top = lighting.ColorShift_Top,
        FogColor = lighting.FogColor,
        FogStart = lighting.FogStart,
        FogEnd = lighting.FogEnd,
        TimeOfDay = lighting.TimeOfDay,
        Skybox = lighting:FindFirstChildOfClass("Sky"), -- Ensure no errors if skybox doesn't exist
        ClockTime = lighting.ClockTime
    }
end

-- Store the selected RGB colors for lighting
local selectedAmbientColor = _G.OriginalLightingSettings.Ambient
local selectedOutdoorAmbientColor = _G.OriginalLightingSettings.OutdoorAmbient
local selectedColorShiftBottom = _G.OriginalLightingSettings.ColorShift_Bottom
local selectedColorShiftTop = _G.OriginalLightingSettings.ColorShift_Top
local selectedFogColor = _G.OriginalLightingSettings.FogColor

-- Pre-store skybox asset ID to avoid repeated string literals
local skyboxAssetID = "rbxassetid://1294489738"

-- Add the toggle for the royal purple ambience
RightGroupBox:AddToggle('AmbienceToggle', {
    Text = 'Enable Custom Ambient Lighting',
    Default = false, -- Default value (true / false)
    Tooltip = 'Toggle to switch between original and custom ambient lighting',

    Callback = function(Value)
        if Value then
            -- Apply the altered custom ambient lighting settings
            lighting.Ambient = selectedAmbientColor
            lighting.OutdoorAmbient = selectedOutdoorAmbientColor
            lighting.Brightness = 2
            lighting.ColorShift_Bottom = selectedColorShiftBottom
            lighting.ColorShift_Top = selectedColorShiftTop
            lighting.FogColor = selectedFogColor
            lighting.FogStart = 0
            lighting.FogEnd = 500
            lighting.TimeOfDay = "18:00:00"

            -- Set a custom skybox for the custom ambience
            local skybox = lighting:FindFirstChildOfClass("Sky")
            if not skybox then
                skybox = Instance.new("Sky")
                skybox.Parent = lighting
            end
            skybox.SkyboxBk = skyboxAssetID
            skybox.SkyboxDn = skyboxAssetID
            skybox.SkyboxFt = skyboxAssetID
            skybox.SkyboxLf = skyboxAssetID
            skybox.SkyboxRt = skyboxAssetID
            skybox.SkyboxUp = skyboxAssetID

            -- Set the flag to indicate that the lighting has been altered
            _G.AmbienceToggled = true

            -- Immediately set the time of day to the current slider value when toggle is enabled
            lighting.ClockTime = _G.ClockTimeOverride or 17 -- Default to the slider value if set
        else
            -- Reset the lighting back to the original settings
            lighting.Ambient = _G.OriginalLightingSettings.Ambient
            lighting.OutdoorAmbient = _G.OriginalLightingSettings.OutdoorAmbient
            lighting.Brightness = _G.OriginalLightingSettings.Brightness
            lighting.ColorShift_Bottom = _G.OriginalLightingSettings.ColorShift_Bottom
            lighting.ColorShift_Top = _G.OriginalLightingSettings.ColorShift_Top
            lighting.FogColor = _G.OriginalLightingSettings.FogColor
            lighting.FogStart = _G.OriginalLightingSettings.FogStart
            lighting.FogEnd = _G.OriginalLightingSettings.FogEnd
            lighting.TimeOfDay = _G.OriginalLightingSettings.TimeOfDay

            -- Reset the skybox immediately (if it exists)
            local sky = lighting:FindFirstChildOfClass("Sky")
            if sky then
                debris:AddItem(sky, 1) -- Use debris to clean up skybox instance
            end

            -- Restore the original skybox (if it exists)
            if _G.OriginalLightingSettings.Skybox then
                local originalSkybox = _G.OriginalLightingSettings.Skybox:Clone()
                originalSkybox.Parent = lighting
            end

            -- Reset the flag to indicate the lighting has been restored
            _G.AmbienceToggled = false
        end
    end
})

-- Add the slider to control brightness with max value set to 20
RightGroupBox:AddSlider('BrightnessSlider', { 
    Text = 'Brightness Control',
    Default = 10,  -- Set initial brightness to 2 (adjust if needed)
    Min = 0,
    Max = 20,  -- Max brightness set to 20
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        -- Immediately change the lighting brightness live based on slider value
        lighting.Brightness = Value
    end
})

-- Add the slider to control fog end with max value set to 1000
RightGroupBox:AddSlider('FogEndSlider', { 
    Text = 'Fog End Control',
    Default = 500,  -- Set initial fog end to 500 (adjust if needed)
    Min = 100,
    Max = 10000,  -- Max fog end set to 100000
    Rounding = 0,
    Compact = false,

    Callback = function(Value)
        lighting.FogEnd = Value
    end
})

-- Add the slider to control the time of day
RightGroupBox:AddSlider('TimeOfDaySlider', { 
    Text = 'Time of Day Control',
    Default = 17,  -- Set initial time to 12:00 (adjust if needed)
    Min = 0,
    Max = 24,  -- 24-hour format for time of day
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        -- Lock the time of day client-side by setting it
        if _G.AmbienceToggled then
            lighting.ClockTime = Value
            -- Save the desired value so it stays fixed
            _G.ClockTimeOverride = Value
        end
    end
})

-- Lock the server time cycle client-side and override server changes, only when toggle is active
runService.Heartbeat:Connect(function()
    if _G.AmbienceToggled and _G.ClockTimeOverride then
        lighting.ClockTime = _G.ClockTimeOverride
    end
end)

-- Add RGB color pickers for each lighting property
RightGroupBox:AddLabel('Ambient Color Picker'):AddColorPicker('AmbientColorPicker', {
    Default = Color3.fromRGB(120, 81, 169),  -- Default royal purple
    Title = 'Select Ambient Color',
    Transparency = 0,  -- Optional

    Callback = function(Value)
        selectedAmbientColor = Value
        if _G.AmbienceToggled then
            lighting.Ambient = selectedAmbientColor
        end
    end
})

RightGroupBox:AddLabel('Outdoor Ambient Color Picker'):AddColorPicker('OutdoorAmbientColorPicker', {
    Default = Color3.fromRGB(120, 81, 169),  -- Default color
    Title = 'Select Outdoor Ambient Color',

    Callback = function(Value)
        selectedOutdoorAmbientColor = Value
        if _G.AmbienceToggled then
            lighting.OutdoorAmbient = selectedOutdoorAmbientColor
        end
    end
})

RightGroupBox:AddLabel('Color Shift Bottom Picker'):AddColorPicker('ColorShiftBottomPicker', {
    Default = Color3.fromRGB(120, 81, 169),  -- Default color
    Title = 'Select Color Shift Bottom',

    Callback = function(Value)
        selectedColorShiftBottom = Value
        if _G.AmbienceToggled then
            lighting.ColorShift_Bottom = selectedColorShiftBottom
        end
    end
})

RightGroupBox:AddLabel('Color Shift Top Picker'):AddColorPicker('ColorShiftTopPicker', {
    Default = Color3.fromRGB(120, 81, 169),  -- Default color
    Title = 'Select Color Shift Top',

    Callback = function(Value)
        selectedColorShiftTop = Value
        if _G.AmbienceToggled then
            lighting.ColorShift_Top = selectedColorShiftTop
        end
    end
})

RightGroupBox:AddLabel('Fog Color Picker'):AddColorPicker('FogColorPicker', {
    Default = Color3.fromRGB(120, 81, 169),  -- Default color
    Title = 'Select Fog Color',

    Callback = function(Value)
        selectedFogColor = Value
        if _G.AmbienceToggled then
            lighting.FogColor = selectedFogColor
        end
    end
})

    LeftGroupBox = Tabs.Movement:AddLeftGroupbox('Speed')

    --// Required Services and Variables
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local KeyCode = Enum.KeyCode -- Store Enum for repeated use

    -- Utility Functions
    local Utility = {
    hasCharacter = function(player)
        local character = player and player.Character
        return character and character:FindFirstChild("HumanoidRootPart", true) and character:FindFirstChild("Humanoid", true)
    end,
    newConnection = function(event, callback)
        return event:Connect(callback)
    end
    }

    -- Configuration Flags
    local Flags = {
    cframeSpeedEnabled = false, -- Initially off
    cframeSpeedToggleAllowed = false, -- Toggle must be enabled via UI
    cframeSpeedKeybind = KeyCode.V, -- Default toggle key set to V
    cframeSpeedAmount = 150 -- Default speed
    }

    -- CFrame Speed Functionality
    local function updateCframeSpeed(deltaTime)
    if Flags.cframeSpeedEnabled and Utility.hasCharacter(LocalPlayer) then
        local character = LocalPlayer.Character
        local hrp = character:FindFirstChild("HumanoidRootPart", true)
        local humanoid = character:FindFirstChild("Humanoid", true)
        local moveDirection = humanoid and humanoid.MoveDirection

        if hrp and moveDirection then
            local movement = moveDirection.Unit * Flags.cframeSpeedAmount * deltaTime
            if movement.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + movement
            end
        end
    end
    end

    -- UI Integration
    LeftGroupBox:AddToggle('CframeSpeedToggle', {
    Text = 'Toggle CFrame Speed',
    Default = false,
    Tooltip = 'Toggles speed using CFrames',
    Callback = function(value)
        Flags.cframeSpeedToggleAllowed = value
        if not value then
            Flags.cframeSpeedEnabled = false
        end
    end
    })

    LeftGroupBox:AddLabel('Keybind'):AddKeyPicker('CframeSpeedKeybind', {
    Default = 'V',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'Toggle CFrame Speed',
    NoUI = false,
    Callback = function(value)
        if value and typeof(value) == "EnumItem" then
            Flags.cframeSpeedKeybind = KeyCode[value.Name]
        end
    end,
    ChangedCallback = function(newValue)
        if newValue and typeof(newValue) == "EnumItem" then
            Flags.cframeSpeedKeybind = KeyCode[newValue.Name]
        end
    end
    })

    LeftGroupBox:AddSlider('CframeSpeedSlider', {
    Text = 'CFrame Speed Amount',
    Default = 150,
    Min = 16,
    Max = 1000,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        Flags.cframeSpeedAmount = value
    end
    })

    -- RenderStepped Connection for CFrame Speed
    if _G.cframeSpeedRenderSteppedConnection then
    _G.cframeSpeedRenderSteppedConnection:Disconnect()
    end
    _G.cframeSpeedRenderSteppedConnection = RunService.Heartbeat:Connect(updateCframeSpeed)

    -- Input Listener for Keybind
    if _G.cframeSpeedToggleListener then
    _G.cframeSpeedToggleListener:Disconnect()
    end
    _G.cframeSpeedToggleListener = Utility.newConnection(UserInputService.InputBegan, function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Flags.cframeSpeedKeybind then
        if Flags.cframeSpeedToggleAllowed then
            Flags.cframeSpeedEnabled = not Flags.cframeSpeedEnabled
        end
    end
    end)

    LeftGroupBox = Tabs.Movement:AddLeftGroupbox('Fly')

    --// Required Services and Variables
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local KeyCode = Enum.KeyCode -- Store Enum for repeated use

    -- Utility Functions
    local Utility = {
    hasCharacter = function(player)
        local character = player and player.Character
        return character and character:FindFirstChild("HumanoidRootPart", true) and character:FindFirstChild("Humanoid", true)
    end,
    newConnection = function(event, callback)
        return event:Connect(callback)
    end
    }

    -- Configuration Flags
    local Flags = {
    rageCFrameFlyEnabled = false, -- Initially off
    rageCFrameFlyToggleAllowed = false, -- Toggle must be enabled via UI
    rageCFrameFlyKeybind = KeyCode.B, -- Default toggle key set to B
    rageCFrameFlyAmount = 250 -- Default fly speed
    }

    -- Fly Functionality
    local function updateFly(deltaTime)
    if Flags.rageCFrameFlyEnabled and Utility.hasCharacter(LocalPlayer) then
        local character = LocalPlayer.Character
        local hrp = character:FindFirstChild("HumanoidRootPart", true)
        local moveDirection = character:FindFirstChild("Humanoid", true).MoveDirection

        -- Vertical movement based on key input
        local verticalSpeed = (UserInputService:IsKeyDown(KeyCode.Space) and 1 or UserInputService:IsKeyDown(KeyCode.LeftShift) and -1 or 0)
        local verticalMovement = Vector3.new(0, verticalSpeed, 0)

        -- Combine horizontal and vertical movement for consistent speed
        local movement = (moveDirection + verticalMovement).Unit * Flags.rageCFrameFlyAmount * deltaTime

        -- Update position using CFrame
        if movement.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + movement
        end

        -- Adjust velocity to prevent conflicts
        hrp.Velocity = Vector3.zero
    end
    end

    -- UI Integration
    LeftGroupBox:AddToggle('CframeFlightToggle', {
    Text = 'Toggle Cframe Flight',
    Default = false,
    Tooltip = 'Toggles flight using CFrames',
    Callback = function(value)
        Flags.rageCFrameFlyToggleAllowed = value
        if not value then
            Flags.rageCFrameFlyEnabled = false
        end
    end
    })

    LeftGroupBox:AddLabel('Keybind'):AddKeyPicker('FlightKeybind', {
    Default = 'B',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'Toggle Cframe Flight',
    NoUI = false,

    Callback = function(value)
        if value and typeof(value) == "EnumItem" then
            Flags.rageCFrameFlyKeybind = KeyCode[value.Name]
        end
    end,

    ChangedCallback = function(newValue)
        if newValue and typeof(newValue) == "EnumItem" then
            Flags.rageCFrameFlyKeybind = KeyCode[newValue.Name]
        end
    end
    })

    LeftGroupBox:AddSlider('CframeFlightSpeed', {
    Text = 'CFrame Flight Speed',
    Default = 250,
    Min = 16,
    Max = 2000,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        Flags.rageCFrameFlyAmount = value
    end
    })

    -- RenderStepped Connection for Flight
    if _G.flyRenderSteppedConnection then
    _G.flyRenderSteppedConnection:Disconnect()
    end
    _G.flyRenderSteppedConnection = RunService.Heartbeat:Connect(updateFly)

    -- Input Listener for Keybind
    if _G.flyToggleListener then
    _G.flyToggleListener:Disconnect()
    end
    _G.flyToggleListener = Utility.newConnection(UserInputService.InputBegan, function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Flags.rageCFrameFlyKeybind then
        if Flags.rageCFrameFlyToggleAllowed then
            Flags.rageCFrameFlyEnabled = not Flags.rageCFrameFlyEnabled
        end
    end
    end)

    LeftGroupBox = Tabs.Movement:AddLeftGroupbox('Fly V2')

    --// Required Services and Variables
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local mouse = LocalPlayer:GetMouse()

    local KeyCode = Enum.KeyCode -- Store Enum for repeated use

    -- Utility Functions
    local Utility = {
    hasCharacter = function(player)
        local character = player and player.Character
        return character and character:FindFirstChild("HumanoidRootPart", true) and character:FindFirstChild("Humanoid", true)
    end,
    newConnection = function(event, callback)
        return event:Connect(callback)
    end
    }

    -- Configuration Flags
    local Flags = {
    v2CFrameFlyEnabled = false, -- Initially off
    v2CFrameFlyToggleAllowed = false, -- Toggle must be enabled via UI
    v2CFrameFlyKeybind = KeyCode.X,
    v2CFrameFlyAmount = 10, -- Default fly speed
    flying = false, -- Flight state management
    speed = 10, -- Default speed
    keys = {a = false, d = false, w = false, s = false}, -- Key states for movement
    lastMoveTime = tick(), -- Tracks the last time movement occurred
    storedSpeed = 10, -- Store speed separately to avoid resetting
    }

    -- Flight Logic
    local torso = LocalPlayer.Character and LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    local Core
    local weld
    local function startFlying()
    if not torso then return end

    -- Core Part for flight
    Core = Instance.new("Part")
    Core.Name = "Core"
    Core.Size = Vector3.new(0.05, 0.05, 0.05)
    Core.Parent = workspace
    weld = Instance.new("Weld", Core)
    weld.Part0 = Core
    weld.Part1 = LocalPlayer.Character.HumanoidRootPart
    weld.C0 = CFrame.new(0, 0, 0)

    -- BodyPosition and BodyGyro for controlling movement
    local pos = Instance.new("BodyPosition", Core)
    local gyro = Instance.new("BodyGyro", Core)
    pos.Name = "EPIXPOS"
    pos.maxForce = Vector3.new(math.huge, math.huge, math.huge)
    pos.position = Core.Position
    gyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    gyro.cframe = Core.CFrame

    -- Movement control loop
    repeat
        wait()

        -- Check if flight is enabled before updating position
        if not Flags.flying then
            break
        end

        LocalPlayer.Character.Humanoid.PlatformStand = true
        local newPos = gyro.cframe - gyro.cframe.p + pos.position

        -- Reset speed if no movement keys are pressed (this is only for control, not for final speed)
        if not Flags.keys.w and not Flags.keys.s and not Flags.keys.a and not Flags.keys.d then
            Flags.speed = Flags.storedSpeed
        else
            Flags.speed = Flags.storedSpeed -- Maintain the stored speed
        end

        -- Horizontal and vertical movement
        if Flags.keys.w then
            newPos = newPos + workspace.CurrentCamera.CoordinateFrame.lookVector * Flags.speed
            Flags.lastMoveTime = tick() -- Update last move time
        end
        if Flags.keys.s then
            newPos = newPos - workspace.CurrentCamera.CoordinateFrame.lookVector * Flags.speed
            Flags.lastMoveTime = tick() -- Update last move time
        end
        if Flags.keys.d then
            newPos = newPos * CFrame.new(Flags.speed, 0, 0)
            Flags.lastMoveTime = tick() -- Update last move time
        end
        if Flags.keys.a then
            newPos = newPos * CFrame.new(-Flags.speed, 0, 0)
            Flags.lastMoveTime = tick() -- Update last move time
        end

        pos.position = newPos.p

        -- Adjust the rotation
        if Flags.keys.w then
            gyro.cframe = workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad(Flags.speed * 0), 0, 0)
        elseif Flags.keys.s then
            gyro.cframe = workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(math.rad(Flags.speed * 0), 0, 0)
        else
            gyro.cframe = workspace.CurrentCamera.CoordinateFrame
        end
    until not Flags.flying

    if gyro then gyro:Destroy() end
    if pos then pos:Destroy() end
    Flags.flying = false
    LocalPlayer.Character.Humanoid.PlatformStand = false
    end

    -- Input handlers
    local function handleKeyInput(input, gameProcessed)
    if gameProcessed or not Flags.v2CFrameFlyToggleAllowed then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == KeyCode.W then
            Flags.keys.w = true
        elseif input.KeyCode == KeyCode.S then
            Flags.keys.s = true
        elseif input.KeyCode == KeyCode.A then
            Flags.keys.a = true
        elseif input.KeyCode == KeyCode.D then
            Flags.keys.d = true
        elseif input.KeyCode == Flags.v2CFrameFlyKeybind then
            -- Toggle flight on key press
            Flags.flying = not Flags.flying
            if Flags.flying then
                startFlying()
            end
        end
    end
    end

    local function handleKeyRelease(input)
    if input.KeyCode == KeyCode.W then
        Flags.keys.w = false
    elseif input.KeyCode == KeyCode.S then
        Flags.keys.s = false
    elseif input.KeyCode == KeyCode.A then
        Flags.keys.a = false
    elseif input.KeyCode == KeyCode.D then
        Flags.keys.d = false
    end
    end

    -- UI Integration for CFrame Flight
    LeftGroupBox:AddToggle('v2flighttoggle', {
    Text = 'Toggle Flight V2',
    Default = false,
    Tooltip = 'Toggles flight using CFrames',
    Callback = function(value)
        Flags.v2CFrameFlyToggleAllowed = value
        if not value then
            Flags.flying = false -- Ensure flight is stopped when toggle is turned off
        end
    end
    })

    LeftGroupBox:AddLabel('Keybind'):AddKeyPicker('v2flightkeybind', {
    Default = 'X',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'Toggle Flight V2',
    NoUI = false,
    Callback = function(value)
        if value and typeof(value) == "EnumItem" then
            Flags.v2CFrameFlyKeybind = KeyCode[value.Name]
        end
    end,
    ChangedCallback = function(newValue)
        if newValue and typeof(newValue) == "EnumItem" then
            Flags.v2CFrameFlyKeybind = KeyCode[newValue.Name]
        end
    end
    })

    LeftGroupBox:AddSlider('v2flightspeed', {
    Text = 'CFrame Flight Speed',
    Default = 10,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        Flags.storedSpeed = value -- Save the new speed to store it
        Flags.speed = value -- Update the current speed
    end
    })

    -- Input Listener for Keybind and Movement
    if _G.flyv2ToggleListener then
    _G.flyv2ToggleListener:Disconnect()
    end
    _G.flyv2ToggleListener = Utility.newConnection(UserInputService.InputBegan, handleKeyInput)
    _G.flyv2ReleaseListener = Utility.newConnection(UserInputService.InputEnded, handleKeyRelease)

    LeftGroupBox = Tabs.Movement:AddLeftGroupbox('No Clip')

    -- Variables
    if _G.noClipLoaded == nil then
    _G.noClipLoaded = false -- Default state
    end

    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Player = game.Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local NoClip = false
    local Keybind = Enum.KeyCode.N -- Default key for NoClip
    local HotkeyEnabled = false -- Track whether the hotkey is enabled or not

    -- Cache expensive operations
    local BasePart = "BasePart"

    -- Toggle NoClip function
    local function toggleNoClip(state)
    NoClip = state ~= nil and state or not NoClip

    if NoClip then
        -- NoClip enabled, `CanCollide` handled in Heartbeat
    else
        -- Reset `CanCollide` for character parts
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA(BasePart) then
                part.CanCollide = true
            end
        end
    end
    end

    -- Enforce NoClip during Heartbeat
    local function enforceNoClip()
    if NoClip and Character then
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA(BasePart) then
                part.CanCollide = false
            end
        end
    end
    end

    -- Handle character respawn
    local function onCharacterAdded(newCharacter)
    Character = newCharacter
    if NoClip then
        toggleNoClip(true)
    end
    end

    -- Execution logic for keybind (only works when hotkey is enabled)
    local function onKeyPress(input, gameProcessed)
    if gameProcessed then return end
    if HotkeyEnabled and input.KeyCode == Keybind then
        toggleNoClip() -- Toggle NoClip on key press
    end
    end

    -- Bind the hotkey event to the input handler
    if not _G.noClipInputConnection then
    _G.noClipInputConnection = UserInputService.InputBegan:Connect(onKeyPress)
    end

    -- Continuously enforce NoClip during Heartbeat
    if not _G.noClipEnforceConnection then
    _G.noClipEnforceConnection = RunService.Heartbeat:Connect(enforceNoClip)
    end

    -- Handle character respawn
    if not _G.noClipCharacterAddedConnection then
    _G.noClipCharacterAddedConnection = Player.CharacterAdded:Connect(onCharacterAdded)
    end

    -- UI code for toggling and keybinding
    LeftGroupBox:AddToggle('NoClipToggle', {
    Text = 'Toggle NoClip',
    Default = false, -- Default value (true / false)
    Tooltip = 'Toggles noclip allowing movement through obstacles', -- Information shown when you hover over the toggle

    Callback = function(Value)
        HotkeyEnabled = Value -- Enable or disable the hotkey functionality based on the toggle
    end
    })

    LeftGroupBox:AddLabel('Keybind'):AddKeyPicker('KeyPicker', {
    Default = 'N', -- Default key for NoClip toggle
    SyncToggleState = true, -- SyncToggleState with the toggle
    Mode = 'Toggle', -- Modes: Always, Toggle, Hold
    Text = 'NoClip Keybind', -- Text to display in the keybind menu
    NoUI = false, -- Show in the Keybind menu

    -- Occurs when the keybind is changed
    ChangedCallback = function(NewKey)
        -- Update the keybind dynamically
        Keybind = NewKey
    end,

    -- Occurs when the keybind is clicked, Value is true/false
    Callback = function(Value)
        -- The hotkey functionality only works if the toggle is enabled.
    end
    })

    RightGroupBox = Tabs.Movement:AddRightGroupbox('Fake Macro')

    RightGroupBox:AddToggle('MyToggle', {
        Text = 'Fake Macro',
        Default = false,
        Tooltip = 'This is a tooltip',
    
        Callback = function(Value)
            print('[cb] MyToggle changed to:', Value)
            
            -- Toggle the speed feature based on the toggle value
            if Value then
                _G.ScriptEnabled = true
                resetCharacter()
            else
                _G.ScriptEnabled = false
            end
        end
    })
    
    player = game.Players.LocalPlayer
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    emoteId = "rbxassetid://3189777795"
    
    -- Speed variables
    maxSpeed = 300
    baseSpeed = 16
    speedIncrement = 1.75
    emoteDuration = 1.6 -- Default emote duration
    
    -- Variables to track speed and state
    currentSpeed = baseSpeed
    isSpeedEnabled = false
    emoteTrack = nil
    isSpeedReady = false
    
    -- Cache the hotkey (Q) for reuse
    Keybind = Enum.KeyCode.Q
    
    -- Efficient use of services and enum values
    UserInputService = game:GetService("UserInputService")
    RunService = game:GetService("RunService")
    
    -- Function to initialize the character and humanoid
    function initializeCharacter(newCharacter)
        character = newCharacter or player.Character
        humanoid = character:WaitForChild("Humanoid")
        currentSpeed = baseSpeed
        humanoid.WalkSpeed = baseSpeed
        isSpeedEnabled = false
        isSpeedReady = false
    end
    
    -- Function to forcefully reset the character
    function resetCharacter()
        if humanoid then
            humanoid.Health = 0
        end
    end
    
    -- Function to play the emote
    function playEmote()
        animation = Instance.new("Animation")
        animation.AnimationId = emoteId
        emoteTrack = humanoid:LoadAnimation(animation)
        emoteTrack:Play()
    
        -- Stop the emote after the duration from the slider
        task.wait(emoteDuration)
        if emoteTrack and emoteTrack.IsPlaying then
            emoteTrack:Stop()
        end
    
        -- After the emote ends, set isSpeedReady to true to start gradual speed increase
        isSpeedReady = true
    end
    
    -- Function to manage speed (gradual increase)
    function updateSpeed()
        if _G.ScriptEnabled and isSpeedEnabled then
            if isSpeedReady then
                currentSpeed = math.min(currentSpeed + speedIncrement, maxSpeed)
                humanoid.WalkSpeed = currentSpeed
            else
                humanoid.WalkSpeed = baseSpeed
            end
        elseif not isSpeedEnabled or not _G.ScriptEnabled then
            humanoid.WalkSpeed = baseSpeed
            currentSpeed = baseSpeed
        end
    end
    
    -- Toggle the speed feature
    function toggleSpeedFeature()
        if not _G.ScriptEnabled then return end
        isSpeedEnabled = not isSpeedEnabled
        if isSpeedEnabled then
            currentSpeed = baseSpeed
            humanoid.WalkSpeed = baseSpeed
            isSpeedReady = false
            playEmote()
        else
            currentSpeed = baseSpeed
            humanoid.WalkSpeed = baseSpeed
            isSpeedReady = false
        end
    end
    
    -- Reinitialize the script on character respawn
    player.CharacterAdded:Connect(initializeCharacter)
    
    -- Bind the hotkey (Q) to toggle the feature
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if _G.ScriptEnabled and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Keybind then
            toggleSpeedFeature()
        end
    end)
    
    -- Do not reset character immediately on script load, only when toggle is true
    if _G.ScriptEnabled then
        resetCharacter()
    end
    
    -- Bind RunService Heartbeat to continuously update speed
    RunService.Heartbeat:Connect(updateSpeed)
    
    -- Initialize the script for the current character
    initializeCharacter(character)
    
    -- Add KeyPicker for dynamic hotkey
    RightGroupBox:AddLabel('Keybind'):AddKeyPicker('KeyPicker', { 
        Default = 'Q', -- Initial keybind (can be changed)
        SyncToggleState = false,
        Mode = 'Toggle', -- Modes: Always, Toggle, Hold
        Text = 'Speed Toggle Keybind',
    
        Callback = function(Value)
            print('[cb] Keybind clicked!', Value)
        end,
    
        ChangedCallback = function(New)
            print('[cb] Keybind changed!', New)
            -- Update the hotkey to the new key selected
            Keybind = New
        end
    })
    
    -- Add Slider for emote duration
    RightGroupBox:AddSlider('EmoteDuration', {
        Text = 'Emote Duration (Seconds)',
        Default = 1.6,
        Min = 0,
        Max = 2.5,
        Rounding = 2,
        Compact = false,
    
        Callback = function(Value)
            print('[cb] Emote Duration changed! New value:', Value)
            emoteDuration = Value
        end
    })
    
    -- Add Slider for max speed
    RightGroupBox:AddSlider('MaxSpeed', {
        Text = 'Max Speed',
        Default = 300,
        Min = 16,
        Max = 1000, -- Adjust max limit as needed
        Rounding = 0,
        Compact = false,
    
        Callback = function(Value)
            print('[cb] Max Speed changed! New value:', Value)
            maxSpeed = Value
        end
    })
    
    -- Add Slider for speed increment
    RightGroupBox:AddSlider('SpeedIncrement', {
        Text = 'Speed Increment',
        Default = 1.75,
        Min = 0.1,
        Max = 10,
        Rounding = 2,
        Compact = false,
    
        Callback = function(Value)
            print('[cb] Speed Increment changed! New value:', Value)
            speedIncrement = Value
        end
    })    

    RightGroupBox = Tabs.Movement:AddRightGroupbox('Random Stuff') 

    -- Function to handle enabling/disabling the no jump cooldown feature
    local function toggleNoJumpCooldown(enabled)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    -- Helper function to update the humanoid's jump settings
    local function updateJumpSettings(humanoid, state)
        humanoid.UseJumpPower = not state -- Disable cooldown when `enabled` is true
        print("Jump cooldown " .. (state and "disabled!" or "enabled!"))
    end

    -- Apply the setting to the current humanoid
    updateJumpSettings(humanoid, enabled)

    -- Monitor for respawn and reapply the no jump cooldown setting if enabled
    player.CharacterAdded:Connect(function(newCharacter)
        local newHumanoid = newCharacter:WaitForChild("Humanoid")
        updateJumpSettings(newHumanoid, enabled)
    end)
    end

    -- Add a toggle to the UI
    RightGroupBox:AddToggle('NoJumpCooldownToggle', {
    Text = 'Toggle No Jump Cooldown',
    Default = false, -- Default value (true / false)
    Tooltip = 'Toggles the jump cooldown on or off', -- Information shown when you hover over the toggle

    Callback = function(value)
        -- Update the global state and toggle the feature
        _G.noJumpCooldownEnabled = value
        toggleNoJumpCooldown(value)
        print('[cb] NoJumpCooldownToggle changed to:', value)
    end
    })

    -- Optimized example: Instead of repeatedly using :FindFirstChild, store the result in a variable
    local part = workspace:FindFirstChild("MyPart")
    if part then
    -- Perform actions with the part
    print("Found part:", part.Name)
    end

    RightGroupBox = Tabs.Movement:AddRightGroupbox('Anti Slow')

    local gh = false -- Set to true to enable Anti-Slow, false to disable it.
    local debris = game:GetService("Debris") -- Access Debris service for cleanup
    local player = game.Players.LocalPlayer
    local toggleValue = false -- Store the current state of the toggle

    -- Replace the print statements with your NotifyLibrary.Notify call once it's defined
    local function notify(title, description)
    print(title .. ": " .. description)
    end

    -- Anti-slow logic that gets activated based on the toggle value
    local function antiSlowToggle(value)
    if value == true then
        gh = true

        -- Use RunService once and bind the logic only when enabled
        game:GetService('RunService'):BindToRenderStep("Anti-Slow", 0 , function()
            if player.Character then
                local bodyEffects = player.Character:WaitForChild("BodyEffects", 10)
                local movement = bodyEffects and bodyEffects:WaitForChild("Movement", 10)
                
                if movement then
                    -- Only check for the existence of these once and remove them if found
                    local noWalkSpeed = movement:FindFirstChild("NoWalkSpeed")
                    if noWalkSpeed then
                        noWalkSpeed:Destroy()
                    end
                    
                    local reduceWalk = movement:FindFirstChild("ReduceWalk")
                    if reduceWalk then
                        reduceWalk:Destroy()
                    end
                    
                    local noJumping = movement:FindFirstChild("NoJumping")
                    if noJumping then
                        noJumping:Destroy()
                    end
                end

                -- Use a more efficient way to check and modify the reload value
                if bodyEffects and bodyEffects.Reload and bodyEffects.Reload.Value == true then
                    bodyEffects.Reload.Value = false
                end
            end
        end)
    else
        gh = false

        -- Cleanup properly and unbind RunService
        game:GetService('RunService'):UnbindFromRenderStep("Anti-Slow")
    end
    end

    -- Integrate with the UI toggle, add it only once
    if not _G.AntiSlowToggle then
    RightGroupBox:AddToggle('MyToggle', {
        Text = 'Anti Slow',
        Default = false, -- Default value (true / false)
        Tooltip = 'Removes any kind of slowness', -- Information shown when you hover over the toggle

        Callback = function(Value)
            toggleValue = Value
            antiSlowToggle(Value)  -- Call the anti-slow function based on the toggle's value
        end
    })

    _G.AntiSlowToggle = true
    end

    -- Listen for character respawn and reapply the anti-slow system
    player.CharacterAdded:Connect(function()
    antiSlowToggle(toggleValue)  -- Reapply the toggle value after respawn
    end)

    -- Initial setup on first load
    if player.Character then
    antiSlowToggle(toggleValue)  -- Apply the anti-slow based on the current toggle state
    end

    RightGroupBox = Tabs.Misc:AddRightGroupbox('Hover UI')

    RightGroupBox:AddToggle('MyToggle', {
        Text = 'Hover UI',
        Default = false, -- Default value (true / false)
        Tooltip = 'Displays Player Stats when hover', -- Information shown when you hover over the toggle
        Callback = function(Value)
            --// Required services and variables
            local run_service = game:GetService("RunService")
            local tween_service = game:GetService("TweenService")
            local local_player = game.Players.LocalPlayer
            local playerGui = local_player:WaitForChild("PlayerGui")
            local mouse = local_player:GetMouse()
        
            -- Configuration flags
            local flags = {
                hover_ui_enabled = false,
            }
        
            -- Initialize UI elements once
            local screenGui, hoverFrame, avatarImage, healthLabel, armorLabel, healthBar, armorBar, whiteHealthBar, whiteArmorBar, playerNameLabel, ammoLabel
            local playerNameLabel, healthLabel, armorLabel, ammoLabel
        
            -- Store Enum values in variables
            local Enum_Font = Enum.Font.SourceSansBold
            local TextColorWhite = Color3.fromRGB(255, 255, 255)
            local BlackColor = Color3.fromRGB(0, 0, 0)
            local GrayColor = Color3.fromRGB(30, 30, 30)
        
            -- Ensure proper initialization and unloading
            if _G.hoverUIInitialized == nil then
                _G.hoverUIInitialized = false
            end
        
            if _G.hoverUIInitialized then
                flags.hover_ui_enabled = false
                _G.hoverUIInitialized = false
                if screenGui then
                    screenGui:Destroy()
                    screenGui = nil
                end
            else
                _G.hoverUIInitialized = true
        
                -- Initialize hover UI frame
                screenGui = Instance.new("ScreenGui", playerGui)
                screenGui.Name = "HoverUI"
                screenGui.ResetOnSpawn = false
        
                hoverFrame = Instance.new("Frame")
                hoverFrame.Size = UDim2.new(0, 300, 0, 140)
                hoverFrame.Position = UDim2.new(0.5, 0, 0.9, -50)
                hoverFrame.AnchorPoint = Vector2.new(0.5, 1)
                hoverFrame.BackgroundColor3 = GrayColor
                hoverFrame.BackgroundTransparency = 0
                hoverFrame.Visible = false
                hoverFrame.Parent = screenGui
                hoverFrame.BorderSizePixel = 3
                hoverFrame.BorderColor3 = BlackColor
        
                avatarImage = Instance.new("ImageLabel", hoverFrame)
                avatarImage.Size = UDim2.new(0, 100, 0, 100)
                avatarImage.Position = UDim2.new(0, 5, 0, 5)
                avatarImage.BackgroundTransparency = 1
                avatarImage.Image = ""
        
                -- Player Name Label
                playerNameLabel = Instance.new("TextLabel", hoverFrame)
                playerNameLabel.Size = UDim2.new(0, 200, 0, 30)
                playerNameLabel.Position = UDim2.new(0, 115, 0, 5)
                playerNameLabel.BackgroundTransparency = 1
                playerNameLabel.TextColor3 = TextColorWhite
                playerNameLabel.Font = Enum_Font
                playerNameLabel.TextSize = 20
                playerNameLabel.Text = "Player Name"
                playerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
                -- Health Bar
                healthBar = Instance.new("Frame", hoverFrame)
                healthBar.Size = UDim2.new(0, 175, 0, 30)
                healthBar.Position = UDim2.new(0, 115, 0, 35)
                healthBar.BackgroundColor3 = GrayColor
                healthBar.BorderSizePixel = 2
                healthBar.BorderColor3 = BlackColor
        
                whiteHealthBar = Instance.new("Frame", healthBar)
                whiteHealthBar.Size = UDim2.new(1, 0, 1, 0)
                whiteHealthBar.Position = UDim2.new(0, 0, 0, 0)
                whiteHealthBar.BackgroundColor3 = BlackColor
                whiteHealthBar.BorderSizePixel = 0
        
                healthLabel = Instance.new("TextLabel", healthBar)
                healthLabel.Size = UDim2.new(1, 0, 1, 0)
                healthLabel.Position = UDim2.new(0, 0, 0, 0)
                healthLabel.TextColor3 = TextColorWhite
                healthLabel.Font = Enum_Font
                healthLabel.TextSize = 23
                healthLabel.BackgroundTransparency = 1
                healthLabel.Text = "Health: 100"
                healthLabel.ZIndex = 2
        
                -- Armor Bar
                armorBar = Instance.new("Frame", hoverFrame)
                armorBar.Size = UDim2.new(0, 175, 0, 30)
                armorBar.Position = UDim2.new(0, 115, 0, 75)
                armorBar.BackgroundColor3 = GrayColor
                armorBar.BorderSizePixel = 2
                armorBar.BorderColor3 = BlackColor
        
                whiteArmorBar = Instance.new("Frame", armorBar)
                whiteArmorBar.Size = UDim2.new(1, 0, 1, 0)
                whiteArmorBar.Position = UDim2.new(0, 0, 0, 0)
                whiteArmorBar.BackgroundColor3 = BlackColor
                whiteArmorBar.BorderSizePixel = 0
        
                armorLabel = Instance.new("TextLabel", armorBar)
                armorLabel.Size = UDim2.new(1, 0, 1, 0)
                armorLabel.Position = UDim2.new(0, 0, 0, 0)
                armorLabel.TextColor3 = TextColorWhite
                armorLabel.Font = Enum_Font
                armorLabel.TextSize = 23
                armorLabel.BackgroundTransparency = 1
                armorLabel.Text = "Armor: 100"
                armorLabel.ZIndex = 2
        
                -- Ammo Label
                ammoLabel = Instance.new("TextLabel", hoverFrame)
                ammoLabel.Size = UDim2.new(0, 175, 0, 30)
                ammoLabel.Position = UDim2.new(0, 115, 0, 105)
                ammoLabel.BackgroundTransparency = 1
                ammoLabel.TextColor3 = TextColorWhite
                ammoLabel.Font = Enum_Font
                ammoLabel.TextSize = 23
                ammoLabel.Text = "Ammo: 0"
                ammoLabel.ZIndex = 2
        
                -- Function to update player name's text size
                local function UpdatePlayerNameSize(playerNameText)
                    local baseSize = 20
                    local textLength = #playerNameText
                    if textLength > 23 then
                        return baseSize - 12
                    elseif textLength > 17 then
                        return baseSize - 8
                    elseif textLength > 11 then
                        return baseSize - 4
                    end
                    return baseSize
                end
        
                -- Update hover UI
                local function UpdateHoverUI(player)
                    if not player or not player.Character then
                        hoverFrame.Visible = false
                        return
                    end
        
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if not humanoid then return end
        
                    -- Update avatar image
                    avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
                    playerNameLabel.Text = player.Name
                    playerNameLabel.TextSize = UpdatePlayerNameSize(player.Name)
        
                    -- Health and Health Bar
                    healthLabel.Text = "Health: " .. math.floor(humanoid.Health)
                    local healthPercentage = humanoid.Health / humanoid.MaxHealth
                    tween_service:Create(whiteHealthBar, TweenInfo.new(0.1), {Size = UDim2.new(healthPercentage, 0, 1, 0)}):Play()
        
                    -- Armor Percentage (maximum armor = 130)
                    local bodyEffects = player.Character:FindFirstChild("BodyEffects")
                    local armorValue = 0
                    if bodyEffects then
                        local armor = bodyEffects:FindFirstChild("Armor")
                        armorValue = armor and armor.Value or 0
                    end
        
                    -- Update armor label and bar with percentage
                    local maxArmor = 130
                    local armorPercentage = math.clamp(armorValue / maxArmor, 0, 1)
                    armorLabel.Text = "Armor: " .. math.floor(armorPercentage * 100) .. ""
                    tween_service:Create(whiteArmorBar, TweenInfo.new(0.1), {Size = UDim2.new(armorPercentage, 0, 1, 0)}):Play()
        
                    -- Ammo
                    local tool = player.Character:FindFirstChildWhichIsA("Tool")
                    if tool and tool:FindFirstChild("Ammo") then
                        ammoLabel.Text = "Ammo: " .. tool.Ammo.Value
                    else
                        ammoLabel.Text = "Ammo: 0"
                    end
        
                    hoverFrame.Visible = true
                end
        
                -- Get the player under the cursor
                local function GetHoveredPlayer()
                    local target = mouse.Target
                    if target and target:IsDescendantOf(workspace) then
                        local character = target:FindFirstAncestorWhichIsA("Model")
                        if character and character:FindFirstChild("Humanoid") then
                            return game.Players:GetPlayerFromCharacter(character)
                        end
                    end
                    return nil
                end
        
                -- Update hover UI on each frame
                run_service.RenderStepped:Connect(function()
                    if not _G.hoverUIInitialized then return end
                    local hoveredPlayer = GetHoveredPlayer()
                    if hoveredPlayer then
                        UpdateHoverUI(hoveredPlayer)
                    else
                        hoverFrame.Visible = false
                    end
                end)
            end
        end
    })    

    RightGroupBox = Tabs.Misc:AddRightGroupbox('Damage Numbers')

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local Camera = game.Workspace.CurrentCamera
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    RaycastParams.IgnoreWater = true

    -- Settings
    local font = Enum.Font.SourceSansBold
    local baseSize = 32
    local distance = 500 -- Maximum distance at which damage numbers will be visible
    local animationDuration = 3 -- Time it takes for the number to slowly move upwards
    local fadeDuration = 1 -- Time it takes for the number to fade away after floating
    local maxOffset = 20 -- Maximum random offset for damage numbers

    local isDamageNumbersEnabled = false  -- Toggle state for enabling/disabling damage numbers
    local damageColor = Color3.fromRGB(255, 255, 255)  -- Default red color for damage numbers

    -- Previous health of the nearest player
    local previousHealth = {}

    -- Function to check if a player is behind a wall
    local function isPlayerVisible(player)
        if not player.Character or not player.Character:FindFirstChild("Head") then return false end
        local head = player.Character.Head
        local origin = Camera.CFrame.Position
        local direction = (head.Position - origin).Unit * (head.Position - origin).Magnitude
        RaycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
        local result = workspace:Raycast(origin, direction, RaycastParams)
        return not result or result.Instance:IsDescendantOf(player.Character)
    end

    -- Function to get the player nearest to the cursor with visibility check
    local function getNearestToCursor()
        local mouseLocation = UserInputService:GetMouseLocation()
        local nearestPlayer
        local shortestDistance = math.huge

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and isPlayerVisible(player) then
                local head = player.Character.Head
                local screenPosition, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distanceToCursor = (Vector2.new(screenPosition.X, screenPosition.Y) - mouseLocation).Magnitude
                    if distanceToCursor < shortestDistance then
                        shortestDistance = distanceToCursor
                        nearestPlayer = player
                    end
                end
            end
        end
        return nearestPlayer
    end

    -- Function to create damage number display
    local function createDamageDisplay(player, damageAmount)
        if not isDamageNumbersEnabled then return end

        local head = player.Character and player.Character:FindFirstChild("Head")
        if head then
            local damageContainer = head:FindFirstChild("DamageContainer")
            if not damageContainer then
                damageContainer = Instance.new("BillboardGui")
                damageContainer.Name = "DamageContainer"
                damageContainer.Parent = head
                damageContainer.Adornee = head
                damageContainer.Size = UDim2.new(0, 100, 0, 50)
                damageContainer.StudsOffset = Vector3.new(0, 2, 0)
                damageContainer.AlwaysOnTop = true
                damageContainer.MaxDistance = distance
                damageContainer.Enabled = true
            end

            -- Create the new damage number label
            local textLabel = Instance.new("TextLabel")
            textLabel.Parent = damageContainer
            textLabel.Text = tostring(damageAmount)
            textLabel.TextColor3 = damageColor
            textLabel.TextSize = baseSize + (damageAmount / 10) -- Scale size based on damage
            textLabel.Font = font
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(1, 0, 0, baseSize)
            textLabel.TextStrokeTransparency = 0.4
            textLabel.Position = UDim2.new(0.5, -50 + math.random(-maxOffset, maxOffset), 0, math.random(-maxOffset, maxOffset)) -- Random offset

            -- Target position for the damage number to slowly move upwards
            local targetPosition = UDim2.new(0.5, -50, 0, -100) -- Final position for all damage numbers

            -- Create the upward movement tween
            local moveUpTween = TweenService:Create(
                textLabel, 
                TweenInfo.new(animationDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
                {Position = targetPosition}
            )

            -- Create the fade-out tween
            local fadeOutTween = TweenService:Create(
                textLabel,
                TweenInfo.new(fadeDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {TextTransparency = 1, TextStrokeTransparency = 1} -- Fade both text and stroke
            )

            -- Play the move-up tween
            moveUpTween:Play()

            -- Once the move-up animation is completed, start fading out
            moveUpTween.Completed:Connect(function()
                fadeOutTween:Play()

                -- Destroy the label after the fade-out is complete
                fadeOutTween.Completed:Connect(function()
                    textLabel:Destroy()
                end)
            end)
        end
    end

    -- Function to check and display damage numbers for the nearest player
    local function checkNearestPlayerDamage()
        local nearestPlayer = getNearestToCursor()

        if nearestPlayer and nearestPlayer.Character and nearestPlayer.Character:FindFirstChildOfClass("Humanoid") then
            local humanoid = nearestPlayer.Character:FindFirstChildOfClass("Humanoid")
            local currentHealth = humanoid.Health

            -- Get the previous health of the player, or set it to their current health if not tracked
            local prevHealth = previousHealth[nearestPlayer.UserId] or currentHealth

            -- If the player has lost health, display the damage number
            if currentHealth < prevHealth and isDamageNumbersEnabled then
                createDamageDisplay(nearestPlayer, math.floor(prevHealth - currentHealth))
            end

            -- Update the player's previous health
            previousHealth[nearestPlayer.UserId] = currentHealth
        end
    end

    -- Run every frame to check the nearest player's health
    RunService.RenderStepped:Connect(checkNearestPlayerDamage)

    -- Integrating UI Toggle for enabling/disabling damage numbers and Color Picker
    RightGroupBox:AddToggle('DamageNumbersToggle', {
        Text = 'Damage numbers',
        Default = false, -- Default value (false so it doesn't show on script execution)
        Tooltip = 'Shows damage dealt with numbers',
        Callback = function(Value)
            isDamageNumbersEnabled = Value
        end
    })

    RightGroupBox:AddLabel('Damage number color'):AddColorPicker('DamageColorPicker', {
        Default = damageColor, -- Default color for damage numbers
        Title = 'Damage Number Color', -- Title of the color picker
        Transparency = 0, -- Enable transparency control for the color picker
        Callback = function(Value)
            damageColor = Value
        end
    })

    Options.DamageColorPicker:OnChanged(function()
        print('Damage Number Color changed to:', Options.DamageColorPicker.Value)
    end)

    RightGroupBox = Tabs.Misc:AddRightGroupbox('Hit Sound')

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Camera = game.Workspace.CurrentCamera
    local RaycastParams = RaycastParams
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    RaycastParams.IgnoreWater = true
    
    -- Settings
    local soundOptions = {
        Ding = "rbxassetid://8578195318",
        Hitmarker = "rbxassetid://9116483270",
        Fortnite_Headshot = "rbxassetid://2513174484"
    }
    
    local currentHitSoundId = soundOptions.Ding  -- Default sound
    local soundVolume = 1  -- Volume of the hit sound
    local previousHealth = {}  -- Store previous health of players
    local isHitSoundEnabled = false  -- Default state of the hit sound toggle
    
    -- Function to check if a player is visible
    local function isPlayerVisible(player)
        local character = player.Character
        local head = character and character:FindFirstChild("Head")
        if not head then return false end
    
        local origin = Camera.CFrame.Position
        local direction = (head.Position - origin).Unit * (head.Position - origin).Magnitude
        RaycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
        local result = workspace:Raycast(origin, direction, RaycastParams)
        return not result or result.Instance:IsDescendantOf(character)
    end
    
    -- Function to get the nearest player to the cursor with visibility check
    local function getNearestToCursor()
        local mouseLocation = UserInputService:GetMouseLocation()
        local nearestPlayer, shortestDistance = nil, math.huge
    
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                local character = player.Character
                if character and character:FindFirstChild("Head") and isPlayerVisible(player) then
                    local head = character.Head
                    local screenPosition, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local distanceToCursor = (Vector2.new(screenPosition.X, screenPosition.Y) - mouseLocation).Magnitude
                        if distanceToCursor < shortestDistance then
                            shortestDistance = distanceToCursor
                            nearestPlayer = player
                        end
                    end
                end
            end
        end
    
        return nearestPlayer
    end
    
    -- Function to play the hit sound on the nearest player when they take damage
    local function playHitSound(player)
        if not isHitSoundEnabled then return end  -- Only proceed if the hit sound is enabled
    
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local currentHealth = humanoid.Health
            local prevHealth = previousHealth[player.UserId] or currentHealth
    
            -- If the player has lost health, play the hit sound
            if currentHealth < prevHealth then
                local sound = Instance.new("Sound")
                sound.SoundId = currentHitSoundId
                sound.Volume = soundVolume
                sound.Parent = player.Character:FindFirstChild("Head")
                sound:Play()
                sound.Ended:Connect(function()
                    sound:Destroy()
                end)
            end
    
            -- Update the player's previous health
            previousHealth[player.UserId] = currentHealth
        end
    end
    
    -- Run every frame to check the nearest player's health
    local function checkNearestPlayerDamage()
        local nearestPlayer = getNearestToCursor()
        if nearestPlayer then
            playHitSound(nearestPlayer)
        end
    end
    
    RunService.RenderStepped:Connect(checkNearestPlayerDamage)
    
    -- Toggle for enabling/disabling hit sound
    RightGroupBox:AddToggle('HitSoundsToggle', {
        Text = 'Hit Sounds',
        Default = false,  -- Default value (false so it doesn't play the sound initially)
        Tooltip = 'Plays a sound when a player takes damage',
        Callback = function(Value)
            isHitSoundEnabled = Value
        end
    })
    
    -- Dropdown for selecting hit sound, positioned under the toggle
    RightGroupBox:AddDropdown('SoundDropdown', {
        Values = { 'Ding', 'Hitmarker', 'Fortnite_Headshot' },
        Default = 1,
        Multi = false,
        Text = 'Select Hit Sound',
        Tooltip = 'Choose a sound to play when you hit players',
        Callback = function(Value)
            currentHitSoundId = soundOptions[Value]
        end
    })    

    RightGroupBox = Tabs.Misc:AddRightGroupbox('No Seats')

    local CollectionService = game:GetService("CollectionService")

    -- Table to cache seats
    local cachedSeats = {}

    -- Function to process a seat
    local function processSeat(seat, state)
    if seat:IsA("Seat") and not cachedSeats[seat] then
        cachedSeats[seat] = seat -- Cache the seat
    end
    if cachedSeats[seat] then
        seat.Disabled = state -- Update the state
        if state then
            CollectionService:AddTag(seat, "Seat")
        else
            CollectionService:RemoveTag(seat, "Seat")
        end
    end
    end

    -- Initialize cached seats
    local function initializeSeats()
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Seat") then
            cachedSeats[object] = object
        end
    end
    end

    -- Monitor new seats dynamically
    local function monitorNewSeats()
    workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Seat") then
            processSeat(descendant, CollectionService:HasTag(descendant, "Seat"))
        end
    end)
    end

    -- Integration with the toggle
    RightGroupBox:AddToggle('MyToggle', {
    Text = 'No Seats',
    Default = false, -- Default value
    Tooltip = 'Makes it so you cant sit down on anything', -- Tooltip info

    Callback = function(value)
        print('[cb] MyToggle changed to:', value)
        for seat, _ in pairs(cachedSeats) do
            if seat and seat:IsA("Seat") then
                seat.Disabled = value -- Update seat state
                if value then
                    CollectionService:AddTag(seat, "Seat")
                else
                    CollectionService:RemoveTag(seat, "Seat")
                end
            end
        end
    end
    })

    -- Initialize and start monitoring
    initializeSeats()
    monitorNewSeats()

RightGroupBox = Tabs.Misc:AddRightGroupbox('Auto Drop Cash')

    RightGroupBox:AddToggle('MyToggle', {
        Text = 'Auto Drop Cash',
        Default = false, -- Default value (true / false)
        Tooltip = 'Automatically drops cash', -- Information shown when you hover over the toggle
    
        Callback = function(Value)
            -- Locals
local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MainScreenGui = Player.PlayerGui.MainScreenGui
local MoneyText = MainScreenGui.MoneyText

-- Global variable to track Money Drop state
getgenv().moneyDropEnabled = getgenv().moneyDropEnabled or false -- Initialize as false if not already set

-- Function to safely extract the money amount from the text
local function getMoneyAmount()
    local moneyText = MoneyText.Text:match("%$(%d[%,%d]*)")  -- Extract the money amount after "$"
    if moneyText then
        local cleanedMoneyString = moneyText:gsub(",", "")  -- Remove commas
        local amount = tonumber(cleanedMoneyString)  -- Convert to number
        return amount or 0  -- If the conversion fails, return 0
    else
        return 0
    end
end

-- Function to drop money
local function dropMoney(amountToDrop)
    if amountToDrop > 0 then
        ReplicatedStorage.MainEvent:FireServer("DropMoney", tostring(amountToDrop))  -- Convert amount to string
    end
end

-- Function to enable or disable the money drop
local function toggleMoneyDrop()
    getgenv().moneyDropEnabled = not getgenv().moneyDropEnabled -- Toggle the state
end

-- Main loop (this will stop doing anything when moneyDropEnabled is false)
RunService.Heartbeat:Connect(function()
    if getgenv().moneyDropEnabled then
        local money = getMoneyAmount()  -- Get the current money amount
        dropMoney(money < 15000 and money or 15000)  -- Drop all money if under 15,000, or drop 15,000
    end
end)

-- Call this function to toggle the money drop
toggleMoneyDrop()  -- Toggle the money drop (enable or disable)
        end
    })
    

RightGroupBox = Tabs.Misc:AddRightGroupbox('Cash Aura')

    RightGroupBox:AddToggle('MyToggle', {
    Text = 'Cash Aura',
    Default = false, -- Default value (true / false)
    Tooltip = 'Automaticly picks up cash near you', -- Information shown when you hover over the toggle

    Callback = function(Value)
    -- Settings
    local Settings = {
    Max_Distance = 20 -- Max distance for collecting cash
    }

    -- Locals
    local Space = game:GetService("Workspace")
    local Player = game:GetService("Players").LocalPlayer
    local Camera = Space.CurrentCamera

    -- Global variable to track Cash Aura state
    getgenv().cashAuraEnabled = getgenv().cashAuraEnabled or false -- Initialize as false if not already set

    -- Function to send notifications
    local function sendNotification(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5 -- Default duration is 5 seconds
    })
    end

    -- Function to check if the player has anything equipped
    local function hasEquippedItem()
    -- Check if the player has a tool in the character's inventory (meaning it's equipped)
    return Player.Character and Player.Character:FindFirstChildOfClass("Tool") ~= nil
    end

    -- Function to collect money around the player
    local function getMoneyAroundMe()
    -- Do not collect money if the player has any tool equipped
    if hasEquippedItem() then
        return
    end

    for _, money in ipairs(game.Workspace.Ignored.Drop:GetChildren()) do
        if money.Name == "MoneyDrop" and money:FindFirstChild("ClickDetector") then
            local distance = (money.Position - Player.Character.HumanoidRootPart.Position).magnitude
            if distance <= Settings.Max_Distance then
                fireclickdetector(money.ClickDetector)
            end
        end
    end
    end

    -- Function to toggle the cash aura state
    local function toggleCashAura()
    getgenv().cashAuraEnabled = not getgenv().cashAuraEnabled -- Toggle the state
    if getgenv().cashAuraEnabled then
    end
    end

    -- Main loop (this will stop doing anything when cashAuraEnabled is false)
    spawn(function()
    while true do
        if getgenv().cashAuraEnabled then
            pcall(getMoneyAroundMe) -- Only collect money if the aura is enabled
        end
        wait(0.01) -- Repeat every 0.01 seconds
    end
    end)

    -- Call this function to toggle the cash aura
    toggleCashAura()  -- Toggle the cash aura (enable or disable)
    end
    })

RightGroupBox = Tabs.Misc:AddRightGroupbox('Reload')

        -- Cache commonly used services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")

-- Variables for tool and ammo
local tool
local ammoValue

-- Pool for animation connection
local animationConnection

-- Function to handle Auto Reload
local function handleAutoReload()
    tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")

    if tool and tool:FindFirstChild("Ammo") then
        ammoValue = tool.Ammo.Value
        if ammoValue <= 0 then
            MainEvent:FireServer("Reload", tool)
        end
    end
end

-- Function to handle Silent Reload setup (with animation stop)
local function setupSilentReload(Value)
    -- Check if the player has a character
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:WaitForChild("Humanoid")
        local targetAnimationId = "rbxassetid://2877910736"

        -- Stop any existing connections to Heartbeat
        if animationConnection then
            animationConnection:Disconnect()
        end

        -- Function to check and stop animation only when enabled
        if Value then
            local function checkAnimations()
                local playingAnimations = humanoid:GetPlayingAnimationTracks()
                for _, animationTrack in pairs(playingAnimations) do
                    local animation = animationTrack.Animation
                    if animation.AnimationId == targetAnimationId then
                        animationTrack:Stop()
                    end
                end
            end

            -- Reconnect the heartbeat listener if Silent Reload is enabled
            animationConnection = RunService.Heartbeat:Connect(checkAnimations)
        end
    end
end

-- Optimized AutoReload Toggle
RightGroupBox:AddToggle('AutoReloadToggle', {
    Text = 'Auto Reload',
    Default = false, -- Default value (true / false)
    Tooltip = 'Reloads Automatically when 0 ammo', -- Information shown when you hover over the toggle

    Callback = function(Value)
        _G.AutoReload = Value -- Set AutoReload based on the toggle state
    end
})

-- Silent Reload Toggle with animation cleanup
RightGroupBox:AddToggle('SilentReloadToggle', {
    Text = 'Silent Reload',
    Default = false, -- Default value (true / false)
    Tooltip = 'Reloads Silently', -- Information shown when you hover over the toggle

    Callback = function(Value)
        -- Apply the Silent Reload setup each time the toggle is changed
        setupSilentReload(Value)

        -- If the player dies and respawns, reset Silent Reload setup
        LocalPlayer.CharacterAdded:Connect(function()
            setupSilentReload(Value)
        end)
    end
})

-- Ensure auto reload is functioning right from the start if enabled
RunService.Heartbeat:Connect(function()
    if _G.AutoReload then
        handleAutoReload()
    end
end)

-- Cleanup function for removing unused objects or connections
local function cleanup()
    if animationConnection then
        animationConnection:Disconnect()
    end
end

-- Use Debris service for cleanup (if necessary in your context)
game:GetService("Debris"):AddItem(animationConnection, 5)

-- Ensure auto reload is functioning right from the start if enabled
RunService.Heartbeat:Connect(function()
    if _G.AutoReload then
        handleAutoReload()
    end
end)

RightGroupBox = Tabs.Misc:AddRightGroupbox('Auto Chatters')

-- List of Rizz lines
local Rizz = {
    "Are you a magician? Because whenever I look at you, everyone else disappears.",
    "Do you have a map? I keep getting lost in your eyes.",
    "Are you French? Because Eiffel for you.",
    "Are you a campfire? Because you’re hot and I want s’more.",
    "Do you have a Band-Aid? Because I just scraped my knee falling for you.",
    "Are you a time traveler? Because I see you in my future.",
    "Do you have a sunburn, or are you always this hot?",
    "Is your dad a boxer? Because you’re a knockout!",
    "Are you a snowstorm? Because you make my heart race.",
    "Can I follow you home? Cause my parents always told me to follow my dreams.",
    "Are you a camera? Because every time I look at you, I smile.",
    "Are you an angel? Because heaven is missing one.",
    "Is it hot in here or is it just you?",
    "Can you lend me a pencil? Because I want to draw a smile on your face.",
    "Do you know if there are any Wi-Fi signals around here? Because I’m feeling a connection.",
    "Is your name Chapstick? Because you’re da balm!",
    "Are you a dictionary? Because you add meaning to my life.",
    "Do you have a pencil? Because I want to erase your past and write our future.",
    "Do you have a quarter? Because I want to call my mom and tell her I met ‘The One’."
}

-- Services
TextChatService = game:GetService("TextChatService")
ReplicatedStorage = game:GetService("ReplicatedStorage")
Debris = game:GetService("Debris")

-- Toggle the script state
_G.rizzEnabled = false

RightGroupBox:AddToggle('MyToggle', {
    Text = 'Rizz chatter',
    Default = false, -- Default value (true / false)
    Tooltip = 'Rizzes up the shawtys', -- Information shown when you hover over the toggle
    
    Callback = function(Value)
        _G.rizzEnabled = Value
        
        if _G.rizzEnabled then
            -- Function to send a random Rizz line
            local function sendRandomRizz()
                local message = Rizz[math.random(#Rizz)] -- Choose a random line
                print("Sending rizz: " .. message)
                
                -- Chat system support (new and legacy)
                local chat = TextChatService.ChatInputBarConfiguration.TargetTextChannel
                
                if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
                    local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                    if chatEvent then
                        chatEvent.SayMessageRequest:FireServer(message, "All")
                    end
                elseif chat then
                    chat:SendAsync(message)
                else
                    print("Chat system not available.")
                end
            end
            
            -- Set up loop to send Rizz line every 3 seconds
            _G.rizzLoop = task.spawn(function()
                while _G.rizzEnabled do
                    sendRandomRizz()
                    task.wait(3) -- Wait 3 seconds before sending another line
                end
            end)
        else
            -- Stop the loop
            if _G.rizzLoop then
                task.cancel(_G.rizzLoop)
                _G.rizzLoop = nil
            end
        end
    end
})

RunService = game:GetService("RunService")
ReplicatedStorage = game:GetService("ReplicatedStorage")
TextChatService = game:GetService("TextChatService")
Toxic = {
    "EZ",
    "Bro doesn't know what aimlabs is",
    "SO EZ",
    "What are you aiming at, your dad?",
    "Bro doesn't have rizz",
    "Sigma who?",
    "storm trooper ahh"
}

ChatVersion = TextChatService.ChatVersion
ChatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
TargetTextChannel = TextChatService.ChatInputBarConfiguration.TargetTextChannel

function sendRandomToxic()
    message = Toxic[math.random(#Toxic)]
    print("Sending toxic: " .. message)
    
    if ChatVersion == Enum.ChatVersion.LegacyChatService and ChatEvent then
        ChatEvent.SayMessageRequest:FireServer(message, "All")
    elseif TargetTextChannel then
        TargetTextChannel:SendAsync(message)
    else
        print("Chat system not available.")
    end
end

local toxicConnection
isToxicChatting = false
function toggleToxicChat(enabled)
    _G.toxicEnabled = enabled
    
    if _G.toxicEnabled then
        if not toxicConnection then
            toxicConnection = RunService.Heartbeat:Connect(function()
                if isToxicChatting == false then
                    isToxicChatting = true
                    sendRandomToxic()
                    task.wait(3) -- Wait for 3 seconds before sending another message
                    isToxicChatting = false
                end
            end)
        end
    else
        if toxicConnection then
            toxicConnection:Disconnect()
            toxicConnection = nil
        end
    end
end

RightGroupBox:AddToggle('MyToggle', {
    Text = 'Toxic chatter',
    Default = false,
    Tooltip = 'Sends toxic chats',
    Callback = toggleToxicChat
})

RunService = game:GetService("RunService")
ReplicatedStorage = game:GetService("ReplicatedStorage")
TextChatService = game:GetService("TextChatService")
Promo = {
    "🎭Hexploit On Top🎭",
    "🎭Get Hexploit🎭",
    "🎭Hexploit Best Lock🎭",
    "🎭Hexploit Best Da Hood Script🎭",
    "🎭HexploitUI On Git🎭",
    "🎭Hexploit Keyless🎭",
    "🎭Hexploit Best AutoStomp🎭",
    "🎭Hexploit Best Animations🎭"
}

ChatVersion = TextChatService.ChatVersion
ChatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
TargetTextChannel = TextChatService.ChatInputBarConfiguration.TargetTextChannel

function sendRandomPromo()
    message = Promo[math.random(#Promo)]
    print("Sending Promo: " .. message)
    
    if ChatVersion == Enum.ChatVersion.LegacyChatService and ChatEvent then
        ChatEvent.SayMessageRequest:FireServer(message, "All")
    elseif TargetTextChannel then
        TargetTextChannel:SendAsync(message)
    else
        print("Chat system not available.")
    end
end

local PromoConnection
isPromoChatting = false
function togglePromoChat(enabled)
    _G.PromoEnabled = enabled
    
    if _G.PromoEnabled then
        if not PromoConnection then
            PromoConnection = RunService.Heartbeat:Connect(function()
                if isPromoChatting == false then
                    isPromoChatting = true
                    sendRandomPromo()
                    task.wait(5) -- Wait for 3 seconds before sending another message
                    isPromoChatting = false
                end
            end)
        end
    else
        if PromoConnection then
            PromoConnection:Disconnect()
            PromoConnection = nil
        end
    end
end

RightGroupBox:AddToggle('MyToggle', {
    Text = 'Promo chatter',
    Default = false,
    Tooltip = 'Sends Promo chats',
    Callback = togglePromoChat
})

RightGroupBox = Tabs.Misc:AddRightGroupbox('Animations pack')

MyButton = RightGroupBox:AddButton({
    Text = 'Animations Packs',
    Func = function()
        repeat
            wait()
        until game:IsLoaded() and game.Players.LocalPlayer.Character:FindFirstChild("FULLY_LOADED_CHAR") and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack") and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")
        
        local uiLoaded = false  -- Track whether the UI has been loaded
        local notificationShown = false  -- Track if the notification has been shown
        
        -- Function to load UI
        function loadUI()
            local player = game.Players.LocalPlayer
            local animationPack = player.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack")
            local animationPlusPack = player.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")
        
            -- Only load UI if it's not already loaded
            if animationPack and not animationPack.Visible then
                animationPack.Visible = true  -- Show AnimationPack UI
            end
        
            if animationPlusPack and not animationPlusPack.Visible then
                animationPlusPack.Visible = true  -- Show AnimationPlusPack UI
            end
        
            -- Set flag to indicate that UI is loaded
            uiLoaded = true
        end
        
        -- Function to unload UI
        function unloadUI()
            local player = game.Players.LocalPlayer
            local animationPack = player.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack")
            local animationPlusPack = player.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")
        
            -- Only unload UI if it's currently loaded
            if animationPack and animationPack.Visible then
                animationPack.Visible = false  -- Hide AnimationPack UI
            end
        
            if animationPlusPack and animationPlusPack.Visible then
                animationPlusPack.Visible = false  -- Hide AnimationPlusPack UI
            end
        
            -- Set flag to indicate that UI is unloaded
            uiLoaded = false
        end
        
        -- Function to show notification only once
        local function showNotificationOnce()
            if not notificationShown then
                -- Show the notification
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Script Loaded";
                    Text = "🎭  Hexploit 🎭";
                    Duration = 5;
                })
                notificationShown = false  -- Mark that the notification has been shown
            end
        end
        
        -- Trigger notification only once
        showNotificationOnce()
        
        -- Check if the UI is loaded or not and toggle appropriately
        if uiLoaded then
            unloadUI()  -- Unload the UI if it's already loaded
        else
            loadUI()  -- Load the UI if it's not loaded yet
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Lean") then
            game.ReplicatedStorage.ClientAnimations.Lean:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Lay") then
            game.ReplicatedStorage.ClientAnimations.Lay:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Dance1") then
            game.ReplicatedStorage.ClientAnimations.Dance1:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Dance2") then
            game.ReplicatedStorage.ClientAnimations.Dance2:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Greet") then
            game.ReplicatedStorage.ClientAnimations.Greet:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Chest Pump") then
            game.ReplicatedStorage.ClientAnimations["Chest Pump"]:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Praying") then
            game.ReplicatedStorage.ClientAnimations.Praying:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("TheDefault") then
            game.ReplicatedStorage.ClientAnimations.TheDefault:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Sturdy") then
            game.ReplicatedStorage.ClientAnimations.Sturdy:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Rossy") then
            game.ReplicatedStorage.ClientAnimations.Rossy:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Griddy") then
            game.ReplicatedStorage.ClientAnimations.Griddy:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("TPose") then
            game.ReplicatedStorage.ClientAnimations.TPose:Destroy()
        end
        
        if game.ReplicatedStorage.ClientAnimations:FindFirstChild("SpeedBlitz") then
            game.ReplicatedStorage.ClientAnimations.SpeedBlitz:Destroy()
        end
        
        local Animations = game.ReplicatedStorage.ClientAnimations
        
        local LeanAnimation = Instance.new("Animation", Animations)
        LeanAnimation.Name = "Lean"
        LeanAnimation.AnimationId = "rbxassetid://3152375249"
        
        local LayAnimation = Instance.new("Animation", Animations)
        LayAnimation.Name = "Lay"
        LayAnimation.AnimationId = "rbxassetid://3152378852"
        
        local Dance1Animation = Instance.new("Animation", Animations)
        Dance1Animation.Name = "Dance1"
        Dance1Animation.AnimationId = "rbxassetid://3189773368"
        
        local Dance2Animation = Instance.new("Animation", Animations)
        Dance2Animation.Name = "Dance2"
        Dance2Animation.AnimationId = "rbxassetid://3189776546"
        
        local GreetAnimation = Instance.new("Animation", Animations)
        GreetAnimation.Name = "Greet"
        GreetAnimation.AnimationId = "rbxassetid://3189777795"
        
        local ChestPumpAnimation = Instance.new("Animation", Animations)
        ChestPumpAnimation.Name = "Chest Pump"
        ChestPumpAnimation.AnimationId = "rbxassetid://3189779152"
        
        local PrayingAnimation = Instance.new("Animation", Animations)
        PrayingAnimation.Name = "Praying"
        PrayingAnimation.AnimationId = "rbxassetid://3487719500"
        
        local TheDefaultAnimation = Instance.new("Animation", Animations)
        TheDefaultAnimation.Name = "TheDefault"
        TheDefaultAnimation.AnimationId = "rbxassetid://11710529975" -- FIX THIS
        
        local SturdyAnimation = Instance.new("Animation", Animations)
        SturdyAnimation.Name = "Sturdy"
        SturdyAnimation.AnimationId = "rbxassetid://11710524717"
        
        local RossyAnimation = Instance.new("Animation", Animations)
        RossyAnimation.Name = "Rossy"
        RossyAnimation.AnimationId = "rbxassetid://11710527244"
        
        local GriddyAnimation = Instance.new("Animation", Animations)
        GriddyAnimation.Name = "Griddy"
        GriddyAnimation.AnimationId = "rbxassetid://11710529220"
        
        local TPoseAnimation = Instance.new("Animation", Animations)
        TPoseAnimation.Name = "TPose"
        TPoseAnimation.AnimationId = "rbxassetid://11710524200"
        
        local SpeedBlitzAnimation = Instance.new("Animation", Animations)
        SpeedBlitzAnimation.Name = "SpeedBlitz"
        SpeedBlitzAnimation.AnimationId = "rbxassetid://11710541744"
        
        function AnimationPack(Character)
            Character:WaitForChild'Humanoid'
            repeat
                wait()
            until game.Players.LocalPlayer.Character:FindFirstChild("FULLY_LOADED_CHAR") and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack") and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")
        
            local AnimationPack = game:GetService("Players").LocalPlayer.PlayerGui.MainScreenGui.AnimationPack
            local AnimationPackPlus = game:GetService("Players").LocalPlayer.PlayerGui.MainScreenGui.AnimationPlusPack
            local ScrollingFrame = AnimationPack.ScrollingFrame
            local CloseButton = AnimationPack.CloseButton
            local ScrollingFramePlus = AnimationPackPlus.ScrollingFrame
            local CloseButtonPlus = AnimationPackPlus.CloseButton
        
            local Lean = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(LeanAnimation)
        
            local Lay = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(LayAnimation)
        
            local Dance1 = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(Dance1Animation)
        
            local Dance2 = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(Dance2Animation)
        
            local Greet = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(GreetAnimation)
        
            local ChestPump = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(ChestPumpAnimation)
        
            local Praying = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(PrayingAnimation)
        
            local TheDefault = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(TheDefaultAnimation)
        
            local Sturdy = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(SturdyAnimation)
        
            local Rossy = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(RossyAnimation)
        
            local Griddy = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(GriddyAnimation)
        
            local TPose = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(TPoseAnimation)
        
            local SpeedBlitz = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(SpeedBlitzAnimation)
        
            AnimationPack.Visible = true
        
            AnimationPackPlus.Visible = true
        
            ScrollingFrame.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
            ScrollingFramePlus.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
            for i,v in pairs(ScrollingFrame:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Lean" then
                        v.Name = "LeanButton"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFrame:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Lay" then
                        v.Name = "LayButton"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFrame:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Dance1" then
                        v.Name = "Dance1Button"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFrame:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Dance2" then
                        v.Name = "Dance2Button"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFrame:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Greet" then
                        v.Name = "GreetButton"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFrame:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Chest Pump" then
                        v.Name = "ChestPumpButton"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFrame:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Praying" then
                        v.Name = "PrayingButton"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFramePlus:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "The Default" then
                        v.Name = "TheDefaultButton"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFramePlus:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Sturdy" then
                        v.Name = "SturdyButton"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFramePlus:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Rossy" then
                        v.Name = "RossyButton"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFramePlus:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Griddy" then
                        v.Name = "GriddyButton"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFramePlus:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "T Pose" then
                        v.Name = "TPoseButton"
                    end
                end
            end
        
            for i,v in pairs(ScrollingFramePlus:GetChildren()) do
                if v.Name == "TextButton" then
                    if v.Text == "Speed Blitz" then
                        v.Name = "SpeedBlitzButton"
                    end
                end
            end
        
            function Stop()
                Lean:Stop()
                Lay:Stop()
                Dance1:Stop()
                Dance2:Stop()
                Greet:Stop()
                ChestPump:Stop()
                Praying:Stop()
                TheDefault:Stop()
                Sturdy:Stop()
                Rossy:Stop()
                Griddy:Stop()
                TPose:Stop()
                SpeedBlitz:Stop()
            end
        
        
            local LeanTextButton = ScrollingFrame.LeanButton
            local LayTextButton = ScrollingFrame.LayButton
            local Dance1TextButton = ScrollingFrame.Dance1Button
            local Dance2TextButton = ScrollingFrame.Dance2Button
            local GreetTextButton = ScrollingFrame.GreetButton
            local ChestPumpTextButton = ScrollingFrame.ChestPumpButton
            local PrayingTextButton = ScrollingFrame.PrayingButton
            local TheDefaultTextButton = ScrollingFramePlus.TheDefaultButton
            local SturdyTextButton = ScrollingFramePlus.SturdyButton
            local RossyTextButton = ScrollingFramePlus.RossyButton
            local GriddyTextButton = ScrollingFramePlus.GriddyButton
            local TPoseTextButton = ScrollingFramePlus.TPoseButton
            local SpeedBlitzTextButton = ScrollingFramePlus.SpeedBlitzButton
        
            AnimationPack.MouseButton1Click:Connect(function()
                if ScrollingFrame.Visible == false then
                    ScrollingFrame.Visible = true
                    CloseButton.Visible = true
                    AnimationPackPlus.Visible = false
                end
            end)
            AnimationPackPlus.MouseButton1Click:Connect(function()
                if ScrollingFramePlus.Visible == false then
                    ScrollingFramePlus.Visible = true
                    CloseButtonPlus.Visible = true
                    AnimationPack.Visible = false
                end
            end)
            CloseButton.MouseButton1Click:Connect(function()
                if ScrollingFrame.Visible == true then
                    ScrollingFrame.Visible = false
                    CloseButton.Visible = false
                    AnimationPackPlus.Visible = true
                end
            end)
            CloseButtonPlus.MouseButton1Click:Connect(function()
                if ScrollingFramePlus.Visible == true then
                    ScrollingFramePlus.Visible = false
                    CloseButtonPlus.Visible = false
                    AnimationPack.Visible = true
                end
            end)
        
            LeanTextButton.MouseButton1Click:Connect(function()
                Stop()
                Lean:Play()
            end)
            LayTextButton.MouseButton1Click:Connect(function()
                Stop()
                Lay:Play()
            end)
            Dance1TextButton.MouseButton1Click:Connect(function()
                Stop()
                Dance1:Play()
            end)
            Dance2TextButton.MouseButton1Click:Connect(function()
                Stop()
                Dance2:Play()
            end)
            GreetTextButton.MouseButton1Click:Connect(function()
                Stop()
                Greet:Play()
            end)
            ChestPumpTextButton.MouseButton1Click:Connect(function()
                Stop()
                ChestPump:Play()
            end)
            PrayingTextButton.MouseButton1Click:Connect(function()
                Stop()
                Praying:Play()
            end)
            TheDefaultTextButton.MouseButton1Click:Connect(function()
                Stop()
                TheDefault:Play()
            end)
            SturdyTextButton.MouseButton1Click:Connect(function()
                Stop()
                Sturdy:Play()
            end)
            RossyTextButton.MouseButton1Click:Connect(function()
                Stop()
                Rossy:Play()
            end)
            GriddyTextButton.MouseButton1Click:Connect(function()
                Stop()
                Griddy:Play()
            end)
            TPoseTextButton.MouseButton1Click:Connect(function()
                Stop()
                TPose:Play()
            end)
            SpeedBlitzTextButton.MouseButton1Click:Connect(function()
                Stop()
                SpeedBlitz:Play()
            end)
        
            game:GetService("Players").LocalPlayer.Character.Humanoid.Running:Connect(function()
                Stop()
            end)
        
            game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
                Stop()
            end)
        end
        AnimationPack(game.Players.LocalPlayer.Character)
        game.Players.LocalPlayer.CharacterAdded:Connect(AnimationPack)
    end,
    DoubleClick = false,
    Tooltip = 'Gives you da hood animations packs'
})

RightGroupBox = Tabs.Misc:AddRightGroupbox('Player Animations')

    Players = game:GetService("Players")  -- Store the Players service in a variable
    player = Players.LocalPlayer  -- Store the LocalPlayer in a variable

    -- Base URL for the animation assets
    animationBaseUrl = "http://www.roblox.com/asset/?id="

    -- Table of animations with optimized base URL usage
    animations = {
    R15 = {
        idle = animationBaseUrl .. "2510196951",
        walk = animationBaseUrl .. "2510202577",
        run = animationBaseUrl .. "2510198475",
        jump = animationBaseUrl .. "2510197830",
        climb = animationBaseUrl .. "2510192778",
        fall = animationBaseUrl .. "2510195892",
    },
    Loser = {
        idle = animationBaseUrl .. "782841498",
        walk = animationBaseUrl .. "616168032",
        run = animationBaseUrl .. "616163682",
        jump = animationBaseUrl .. "1083218792",
        climb = animationBaseUrl .. "1083439238",
        fall = animationBaseUrl .. "707829716",
    },
    Astronaut = {
        idle = animationBaseUrl .. "891621366",
        jump = animationBaseUrl .. "891627522",
        fall = animationBaseUrl .. "891617961",
        walk = animationBaseUrl .. "891667138",
        run = animationBaseUrl .. "891636393",
        climb = animationBaseUrl .. "891609353",
    },
    Bubbly = {
        idle = animationBaseUrl .. "910004836",
        jump = animationBaseUrl .. "910016857",
        fall = animationBaseUrl .. "910001910",
        walk = animationBaseUrl .. "910034870",
        run = animationBaseUrl .. "910025107",
        climb = animationBaseUrl .. "940996062",
    },
    Cartoony = {
        idle = animationBaseUrl .. "742637544",
        jump = animationBaseUrl .. "742637942",
        fall = animationBaseUrl .. "742637151",
        walk = animationBaseUrl .. "742640026",
        run = animationBaseUrl .. "742638842",
        climb = animationBaseUrl .. "742636889",
    },
    Confident = {
        idle = animationBaseUrl .. "1069977950",
        jump = animationBaseUrl .. "1069984524",
        fall = animationBaseUrl .. "1069973677",
        walk = animationBaseUrl .. "1070017263",
        run = animationBaseUrl .. "1070001516",
        climb = animationBaseUrl .. "1069946257",
    },
    Cowboy = {
        idle = animationBaseUrl .. "1014390418",
        jump = animationBaseUrl .. "1014394726",
        fall = animationBaseUrl .. "1014384571",
        walk = animationBaseUrl .. "1014421541",
        run = animationBaseUrl .. "1014401683",
        climb = animationBaseUrl .. "1014380606",
    },
    Elder = {
        idle = animationBaseUrl .. "845397899",
        jump = animationBaseUrl .. "845398858",
        fall = animationBaseUrl .. "845396048",
        walk = animationBaseUrl .. "845403856",
        run = animationBaseUrl .. "845386501",
        climb = animationBaseUrl .. "845392038",
    },
    Knight = {
        idle = animationBaseUrl .. "657595757",
        jump = animationBaseUrl .. "658409194",
        fall = animationBaseUrl .. "657600338",
        walk = animationBaseUrl .. "657552124",
        run = animationBaseUrl .. "657564596",
        climb = animationBaseUrl .. "658360781",
    },
    Levitation = {
        idle = animationBaseUrl .. "616006778",
        jump = animationBaseUrl .. "616008936",
        fall = animationBaseUrl .. "616005863",
        walk = animationBaseUrl .. "616013216",
        run = animationBaseUrl .. "616010382",
        climb = animationBaseUrl .. "616003713",
    },
    Mage = {
        idle = animationBaseUrl .. "707742142",
        jump = animationBaseUrl .. "707853694",
        fall = animationBaseUrl .. "707829716",
        walk = animationBaseUrl .. "707897309",
        run = animationBaseUrl .. "707861613",
        climb = animationBaseUrl .. "707826056",
    },
    Ninja = {
        idle = animationBaseUrl .. "656117400",
        jump = animationBaseUrl .. "656117878",
        fall = animationBaseUrl .. "656115606",
        walk = animationBaseUrl .. "656121766",
        run = animationBaseUrl .. "656118852",
        climb = animationBaseUrl .. "656114359",
    },
    Patrol = {
        idle = animationBaseUrl .. "1149612882",
        jump = animationBaseUrl .. "1148811837",
        fall = animationBaseUrl .. "1148863382",
        walk = animationBaseUrl .. "1151231493",
        run = animationBaseUrl .. "1150967949",
        climb = animationBaseUrl .. "1148811837",
    },
    Pirate = {
        idle = animationBaseUrl .. "750781874",
        jump = animationBaseUrl .. "750782230",
        fall = animationBaseUrl .. "750780242",
        walk = animationBaseUrl .. "750785693",
        run = animationBaseUrl .. "750783738",
        climb = animationBaseUrl .. "750779899",
    },
    Popstar = {
        idle = animationBaseUrl .. "1212900985",
        jump = animationBaseUrl .. "1212954642",
        fall = animationBaseUrl .. "1212900995",
        walk = animationBaseUrl .. "1212980338",
        run = animationBaseUrl .. "1212980348",
        climb = animationBaseUrl .. "1213044953",
    },
    Princess = {
        idle = animationBaseUrl .. "941003647",
        jump = animationBaseUrl .. "941008832",
        fall = animationBaseUrl .. "941000007",
        walk = animationBaseUrl .. "941028902",
        run = animationBaseUrl .. "941015281",
        climb = animationBaseUrl .. "940996062",
    },
    Robot = {
        idle = animationBaseUrl .. "616088211",
        jump = animationBaseUrl .. "616090535",
        fall = animationBaseUrl .. "616087089",
        walk = animationBaseUrl .. "616095330",
        run = animationBaseUrl .. "616091570",
        climb = animationBaseUrl .. "616086039",
    },
    Sneaky = {
        idle = animationBaseUrl .. "1132473842",
        jump = animationBaseUrl .. "1132489853",
        fall = animationBaseUrl .. "1132469004",
        walk = animationBaseUrl .. "1132510133",
        run = animationBaseUrl .. "1132494274",
        climb = animationBaseUrl .. "1132461372",
    },
    Stylish = {
        idle = animationBaseUrl .. "616136790",
        jump = animationBaseUrl .. "616139451",
        fall = animationBaseUrl .. "616134815",
        walk = animationBaseUrl .. "616146177",
        run = animationBaseUrl .. "616140816",
        climb = animationBaseUrl .. "616133594",
    },
    Superhero = {
        idle = animationBaseUrl .. "616111295",
        jump = animationBaseUrl .. "616115533",
        fall = animationBaseUrl .. "616108001",
        walk = animationBaseUrl .. "616122287",
        run = animationBaseUrl .. "616117076",
        climb = animationBaseUrl .. "616104706",
    },
    Toy = {
        idle = animationBaseUrl .. "782841498",
        jump = animationBaseUrl .. "782847020",
        fall = animationBaseUrl .. "782846423",
        walk = animationBaseUrl .. "782843345",
        run = animationBaseUrl .. "782842708",
        climb = animationBaseUrl .. "782843869",
    },
    Vampire = {
        idle = animationBaseUrl .. "1083445855",
        jump = animationBaseUrl .. "1083455352",
        fall = animationBaseUrl .. "1083443587",
        walk = animationBaseUrl .. "1083473930",
        run = animationBaseUrl .. "1083462077",
        climb = animationBaseUrl .. "1083439238",
    },
    Werewolf = {
        idle = animationBaseUrl .. "1083195517",
        jump = animationBaseUrl .. "1083218792",
        fall = animationBaseUrl .. "1083189019",
        walk = animationBaseUrl .. "1083178339",
        run = animationBaseUrl .. "1083216690",
        climb = animationBaseUrl .. "1083182000",
    },
    Zombie = {
        idle = animationBaseUrl .. "616158929",
        jump = animationBaseUrl .. "616161997",
        fall = animationBaseUrl .. "616157476",
        walk = animationBaseUrl .. "616168032",
        run = animationBaseUrl .. "616163682",
        climb = animationBaseUrl .. "616156119",
    },
    RealisticZombie = {
        idle = animationBaseUrl .. "3489171152",
        jump = animationBaseUrl .. "616161997",
        fall = animationBaseUrl .. "616157476",
        walk = animationBaseUrl .. "3489174223",
        run = animationBaseUrl .. "3489173414",
        climb = animationBaseUrl .. "616156119", 
    },
    }

    -- Function to apply animations based on the selected preset
    local function applyAnimations(animate, preset)
    -- Ensure the animation IDs are applied correctly
    if animate and preset then
        if animate.idle and animate.idle:FindFirstChild("Animation1") then
            animate.idle.Animation1.AnimationId = preset.idle
        else
            warn("Idle animation or Animation1 not found")
        end
        
        if animate.walk and animate.walk:FindFirstChild("WalkAnim") then
            animate.walk.WalkAnim.AnimationId = preset.walk
        else
            warn("Walk animation or WalkAnim not found")
        end

        if animate.run and animate.run:FindFirstChild("RunAnim") then
            animate.run.RunAnim.AnimationId = preset.run
        else
            warn("Run animation or RunAnim not found")
        end

        if animate.jump and animate.jump:FindFirstChild("JumpAnim") then
            animate.jump.JumpAnim.AnimationId = preset.jump
        else
            warn("Jump animation or JumpAnim not found")
        end

        if animate.climb and animate.climb:FindFirstChild("ClimbAnim") then
            animate.climb.ClimbAnim.AnimationId = preset.climb
        else
            warn("Climb animation or ClimbAnim not found")
        end

        if animate.fall and animate.fall:FindFirstChild("FallAnim") then
            animate.fall.FallAnim.AnimationId = preset.fall
        else
            warn("Fall animation or FallAnim not found")
        end
    end
    end

    -- Function to apply the selected animation preset to the player's character
    local function applySelectedAnimations(character)
    -- Ensure the character has the Animate object
    local animate = character:FindFirstChild("Animate")
    if animate then
        local selectedPreset = animations[currentAnimationPreset]  -- Use the preset based on the dropdown
        applyAnimations(animate, selectedPreset)
    end
    end

    -- Set up the dropdown to choose which animation preset to apply
    RightGroupBox:AddDropdown('AnimationSelector', {
    Values = {'R15', 'Loser', 'Astronaut', 'Bubbly', 'Cartoony', 'Confident', 'Cowboy', 'Elder', 'Knight', 'Levitation', 'Mage', 'Ninja', 'Patrol', 'Pirate', 'Popstar', 'Princess', 'Robot', 'Sneaky', 'Stylish', 'Superhero', 'Toy', 'Vampire', 'Werewolf', 'Zombie', 'RealisticZombie'}, -- Add new presets here if needed
    Default = 1, -- Default option (R15)
    Multi = false, -- Allow single selection only

    Text = 'Select Animation',
    Tooltip = 'Choose the animation you want to apply',

    Callback = function(Value)
        currentAnimationPreset = Value  -- Update the preset based on the dropdown selection
    end
    })

    -- Connect to Heartbeat and apply the animation every frame
    game:GetService("RunService").Heartbeat:Connect(function()
    if player.Character then
        applySelectedAnimations(player.Character)  -- Apply the selected animation
    end
    end)

RightGroupBox = Tabs.Misc:AddRightGroupbox('Skin Changer')

MyButton = RightGroupBox:AddButton({
    Text = 'Skin Changer',
    Func = function()
        	-- rev sound rbxassetid://1583819337

	local InventoryChanger = { Functions = {}, Selected = {}, Skins = {}, Owned = {} };


	do
		local Utilities = {};

-- Define the notification function
    function ShowNotification(title, text)
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("SendNotification", {
            Title = title; -- Notification title
            Text = text; -- Notification message
            Duration = 5; -- Duration in seconds
        })
    end
    
    -- Define the custom print and notification function
    function cout(watermark, message)
        -- Print the message in the console
        print('['..watermark..'] DH skin changer made by affeboy')
        
        -- Show the notification
        ShowNotification("Skin Changer Loading", "Skibidi Changer")
    end
    
    -- Example usage
    cout("Skibidi Changer")           

		if not getgenv().InventoryConnections then
			getgenv().InventoryConnections = {};
		end;

		local players = game:GetService('Players');
		local client = players.LocalPlayer;

		local tween_service = game:GetService('TweenService');

		Utilities.AddConnection = function(signal, func)
			local connect = signal:Connect(func);

			table.insert(getgenv().InventoryConnections, { signal = signal, func = func, connect = connect });
			return connect;
		end;

		Utilities.Unload = function()
			for _, tbl in ipairs(getgenv().InventoryConnections) do
				if type(tbl) ~= 'table' then 
					tbl:Disconnect();
				end
			end;

			getgenv().InventoryConnections = {};
		end;

		Utilities.Unload();

		Utilities.Tween = function(args)
			local obj = args.obj or args.object;
			local prop = args.prop or args.properties;
			local duration = args.duration or args.time;
			local info = args.info or args.tween_info;
			local callback = args.callback;

			local tween = tween_service:Create(obj, duration and TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) or info and TweenInfo.new(unpack(info)), prop);
			tween:Play();

			if callback then
				tween.Completed:Connect(callback);
			end;
		end;

		repeat task.wait() until client.Character:FindFirstChild('FULLY_LOADED_CHAR');

		local player_gui = client.PlayerGui;

		local main_gui = player_gui:WaitForChild('MainScreenGui');
		local crew = main_gui:WaitForChild('Crew');
		local bottom_left = crew:WaitForChild('BottomLeft').Frame;
		local skins_button = bottom_left:WaitForChild('Skins');

		local replicated_storage = game:GetService('ReplicatedStorage');
		local skin_modules = replicated_storage:WaitForChild('SkinModules');
		local meshes = skin_modules:WaitForChild('Meshes');

		local weapon_skins_gui = main_gui:WaitForChild('WeaponSkinsGUI');
		local gui_body_wrapper = weapon_skins_gui:WaitForChild('Body');
		local body_wrapper = gui_body_wrapper:WaitForChild('Wrapper');
		local skin_view = body_wrapper:WaitForChild('SkinView');
		local skin_view_frame = skin_view:WaitForChild('Frame');

		local guns = skin_view_frame:WaitForChild('Guns').Contents;
		local entries = skin_view_frame:WaitForChild('Skins').Contents.Entries;

		local Ignored = workspace.Ignored;
		local Siren = Ignored.Siren;
		local Radius = Siren.Radius;

		local regex = '%[(.-)%]';

		local newColorSequence = ColorSequence.new;
		local Color3fromRGB = Color3.fromRGB;
		local newCFrame = CFrame.new;
		local newColorSequenceKeypoint = ColorSequenceKeypoint.new;

		InventoryChanger.Skins = {
			['Aqua'] = {
				color = newColorSequence(Color3fromRGB(38, 96, 255)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Aqua.rev,
						equipped = false,
						shoot_sound = 'rbxassetid://77877805688791',
						C0 = newCFrame(-0.105384827, 0.208259106, 0.00799560547, 1, -5.87381323e-27, 0, -5.87381323e-27, 1, 0, 0, 0, 1)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.Aqua.db,
						equipped = false,
						shoot_sound = 'rbxassetid://137783932140587',
						C0 = newCFrame(0.204410553, 0.268578529, 0.0223999023, -1.00000572, 2.90278896e-27, 0, -2.90275526e-27, 0.999988556, 0, 0, 0, -0.999994278)
					},
					['RPG'] = {
						location = meshes.Aqua.rpg,
						equipped = false,
						shoot_sound = 'rbxassetid://136641811532905',
						C0 = newCFrame(-0.0422363281, 0.243108392, -0.243370056, -4.37113883e-08, 1.79695434e-18, -1, -5.64731205e-13, 1, -1.7722692e-18, 1, -5.64731205e-13, -4.37113883e-08)
					}
				}
			},
			['Arcade'] = {
				color = newColorSequence(Color3fromRGB(193, 92, 5)),
				guns = {
					['Revolver'] = {
						location = meshes.Arcade.Rev,
						equipped = false,
						shoot_sound = 'rbxassetid://110368146859788',
						C0 = newCFrame(0.0578613281, -0.0479719043, -0.00115966797, -1.00000405, 1.15596135e-16, 1.64267286e-30, -1.15596135e-16, 1, 2.99751983e-14, 1.66683049e-30, -2.99751983e-14, -1.00000405)
					},
					['Double-Barrel SG'] = {
						location = meshes.Arcade.DB,
						equipped = false,
						shoot_sound = 'rbxassetid://110368146859788',
						C0 = newCFrame(0.0578613281, -0.0479719043, -0.00115966797, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					}
				}
			},
			['Barbie'] = {
				guns = {
					['Revolver'] = {
						location = meshes.Barbie.Revol,
						equipped = false,
						C0 = newCFrame(0.0218505859, -0.0277693868, 0.0029296875, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['Double-Barrel SG'] = {
						location = meshes.Barbie.db,
						equipped = false,
						C0 = newCFrame(0.0457763672, 0.0508109927, 0.000579833984, -1, 0, 0, 0, 1, 0, 0, 0, -1)
					},
					['[RPG]'] = {
						location = meshes.Barbie.rpg,
						equipped = false,
						C0 = newCFrame(-0.0417480469, 0.253171682, 1.63067627, 4.37113883e-08, 3.46944654e-18, 1, -4.00865674e-13, 1, 3.48696912e-18, -1, 4.00865674e-13, 4.37113883e-08)
					},
					['[Flamethrower]'] = {
						location = meshes.Barbie.FT,
						equipped = false,
						C0 = newCFrame(-0.450744629, -0.232652962, 0.0798339844, -1, 0, 0, 0, 1, 0, 0, 0, -1)
					}
				}
			},
			['Butterfly'] = {
				color = newColorSequence(Color3fromRGB(255, 112, 236)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Butterfly.Rev,
						equipped = false,
						shoot_sound = 'rbxassetid://135313010828275',
						C0 = newCFrame(0.0578613281, -0.0479719043, -0.00115966797, -1.00000405, 1.15596135e-16, 1.64267286e-30, -1.15596135e-16, 1, 2.99751983e-14, 1.66683049e-30, -2.99751983e-14, -1.00000405)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.Butterfly.DB,
						equipped = false,
						shoot_sound = 'rbxassetid://91190443400371',
						C0 = newCFrame(0.36031723, 0.00864857435, -0.00158691406, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					}
				}
			},
		['CandyCane'] = {
			color = newColorSequence({newColorSequenceKeypoint(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.25, Color3.new(1, 0, 0)), ColorSequenceKeypoint.new(0.50, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.75, Color3.new(1, 0, 0)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))}),
				guns = {
					['[Revolver]'] = {
						location = meshes.CandyCane.Rev,
						equipped = false,
						shoot_sound = 'rbxassetid://134944277318607',
						C0 = newCFrame(0.3, -0.0479719043, -0.00115966797, -1.00000405, 1.15596135e-16, 1.64267286e-30, -1.15596135e-16, 1, 2.99751983e-14, 1.66683049e-30, -2.99751983e-14, -1.00000405)
					},
				}
			},
			['PrestigeCandyCane'] = {
				color = newColorSequence({newColorSequenceKeypoint(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.25, Color3.new(0.5, 0, 0.5)), ColorSequenceKeypoint.new(0.50, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.75, Color3.new(0.5, 0, 0.5)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))}),
					guns = {
						['[Revolver]'] = {
							location = meshes.CandyCane.PrestigeRev,
							equipped = false,
							shoot_sound = 'rbxassetid://134944277318607',
							C0 = newCFrame(0.3, -0.0479719043, -0.00115966797, -1.00000405, 1.15596135e-16, 1.64267286e-30, -1.15596135e-16, 1, 2.99751983e-14, 1.66683049e-30, -2.99751983e-14, -1.00000405)
						},
					}
				},
			['Cat'] = {
				color = newColorSequence(Color3fromRGB(247, 129, 255)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Cat.Rev,
						equipped = false,
						shoot_sound = 'rbxassetid://18544605344',
						C0 = newCFrame(-0.0353851318, 0.0917409062, -0.001953125, 1, 0, 0, 0, 1, -3.25059848e-30, 0, -3.25059848e-30, 1)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.Cat.db,
						equipped = false,
						shoot_sound = 'rbxassetid://18544603790',
						C0 = newCFrame(-0.321357727, -0.021577239, -0.000366210938, -1, 0, 0, 0, 1, -3.25059773e-30, 0, 3.25059773e-30, -1)
					},
					['[Drum-Shotgun]'] = {
						location = meshes.Cat.drum,
						equipped = false,
						shoot_sound = 'rbxassetid://18544602257',
						C0 = newCFrame(-0.0637664795, 0.164270639, 0.00408935547, -1, 1.62920685e-07, 1.79568244e-22, 1.62920685e-07, 1, -2.44927253e-16, 1.99519584e-23, -2.44929794e-16, -1)
					},
					['RPG'] = {
						location = meshes.Cat.rpg,
						equipped = false,
						shoot_sound = 'rbxassetid://18544610124',
						C0 = newCFrame(-0.0182495117, 0.288909316, -0.0680465698, -4.37113883e-08, 4.54747351e-13, -1, 0.00000192143443, 1, -5.3873594e-13, 1, 0.00000192143443, -4.37113883e-08)
					}
				}
			},
			['Hoodmas'] = {
				guns = {
					['Revolver'] = {
						location = meshes.Hoodmas.revolver,
						equipped = false,
						C0 = newCFrame(0.00862121582, -0.000740110874, -0.0009765625, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					}
				}
			},
			['Ice'] = {
				guns = {
					['Revolver'] = {
						location = meshes.Ice.rev,
						equipped = false,
						C0 = newCFrame(-0.0299072266, 0.0293902755, -0.0108032227, 1, 0, 0, 0, 0, 1, 0, -1, 0)
					}
				}
			},
			['Iced Out'] = {
				guns = {
					['Revolver'] = {
						location = meshes.IcedOut.rev,
						equipped = false,
						C0 = newCFrame(-0.0419578552, -0.0496253371, -0.0009765625, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					}
				}
			},
			['Cupid'] = {
				color = newColorSequence(Color3fromRGB(255, 187, 239)),
				guns = {
					['Revolver'] = {
					location = meshes.Cupid.rev,
					equipped = false,
					shoot_sound = 'rbxassetid://16288431925',
					C0 = newCFrame(0.0240020752, 0.229963183, -0.0170898438, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
					['Double-Barrel SG'] = {
						location = meshes.Cupid.db,
						equipped = false,
						shoot_sound = 'rbxassetid://16288431925',
						C0 = newCFrame(-0.0375976562, 0.048615396, 0.00555419922, 0, 0, 1, 0, 0.999998212, 0, -1, 0, 0)
					}
				}
			},
			['Emerald'] = {
				color = newColorSequence(Color3fromRGB(0, 255, 0)),
				guns = {
					['Revolver'] = {
						location = meshes.Emerald.Rev,
						equipped = false,
						shoot_sound = 'rbxassetid://119530007559356',
						C0 = newCFrame(0.200012207, -0.0815875828, 0.0110473633, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
				}
			},
			['Etheral'] = {
				color = newColorSequence(Color3fromRGB(255, 0, 255)),
				guns = {
					['Revolver'] = {
						location = meshes.Etheral.Rev,
						equipped = false,
						shoot_sound = 'rbxassetid://15399809021',
						C0 = newCFrame(0.0255432129, -0.0427106023, 0.0140380859, -1, 0, 0, 0, 1, 0, 0, 0, -1)
					},
				}
			},
			['Grumpy'] = {
				color = newColorSequence(Color3fromRGB(0, 255, 42)),
				guns = {
					['Revolver'] = {
						location = meshes.Grumpy.rev,
						equipped = false,
						shoot_sound = 'rbxassetid://78903650873779',
						C0 = newCFrame(0.083902359, -0.000752657652, -0.00531005859, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
				}
			},
			['Web-Hero'] = {
				color = newColorSequence(Color3fromRGB(255, 255, 255)),
				guns = {
					['Revolver'] = {
						location = meshes.HERO.HeroWeb,
						equipped = false,
						shoot_sound = 'rbxassetid://13814390550',
						C0 = newCFrame(-0.0891418457, -0.0215809345, -0.0041809082, -1.99520325e-23, -1.62920685e-07, 1, 2.44929371e-16, 1, 1.62920685e-07, -1, 2.44929371e-16, 1.99520294e-23)
					}
				}
			},
			
			['Mystical'] = {
				color = newColorSequence(Color3fromRGB(255, 39, 24)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Mystical.Revolver,
						equipped = false,
						shoot_sound = 'rbxassetid://14489866118',
						C0 = newCFrame(-0.015838623, -0.0802496076, 0.00772094727, 1, 0, 4.37113883e-08, 0, 1, 0, -4.37113883e-08, 0, 1)
					},
				}
			},
			['CyanPack'] = {
				mesh_location = meshes.CyanPack,
				guns = {
					['[TacticalShotgun]'] = {
						location = meshes.CyanPack.Cloud,
						equipped = false,
						shoot_sound = 'rbxassetid://14056055126',
						C0 = newCFrame(0.0441589355, -0.0269355774, -0.000701904297, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.CyanPack.DB,
						equipped = false,
						shoot_sound = 'rbxassetid://14056053588',
						C0 = newCFrame(-0.00828552246, 0.417651355, -0.00537109375, 4.18358377e-06, -1.62920685e-07, 1, 3.4104116e-13, 1, 1.62920685e-07, -1, 3.41041052e-13, -4.18358377e-06)
					},
					['[Revolver]'] = {
						location = meshes.CyanPack.Devil,
						equipped = false,
						shoot_sound = 'rbxassetid://14056056444',
						C0 = newCFrame(0.0185699463, 0.293397784, -0.00256347656, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					}
				}
			},
			['Cartoon'] = {
				color = newColorSequence(Color3fromRGB(99, 234, 255)),            
				guns = {
					['[Flamethrower]'] = {
						location = meshes.Cartoon.CartoonFT,
						equipped = false,
						C0 = newCFrame(-0.272186279, 0.197086751, 0.0440063477, -1, 4.8018768e-07, 8.7078952e-08, 4.80187623e-07, 1, -3.54779985e-07, -8.70791226e-08, -3.54779957e-07, -1)
					},
					['[Revolver]'] = {
						location = meshes.Cartoon.CartoonRev,
						equipped = false,
						shoot_sound = 'rbxassetid://14221101923',
						C0 = newCFrame(-0.015411377, 0.0135096312, 0.00338745117, 1.00000095, 3.41326549e-13, 2.84217399e-14, 3.41326549e-13, 1.00000191, -9.89490712e-10, 2.84217399e-14, -9.89490712e-10, 1.00000191)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.Cartoon.DBCartoon,
						equipped = false,
						shoot_sound = 'rbxassetid://14220912852',
						C0 = newCFrame(0.00927734375, -0.00691050291, 0.000732421875, -1, -2.79396772e-08, -9.31322797e-10, -2.79396772e-08, 1, 1.42607872e-08, 9.31322575e-10, 1.42607872e-08, -1)
					},
					['[RPG]'] = {
						location = meshes.Cartoon.RPGCartoon,
						equipped = false,
						C0 = newCFrame(-0.0201721191, 0.289476752, -0.0727844238, 4.37113883e-08, 6.58276836e-37, 1, -5.72632016e-14, 1, 2.50305399e-21, -1, 5.72632016e-14, 4.37113883e-08)
					},
				}
			},
			['Dragon'] = {
				color = newColorSequence(Color3.new(1, 0, 0)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Dragon.DragonRev,
						equipped = false,
						shoot_sound = 'rbxassetid://14217797127',
						C0 = newCFrame(0.0384216309, 0.0450432301, -0.000671386719, 1.87045402e-31, 4.21188801e-16, -0.99999994, 1.77635684e-15, 1, -4.21188827e-16, 1, 1.77635684e-15, -1.87045413e-31)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.Dragon.DBDragon,
						equipped = false,
						C0 = newCFrame(-0.123794556, 0.0481165648, 0.00048828125, 7.14693442e-07, 3.13283705e-10, 1, -4.56658222e-09, 1, -3.13281678e-10, -1, -4.56658533e-09, 7.14693442e-07)
					}
				}
			},
			['Tact'] = {
				color = newColorSequence(Color3.new(1, 0.3725490196, 0.3725490196)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Tact.Rev,
						equipped = false,
						shoot_sound = 'rbxassetid://13850086195',
						C0 = newCFrame(-0.318634033, -0.055095911, 0.00491333008, 0, 0, 1, 0, 1, 0, -1, 0, 0)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.Tact.DB,
						equipped = false,
						shoot_sound = 'rbxassetid://13988900457',
						C0 = newCFrame(-0.0701141357, -0.0506889224, -0.0826416016, 0, 0, 1, 0, 1, 0, -1, 0, 0)
					},
					['[TacticalShotgun]'] = {
						location = meshes.Tact.Tact,
						equipped = false,
						shoot_sound = 'rbxassetid://13850091297',
						C0 = newCFrame(-0.0687713623, -0.0684046745, 0.12701416, 0, 0, 1, 0, 1, 0, -1, 0, 0)
					},
					['[SMG]'] = {
						location = meshes.Tact.Uzi,
						equipped = false,
						shoot_sound = 'rbxassetid://13850089197',
						C0 = newCFrame(0.0408782959, 0.0827783346, -0.0423583984, -1, 0, 0, 0, 1, 0, 0, 0, -1)
					},
					['[Shotgun]'] = {
						location = meshes.Tact.Shotgun,
						equipped = false,
						shoot_sound = 'rbxassetid://13988901716',
						C0 = newCFrame(-0.0610046387, 0.171100497, -0.00495910645, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[Silencer]'] = {
						location = meshes.Tact.Silencer,
						equipped = false,
						shoot_sound = 'rbxassetid://13850087044',
						C0 = newCFrame(0.0766601562, -0.0350288749, -0.648864746, 1, 0, -4.37113883e-08, 0, 1, 0, 4.37113883e-08, 0, 1)
					}
				}
			},
			['Shadow'] = {
				color = newColorSequence(Color3.new(0.560784, 0.470588, 1), Color3.new(0.576471, 0.380392, 1)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Shadow.RevolverGhost,
						equipped = false,
						C0 = newCFrame(1.52587891e-05, 0, 0, 1, 0, 8.74227766e-08, 0, 1, 0, -8.74227766e-08, 0, 1)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.Shadow.DoubleBGhost,
						equipped = false,
						C0 = newCFrame(0.0250015259, -0.077037394, 0, 1, 0, 0, 0, 0.999998331, 0, 0, 0, 1)
					},
					['[AK47]'] = {
						location = meshes.Shadow.AK47Ghost,
						equipped = false,
						C0 = newCFrame(-0.750015259, 4.76837158e-07, -3.05175781e-05, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[SilencerAR]'] = {
						location = meshes.Shadow.ARGhost,
						equipped = false,
						C0 = newCFrame(0.116256714, 0.0750004649, 6.10351562e-05, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[AUG]'] = {
						location = meshes.Shadow.AUGGhost,
						equipped = false,
						C0 = newCFrame(-7.62939453e-06, 0.0499991775, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[DrumGun]'] = {
						location = meshes.Shadow.DrumgunGhost,
						equipped = false,
						C0 = newCFrame(1.14440918e-05, 0, 0, 1, 0, 8.74227766e-08, 0, 1, 0, -8.74227766e-08, 0, 1)
					},
					['[Flamethrower]'] = {
						location = meshes.Shadow.FlamethrowerGhost,
						equipped = false,
						C0 = newCFrame(-0.219947815, 0.339559376, 0.000274658203, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[Glock]'] = {
						location = meshes.Shadow.GlockGhost,
						equipped = false,
						C0 = newCFrame(0, 0, -0.200004578, 1, 0, 4.37113883e-08, 0, 1, 0, -4.37113883e-08, 0, 1)
					},
					['[LMG]'] = {
						location = meshes.Shadow.LMGGhost,
						equipped = false,
						C0 = newCFrame(0.374502182, -0.25, -0.25, -1, 0, -1.31134158e-07, 0, 1, 0, 1.31134158e-07, 0, -1)
					},
					['[P90]'] = {
						location = meshes.Shadow.P90Ghost,
						equipped = false,
						C0 = newCFrame(6.86645508e-05, 0.000218153, 3.05175781e-05, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[RPG]'] = {
						location = meshes.Shadow.RPGGhost,
						equipped = false,
						C0 = newCFrame(0.000122070312, 0.0625389814, 0.00672149658, 1, 0, -8.74227766e-08, 5.00610797e-21, 1, 5.72632016e-14, 8.74227766e-08, 5.72632016e-14, 1)
					},
					['[Rifle]'] = {
						location = meshes.Shadow.RifleGhost,
						equipped = false,
						C0 = newCFrame(0.000244140625, -0.100267321, -9.15527344e-05, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[SMG]'] = {
						location = meshes.Shadow.SMGGhost,
						equipped = false,
						C0 = newCFrame(-1.14440918e-05, 1.78813934e-07, -0.0263671875, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[Shotgun]'] = {
						location = meshes.Shadow.ShotgunGhost,
						equipped = false,
						C0 = newCFrame(3.05175781e-05, 0.199999928, 3.81469727e-06, -1, 0, -4.37113883e-08, 0, 1, 0, 4.37113883e-08, 0, -1)
					},
					['[TacticalShotgun]'] = {
						location = meshes.Shadow.TacticalShotgunGhost,
						equipped = false,
						C0 = newCFrame(-0.148262024, 0, 0, 1, 0, 8.74227766e-08, 0, 1, 0, -8.74227766e-08, 0, 1)
					}
				}
			},
			['Golden Age'] = {
				color = newColorSequence(Color3.fromHSV(0.89166666666, 0.24, 1)),
				guns = {
					['[Revolver]'] = {
						location = meshes.GoldenAge.Revolver,
						equipped = false,
						C0 = newCFrame(0.0295257568, 0.0725820661, -0.000946044922, 1, -4.89858741e-16, -7.98081238e-23, 4.89858741e-16, 1, 3.2584137e-07, -7.98081238e-23, -3.2584137e-07, 1),
						shoot_sound = 'rbxassetid://1898322396'
					},
					['[Double-Barrel SG]'] = {
						location = meshes.GoldenAge['Double Barrel'],
						equipped = false,
						shoot_sound = 'rbxassetid://4915503055',
						C0 = newCFrame(-0.00664520264, 0.0538104773, 0.0124816895, -1, 4.89858741e-16, 7.98081238e-23, 4.89858741e-16, 1, 3.2584137e-07, 7.98081238e-23, 3.2584137e-07, -1)
					}
				}
			},
			['Red Skull'] = {
				color = newColorSequence({newColorSequenceKeypoint(0, Color3.new(1, 0, 0)), ColorSequenceKeypoint.new(0.25, Color3.new(1, 0, 0)), ColorSequenceKeypoint.new(0.50, Color3.new(0, 0, 0)), ColorSequenceKeypoint.new(0.75, Color3.new(1, 0, 0)), ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))}),
				guns = {
					['[Revolver]'] = {
						location = meshes.RedSkull.RedSkullRev,
						equipped = false,
						shoot_sound = 'rbxassetid://13487882844',
						C0 = newCFrame(-0.0043258667, 0.0084195137, -0.00238037109, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
					['[Shotgun]'] = {
						location = meshes.RedSkull.RedSkullShotgun,
						equipped = false,
						C0 = newCFrame(-0.00326538086, 0.0239292979, -0.039352417, -4.37113883e-08, 0, -1, 0, 1, 0, 1, 0, -4.37113883e-08)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.RedSkull.RedSkullDB,
						equipped = false,
						C0 = newCFrame(-0.0143432617, -0.151709318, 0.00820922852, -1, 0, 0, 0, 1, 0, 0, 0, -1)
					},
					['[RPG]'] = {
						location = meshes.RedSkull.RedSkullRPG,
						equipped = false,
						shoot_sound = 'rbxassetid://12222095',
						C0 = newCFrame(-0.00149536133, 0.254377961, 0.804840088, -1, 0, 4.37113883e-08, -2.50305399e-21, 1, -5.72632016e-14, -4.37113883e-08, 5.72632016e-14, -1)
					}
				}
			},
			--[[['Galaxy'] = {
				border_color = newColorSequence(Color3.new(0, 0, 1)),
				particle = {
					properties = {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.new(0.419608, 0.376471, 1)),
							ColorSequenceKeypoint.new(1, Color3.new(0.419608, 0.376471, 1))
						}),
						Name = 'Galaxy',
						Size = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0.5),
							NumberSequenceKeypoint.new(0.496, 1.2),
							NumberSequenceKeypoint.new(1, 0.5)
						}),
						Squash = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.173364, 0.525),
							NumberSequenceKeypoint.new(0.584386, -1.7625),
							NumberSequenceKeypoint.new(0.98163, 0.0749998),
							NumberSequenceKeypoint.new(1, 0)
						}),
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.107922, 1),
							NumberSequenceKeypoint.new(0.391504, 0.25),
							NumberSequenceKeypoint.new(0.670494, 0.78125),
							NumberSequenceKeypoint.new(0.845006, 0),
							NumberSequenceKeypoint.new(1, 1)
						}),
						Texture = 'rbxassetid://7422600824',
						ZOffset = 1,
						LightEmission = 0.7,
						Lifetime = NumberRange.new(1, 1),
						Rate = 3,
						Rotation = NumberRange.new(0, 360),
						RotSpeed = NumberRange.new(0, 15),
						Speed = NumberRange.new(1, 1),
						SpreadAngle = Vector2.new(-45, 45)
					}
				},
				guns = {
					['[Revolver]'] = {
						texture = 'rbxassetid://9370936730'
					},
					['[TacticalShotgun]'] = {
						texture = 'rbxassetid://9402279010'
					}
				}
			},]]
			['Kitty'] = {
				color = newColorSequence(Color3.new(1, 0.690196, 0.882353), Color3.new(1, 0.929412, 0.964706)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Kitty.KittyRevolver,
						equipped = false,
						shoot_sound = 'rbxassetid://13483022860',
						C0 = newCFrame(0.0310440063, 0.0737591386, 0.0226745605, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[Flamethrower]'] = {
						location = meshes.Kitty.KittyFT,
						equipped = false,
						C0 = newCFrame(-0.265670776, 0.115545571, 0.00997924805, -1, 9.74078034e-21, 5.47124086e-13, 9.74092898e-21, 1, 3.12638804e-13, -5.47126309e-13, 3.12638804e-13, -1)
					},
					['[RPG]'] = {
						location = meshes.Kitty.KittyRPG,
						equipped = false,
						C0 = newCFrame(0.0268554688, 0.0252066851, 0.117408752, -1, 2.51111284e-40, 4.37113883e-08, -3.7545812e-20, 1, -8.58948004e-13, -4.37113883e-08, 8.58948004e-13, -1)
					},
					['[Shotgun]'] = {
						location = meshes.Kitty.KittyShotgun,
						equipped = false,
						shoot_sound = 'rbxassetid://13483035672',
						C0 = newCFrame(0.0233459473, 0.223892093, -0.0213623047, 4.37118963e-08, -6.53699317e-13, 1, 3.47284736e-20, 1, 7.38964445e-13, -0.999997139, 8.69506734e-21, 4.37119354e-08)
					}
				}
			},
			['Toy'] = {
				mesh_location = meshes.Toy,
				color = newColorSequence({newColorSequenceKeypoint(0, Color3.new(0, 1, 0)), ColorSequenceKeypoint.new(0.5, Color3.new(0.666667, 0.333333, 1)), ColorSequenceKeypoint.new(1, Color3.new(1, 0.666667, 0))}),
				guns = {
					['[Revolver]'] = {
						location = meshes.Toy.RevolverTOY,
						equipped = false,
						shoot_sound = 'rbxassetid://13613387797',
						C0 = newCFrame(-0.0250854492, -0.144362092, -0.00266647339, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[LMG]'] = {
						location = meshes.Toy.LMGTOY,
						equipped = false,
						shoot_sound = 'rbxassetid://13613391426',
						C0 = newCFrame(-0.285247803, -0.0942560434, -0.270412445, 1, 0, 4.37113883e-08, 0, 1, 0, -4.37113883e-08, 0, 1)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.Toy.DBToy,
						equipped = false,
						shoot_sound = 'rbxassetid://13613388954',
						C0 = newCFrame(-0.0484313965, -0.00164616108, -0.0190467834, -1, 0, 0, 0, 1, 0, 0, 0, -1)
					},
					['[RPG]'] = {
						location = meshes.Toy.RPGToy,
						equipped = false,
						shoot_sound = 'rbxassetid://13613389876',
						C0 = newCFrame(0.00121307373, 0.261434197, -0.318969727, 1, 2.5768439e-12, -4.37113883e-08, 2.57684412e-12, 1, 6.29895225e-12, 4.37113883e-08, 6.29895225e-12, 1)
					}
				}
			},
			['Galactic'] = {
				color = newColorSequence(Color3fromRGB(255, 0, 0)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Galactic.galacticRev,
						equipped = false,
						shoot_sound = 'rbxassetid://13633362452',
						C0 = newCFrame(-0.049041748, 0.0399398208, -0.00772094727, 0, 0, 1, 0, 1, 0, -1, 0, 0)
					},
					['[TacticalShotgun]'] = {
						location = meshes.Galactic.TacticalGalactic,
						equipped = false,
						C0 = newCFrame(-0.0411682129, -0.0281000137, 0.00103759766, 0, 5.68434189e-14, 1, -1.91456822e-13, 1, 5.68434189e-14, -1, 1.91456822e-13, 0)
					}
				}
			},
			['Water'] = {
				color = newColorSequence(Color3.new(0, 1, 1), Color3.new(0.666667, 1, 1)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Water.WaterGunRevolver,
						equipped = false,
						shoot_sound = 'rbxassetid://13814989290',
						C0 = newCFrame(-0.0440063477, 0.028675437, -0.00469970703, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
					['[TacticalShotgun]'] = {
						location = meshes.Water.TactWater,
						equipped = false,
						shoot_sound = 'rbxassetid://13814991449',
						C0 = newCFrame(0.0238037109, -0.00912904739, 0.00485229492, 0, 0, 1, 0, 1, 0, -1, 0, 0)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.Water.DBWater,
						equipped = false,
						shoot_sound = 'rbxassetid://13814990235',
						C0 = newCFrame(-0.0710754395, 0.00169920921, -0.0888671875, 0, 0, 1, 0, 1, 0, -1, 0, 0)
					},
					['[Flamethrower]'] = {
						location = meshes.Water.FTWater,
						equipped = false,
						C0 = newCFrame(0.0941314697, 0.593509138, 0.0191040039, -1, 0, 0, 0, 1, 0, 0, 0, -1)
					}
				}
			},
			['GPO'] = {
				color = newColorSequence(Color3.new(1, 0.666667, 0)),
				guns = {
					['[RPG]'] = {
						location = meshes.GPO.Bazooka,
						equipped = false,
						C0 = newCFrame(-0.0184631348, 0.0707798004, 0.219360352, 4.37113883e-08, 1.07062025e-23, 1, -5.75081297e-14, 1, 1.14251725e-36, -1, 5.70182736e-14, 4.37113883e-08)
					},
					['[TacticalShotgun]'] = {
						location = meshes.GPO.MaguTact,
						equipped = false,
						shoot_sound = 'rbxassetid://13998711419',
						C0 = newCFrame(-0.282501221, 0.0472121239, -0.0065612793, -6.60624482e-06, 1.5649757e-08, -1, -5.68434189e-14, 1, -1.56486806e-08, 1, 5.68434189e-14, -6.60624482e-06)
					},
					['[Rifle]'] = {
						location = meshes.GPO.Rifle,
						equipped = false,
						C0 = newCFrame(-0.208007812, 0.185256913, 0.000610351562, -3.37081539e-14, 1.62803403e-07, -1.00000012, -8.74227695e-08, 0.999999881, 1.63036205e-07, 1, 8.74227766e-08, -1.94552524e-14)
					}
				}
			},
			['GPOII'] = {
				color = newColorSequence(Color3.new(0.0, 0.502, 1.0), Color3.new(1, 1, 1)),
				guns = {
					['[Double-Barrel SG]'] = {
						location = meshes.GPOII.DB,
						equipped = false,
						shoot_sound = 'rbxassetid://98362382710844',
						C0 = newCFrame(0.15, -0.0815875828, 0.0110473633, 1, 0, 0, 0, 1, 0, 0, 0, -1)
					},            
				}
			},

			['BIT8'] = {
				color = newColorSequence(Color3.fromHSV(0.5, 0.9, 1)),
				guns = {
					['[Revolver]'] = {
						location = meshes.BIT8.RPixel,
						equipped = false,
						shoot_sound = 'rbxassetid://13326584088',
						C0 = newCFrame(0.0261230469, -0.042888701, 0.00260925293, -1, 1.355249e-20, -3.55271071e-15, 1.355249e-20, 1, -1.81903294e-27, 3.55271071e-15, -1.81903294e-27, -1)
					},
					['[Flamethrower]'] = {
						location = meshes.BIT8.FTPixel,
						equipped = false,
						C0 = newCFrame(-0.0906066895, -0.0161985159, -0.0117645264, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.BIT8.DBPixel,
						equipped = false,
						shoot_sound = 'rbxassetid://13326578563',
						C0 = newCFrame(-0.240386963, -0.127295256, -0.00776672363, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
					['[RPG]'] = {
						location = meshes.BIT8.RPGPixel,
						equipped = false,
						C0 = newCFrame(0.0102081299, 0.0659624338, 0.362945557, 4.37113883e-08, 0, 1, -5.72632016e-14, 1, 2.50305399e-21, -1, 5.72632016e-14, 4.37113883e-08)
					}
				}
			},
			['Electric'] = {
				color = newColorSequence(Color3fromRGB(0, 234, 255)),
				guns = {
					['[Revolver]'] = {
						location = meshes.Electric.ElectricRevolver,
						equipped = false,
						C0 = newCFrame(0.185462952, 0.0312761068, 0.000610351562, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
					['[DrumGun]'] = {
						location = meshes.Electric.ElectricDrum,
						equipped = false,
						C0 = newCFrame(-0.471969604, 0.184426308, 0.075378418, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[SMG]'] = {
						location = meshes.Electric.ElectricSMG,
						equipped = false,
						C0 = newCFrame(-0.0620956421, 0.109580457, 0.00729370117, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[Shotgun]'] = {
						location = meshes.Electric.ElectricShotgun,
						equipped = false,
						C0 = newCFrame(6.10351562e-05, 0.180232108, -0.624732971, 1, 0, -4.37113883e-08, 0, 1, 0, 4.37113883e-08, 0, 1)
					},
					['[Rifle]'] = {
						location = meshes.Electric.ElectricRifle,
						equipped = false,
						C0 = newCFrame(0.181793213, -0.0415201783, 0.00421142578, 1.8189894e-12, 6.6174449e-24, 1, 7.27595761e-12, 1, 6.6174449e-24, -1, -7.27595761e-12, -1.8189894e-12)
					},
					['[P90]'] = {
						location = meshes.Electric.ElectricP90,
						equipped = false,
						C0 = newCFrame(0.166191101, -0.225557804, -0.0075378418, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[LMG]'] = {
						location = meshes.Electric.ElectricLMG,
						equipped = false,
						C0 = newCFrame(0.142379761, 0.104723871, -0.303771973, -1, 0, -4.37113883e-08, 0, 1, 0, 4.37113883e-08, 0, -1)
					},
					['[Flamethrower]'] = {
						location = meshes.Electric.ElectricFT,
						equipped = false,
						C0 = newCFrame(-0.158782959, 0.173444271, 0.00640869141, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[Double-Barrel SG]'] = {
						location = meshes.Electric.ElectricDB,
						equipped = false,
						C0 = newCFrame(0.0755996704, -0.0420352221, 0.00543212891, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[Glock]'] = {
						location = meshes.Electric.ElectricGlock,
						equipped = false,
						C0 = newCFrame(-0.00207519531, 0.0318723917, 0.0401077271, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
					['[AUG]'] = {
						location = meshes.Electric.ElectricAUG,
						equipped = false,
						C0 = newCFrame(0.331085205, -0.0117390156, 0.00155639648, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[SilencerAR]'] = {
						location = meshes.Electric.ElectricAR,
						equipped = false,
						C0 = newCFrame(-0.16942215, 0.0508521795, 0.0669250488, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[AK47]'] = {
						location = meshes.Electric.ElectricAK,
						equipped = false,
						C0 = newCFrame(0.155792236, 0.18423444, 0.00140380859, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					}
				}
			},
			['Halloween23'] = {
				color = newColorSequence(Color3fromRGB(255, 85, 88)),
				guns = {
					['[Revolver]'] = {
						equipped = false,
						location = meshes.Halloween.Rev,
						shoot_sound = 'rbxassetid://14924285721',
						C0 = newCFrame(-0.0257873535, -0.0117108226, -0.00671386719, -1, 0, 0, 0, 1, 0, 0, 0, -1)
					},
					['[Double-Barrel SG]'] = {
						equipped = false,
						location = meshes.Halloween.DB,
						shoot_sound = 'rbxassetid://14924282919',
						C0 = newCFrame(-0.00271606445, -0.0485508144, 0.000732421875, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					},
					['[Shotgun]'] = {
						equipped = false,
						location = meshes.Halloween.SG,
						shoot_sound = 'rbxassetid://14924268000',
						C0 = newCFrame(0.00573730469, 0.294590235, -0.115814209, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
					['[TacticalShotgun]'] = {
						equipped = false,
						location = meshes.Halloween.Tact,
						shoot_sound = 'rbxassetid://14924256223',
						C0 = newCFrame(-0.0715637207, -0.0843618512, 0.00582885742, -1, 0, 0, 0, 1, 0, 0, 0, -1)
					}
				}
			},
			['Soul'] = {
			color = newColorSequence({newColorSequenceKeypoint(0, Color3.new(1, 0, 0)), ColorSequenceKeypoint.new(0.5, Color3.new(0.7, 0.3, 0.1)), ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))}),
				guns = {
					['[Revolver]'] = {
						equipped = false,
						location = meshes.Soul.rev,
						shoot_sound = 'rbxassetid://14909152822',
						C0 = CFrame.new(-0.0646362305, 0.2725088, -0.00242614746, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
					['[Double-Barrel SG]'] = {
						equipped = false,
						location = meshes.Soul.db,
						shoot_sound = 'rbxassetid://14909164664',
						C0 = CFrame.new(0.405822754, 0.0975035429, -0.00506591797, -1, 0, 0, 0, 1, 0, 0, 0, -1)
					},
					['[TacticalShotgun]'] = {
						equipped = false,
						location = meshes.Soul.tact,
						shoot_sound = 'rbxassetid://14918188609',
						C0 = CFrame.new(-0.347473145, 0.0268714428, 0.00553894043, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					}
				}
			},        
			['Heaven'] = {
				color = newColorSequence(Color3.new(1, 1, 1)),
				guns = {
					['[Revolver]'] = {
						equipped = false,
						location = meshes.Heaven.Revolver,
						shoot_sound = 'rbxassetid://14489857436',
						C0 = newCFrame(-0.0829315186, -0.0831851959, -0.00296020508, -0.999999881, 2.94089277e-17, 8.27179774e-25, -2.94089277e-17, 0.999999881, 6.85215614e-16, 8.27179922e-25, -6.85215667e-16, -1)
					},
					['[Double-Barrel SG]'] = {
						equipped = false,
						location = meshes.Heaven.DB,
						shoot_sound = 'rbxassetid://14489852879',
						C0 = newCFrame(-0.0303955078, 0.022110641, 0.00296020508, -0.999997139, -7.05812226e-16, 7.85568618e-30, 7.05812226e-16, 0.999997139, -2.06501178e-14, 6.44518474e-30, 2.06501042e-14, -0.999999046)
					}
				}
			},
			['Void'] = {
				color = newColorSequence(Color3fromRGB(93, 0, 255)),
				guns = {
					['[Revolver]'] = {
						equipped = false,
						location = meshes.Void.rev,
						shoot_sound = 'rbxassetid://14756584250',
						C0 = newCFrame(-0.00503540039, 0.0082899332, -0.00164794922, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
					['[TacticalShotgun]'] = {
						equipped = false,
						location = meshes.Void.tact,
						C0 = newCFrame(0.0505371094, -0.0487936139, 0.00158691406, 0, 0, 1, 0, 1, 0, -1, 0, 0)
					}
				}
			},
			['DH-Stars II'] = {
				color = newColorSequence(Color3.new(1, 0.749, 0), Color3.new(0.9843, 1, 0)),
				guns = {
					['[Revolver]'] = {
						equipped = false,
						location = meshes.Popular.STARSREV,
						shoot_sound ='rbxassetid://14489869355',
						C0 = newCFrame(0.0578613281, -0.0479719043, -0.00115966797, -1.00000405, 1.15596135e-16, 1.64267286e-30, -1.15596135e-16, 1, 2.99751983e-14, 1.66683049e-30, -2.99751983e-14, -1.00000405)
					}
				}
			},
			['DH-Verified'] = {
				color = newColorSequence(Color3.new(0, 0.2157, 1), Color3.new(0, 0.4314, 1)),
				guns = {
					['[Revolver]'] = {
						equipped = false,
						location = meshes.Popular.VERIFIEDREV,
						shoot_sound =  'rbxassetid://14489870949',
						C0 = newCFrame(0.049407959, -0.0454721451, 0.00158691406, -1, 0, 0, 0, 1, 2.22044605e-15, 0, -2.22044605e-15, -1)
					}
				}
			},
			['Candy'] = {
				color = newColorSequence(Color3fromRGB(210, 160, 255)),
				guns = {
					['[Revolver]'] = {
						equipped = false,
						location = meshes.Candy.RevolverCandy,
						shoot_sound = 'rbxassetid://14723119555',
						C0 = newCFrame(-0.106658936, -0.0681198835, 0.00198364258, 0, 0, -1, 0, 1, 0, 1, 0, 0)
					},
					['[Double-Barrel SG]'] = {
						equipped = false,
						location = meshes.Candy.DBCandy,
						shoot_sound = 'rbxassetid://14723117395',
						C0 = newCFrame(0.0430603027, -0.0375298262, -0.00198364258, 0, 0, 1, 0, 1, 0, -1, 0, 0)
					},
					['LMG'] = {
						equipped = false,
						location = meshes.Candy.LMG,
						shoot_sound = 'rbxassetid://14748185495',
						C0 = newCFrame (0.125213623, -0.30771935, -0.0625305176, -4.37113883e-08, 0, 1, 0, 1, 0, -1, 0, -4.37113883e-08)
					}
				}
			}
		};

		mkelement = function(class, parent, props)
			local obj = Instance.new(class);

			for i, v in next, props do
				obj[i] = v;
			end;

			obj.Parent = parent;
			return obj;
		end;

		find_gun = (function(gun_name, instance)
			for i, v in next, instance:GetChildren() do
				if v:IsA('Tool') then
					if (v.Name == gun_name) then
						return v
					end
				end
			end
		end);

		InventoryChanger.Functions.GameEquip = function(gun, skin)
			return replicated_storage.MainEvent:FireServer('EquipWeaponSkins', gun, skin);
		end;

		InventoryChanger.Functions.AddOwnedSkins = function()
			for _, v in ipairs(entries:GetChildren()) do
				local ext_name = v.Name:match('%[(.-)%]');
				local skin_name, _ = v.Name:gsub('%[.-%]', '');
				if 
					ext_name 
					and skin_name 
					and InventoryChanger.Skins[skin_name] 
					and InventoryChanger.Skins[skin_name].guns 
					and InventoryChanger.Skins[skin_name].guns['[' .. ext_name .. ']']
				then
					local Preview = v:FindFirstChild('Preview');

					if Preview and Preview:FindFirstChild('Equipped') and Preview.Equipped.Visible then
						table.insert(InventoryChanger.Owned, { frame = v, gun = '[' .. ext_name .. ']' })
					end;
				end;
			end;
		end;

		InventoryChanger.Functions.UnequipGameSkins = function()
			for _, v in ipairs(InventoryChanger.Owned) do
				local SkinInfo = v.frame.SkinInfo;
				local Container = SkinInfo.Container;
				local SkinName = Container.SkinName.Text;

				InventoryChanger.Functions.GameEquip(v.gun, SkinName)
			end;
		end;

		InventoryChanger.Functions.Unload = function()
			return Utilities.Unload();
		end;

		InventoryChanger.Functions.Reload = function()
			local function wait_for_child(parent, child)
				local child = parent:WaitForChild(child);
				while not child do
					child = parent:WaitForChild(child);
				end;
				return child;
			end;
			
			client = players.LocalPlayer;
			player_gui = client.PlayerGui;

			repeat task.wait() until player_gui;

			main_gui = wait_for_child(player_gui, 'MainScreenGui');
			crew = wait_for_child(main_gui, 'Crew');

			bottom_left = wait_for_child(crew, 'BottomLeft');
			bottom_left = bottom_left.Frame;

			skins_button = wait_for_child(bottom_left, 'Skins');

			weapon_skins_gui = wait_for_child(main_gui, 'WeaponSkinsGUI');
			
			gui_body_wrapper = wait_for_child(weapon_skins_gui, 'Body');
			body_wrapper = wait_for_child(gui_body_wrapper, 'Wrapper');
			
			skin_view = wait_for_child(body_wrapper, 'SkinView');
			skin_view_frame = wait_for_child(skin_view, 'Frame');

			guns = wait_for_child(skin_view_frame, 'Guns').Contents;
			entries = wait_for_child(skin_view_frame, 'Skins').Contents.Entries;

			InventoryChanger.Functions.Unload();

			print ('Skins Loaded');
            ShowNotification("Loaded Open Skins", "Skibidi Changer")

			wait_for_child(entries, '[Revolver]Golden Age');
			InventoryChanger.Functions.AddOwnedSkins();
			InventoryChanger.Functions.UnequipGameSkins();

			for i, v in next, guns:GetChildren() do
				if v:IsA('Frame') and v.Name ~= 'GunEntry' and v.Name ~= 'Trading' and v.Name ~= '[Mask]' then
					Utilities.AddConnection(v.Button.MouseButton1Click, function()
						local extracted_name = v.Name:match(regex);
						if extracted_name then
							InventoryChanger.Functions.Start(extracted_name);
						end;
					end);
				end;
			end;
		end;

		InventoryChanger.Functions.Equip = function(gun_name, skin_name)
			print('[DEBUG]', 'Equip function has been invoked.', gun_name, skin_name or 'Default')
			local gun = find_gun(gun_name, client.Backpack) or find_gun(gun_name, client.Character);
			if not skin_name then
				if gun and gun.Name == gun_name then
					for _, v in next, gun.Default:GetChildren() do v:Destroy() end;
					
					gun.Default.Transparency = 0;
					--if InventoryChanger.Selected[gun.Name] and not InventoryChanger.Skins[InventoryChanger.Selected[gun.Name]].Location then
						--gun.Default.TextureID = 'rbxassetid://8117372147';
					--end;
					
					if gun.Name == '[Silencer]' or gun.Name == '[SilencerAR]' then
						gun:FindFirstChild('Part').Transparency = 0;
					end;

					local skin_name = InventoryChanger.Selected[gun.Name];

					if skin_name and InventoryChanger.Skins[skin_name] and InventoryChanger.Skins[skin_name].guns and InventoryChanger.Skins[skin_name].guns[gun.Name] then
						if InventoryChanger.Skins[skin_name].guns[gun.Name].TracerLoop then
							InventoryChanger.Skins[skin_name].guns[gun.Name].TracerLoop:Disconnect();
							InventoryChanger.Skins[skin_name].guns[gun.Name].TracerLoop = nil;
						end;

						if InventoryChanger.Skins[skin_name].guns[gun.Name].shoot_sound_loop then
							InventoryChanger.Skins[skin_name].guns[gun.Name].shoot_sound_loop:Disconnect();
							InventoryChanger.Skins[skin_name].guns[gun.Name].shoot_sound_loop = nil;
						end;
					end;
				end;

				return;
			end;
			
			if gun and gun.Name == gun_name and skin_name then
				local skin_pack = InventoryChanger.Skins[skin_name];
				local guns = skin_pack.guns;
				if skin_pack and guns and not skin_pack.texture then
					for _, x in next, gun.Default:GetChildren() do x:Destroy() end;
					
					local clone = guns[gun_name].location:Clone();
					clone.Name = 'Mesh';
					clone.Parent = gun.Default;
					
					local weld = Instance.new('Weld', clone);
					weld.Part0 = gun.Default;
					weld.Part1 = clone;
					weld.C0 = guns[gun_name].C0;
					
					gun.Default.Transparency = 1;

					if guns[gun_name].shoot_sound then
						if guns[gun_name].shoot_sound_loop then
							guns[gun_name].shoot_sound_loop:Disconnect();
							guns[gun_name].shoot_sound_loop = nil;
						end;
						gun.Handle.ShootSound.SoundId = guns[gun_name].shoot_sound;
						guns[gun_name].shoot_sound_loop = gun.Handle.ChildAdded:Connect(function(child)
							if child:IsA('Sound') and child.Name == 'ShootSound' then
								child.SoundId = guns[gun_name].shoot_sound;
							end;
						end);
					end;
				end;
			end;
		end;

		InventoryChanger.Functions.Start = function(name)
			for i, v in next, entries:GetChildren() do
				local skin_name, _ = v.Name:gsub('%[.-%]', '');

				if string.find(v.Name, name, 1, true) and InventoryChanger.Skins[skin_name] and InventoryChanger.Skins[skin_name].guns and InventoryChanger.Skins[skin_name].guns['['..name..']'] and InventoryChanger.Skins[skin_name].guns['['..name..']'].location then
					local Preview = v:FindFirstChild('Preview');
					local Button = v:FindFirstChild('Button');
					local skinInfo = v:FindFirstChild('SkinInfo');

					if Preview and Button and skinInfo then
						local Label = Preview:FindFirstChild('LockImageLabel');
						local AmountValue = Preview:FindFirstChild('AmountValue');
						local Equipped = Preview:FindFirstChild('Equipped');
						local container = skinInfo:FindFirstChild('Container');

						local extracted_name = v.Name:match(regex);

						if Equipped and extracted_name then
							Equipped.Visible = InventoryChanger.Skins[skin_name] and InventoryChanger.Skins[skin_name].guns['['..extracted_name..']'] and InventoryChanger.Skins[skin_name].guns['['..extracted_name..']'].equipped or false;
							InventoryChanger.Functions.Equip('['..extracted_name..']', InventoryChanger.Selected['['..extracted_name..']'])

							if Label then
								Label.Visible = false;
							end;

							if container and container.SellButton then
								container.SellButton.Visible = true;
							end;
						
							if AmountValue then
								AmountValue.Visible = true;
								AmountValue.Text = 'x1';
							end;
						
							if getgenv().InventoryConnections[v.Name] then
								getgenv().InventoryConnections[v.Name]:Disconnect();
								getgenv().InventoryConnections[v.Name] = nil;
							end;

							v.Button:Destroy();
							local props = { Text = '',BackgroundTransparency = 1,Size = UDim2.new(1, 0, 0.7, 0),ZIndex = 5,Name = 'Button',Position = UDim2.new(0, 0, 0, 0)};
							local new_btn = mkelement('TextButton', v, props);

							getgenv().InventoryConnections[v.Name] = new_btn.MouseButton1Click:Connect(function()
								InventoryChanger.Skins[skin_name].guns['['..extracted_name..']'].equipped = not InventoryChanger.Skins[skin_name].guns['['..extracted_name..']'].equipped;
								InventoryChanger.Selected['['..extracted_name..']'] = InventoryChanger.Skins[skin_name].guns['['..extracted_name..']'].equipped and skin_name or nil;
								Equipped.Visible = InventoryChanger.Skins[skin_name].guns['['..extracted_name..']'].equipped;

								for k, x in ipairs(entries:GetChildren()) do
									if x.Name:match(regex) == extracted_name and x ~= v then
										x.Preview.Equipped.Visible = false;

										for _, l in next, InventoryChanger.Skins do
											if _ ~= skin_name and l['['..extracted_name..']'] and l['['..extracted_name..']'].equipped then
												l[extracted_name].equipped = false
											end;
										end;
									end;
									
									if x ~= v and string.find(x.Name, name, 1, true) and InventoryChanger.Skins[skin_name] and InventoryChanger.Skins[skin_name].guns and InventoryChanger.Skins[skin_name].guns['['..name..']'] and InventoryChanger.Skins[skin_name].guns['['..name..']'].location then
										local Preview = v:FindFirstChild('Preview');
										local Button = v:FindFirstChild('Button');
										local skinInfo = v:FindFirstChild('SkinInfo');
										
										if Preview and Button and skinInfo then
											local Label = Preview:FindFirstChild('LockImageLabel');
											local AmountValue = Preview:FindFirstChild('AmountValue');
											local Equipped = Preview:FindFirstChild('Equipped');
											local container = skinInfo:FindFirstChild('Container');
											
											if Label then
												Label.Visible = false;
											end;
							
											if container and container.SellButton then
												container.SellButton.Visible = true;
											end;
											
											if AmountValue then
												AmountValue.Visible = true;
												AmountValue.Text = 'x1';
											end;
										end;

										InventoryChanger.Owned = {};
										InventoryChanger.Functions.AddOwnedSkins();
										InventoryChanger.Functions.UnequipGameSkins();
									end;
								end;
							end);
						end;
					end;
				end;
			end;
		end;

		InventoryChanger.Functions.CharacterAdded = function(character)
			if getgenv().InventoryConnections.ChildAdded then
				getgenv().InventoryConnections.ChildAdded:Disconnect();
				getgenv().InventoryConnections.ChildAdded = nil;
			end;

			if getgenv().InventoryConnections.ChildRemoved then
				getgenv().InventoryConnections.ChildRemoved:Disconnect();
				getgenv().InventoryConnections.ChildRemoved = nil;
			end;

			getgenv().InventoryConnections.ChildAdded = character.ChildAdded:Connect(function(child)
				if child:IsA('Tool') and child:FindFirstChild('GunScript') then
					InventoryChanger.Functions.Equip(child.Name, InventoryChanger.Selected[child.Name]);
					local skin_name = InventoryChanger.Selected[child.Name];
					
					if skin_name then
						if InventoryChanger.Skins[skin_name].color and InventoryChanger.Skins[skin_name].guns[child.Name].equipped then
							if InventoryChanger.Skins[skin_name].guns[child.Name].TracerLoop then
								InventoryChanger.Skins[skin_name].guns[child.Name].TracerLoop:Disconnect();
								InventoryChanger.Skins[skin_name].guns[child.Name].TracerLoop = nil;
							end;

							InventoryChanger.Skins[skin_name].guns[child.Name].TracerLoop = Ignored.DescendantAdded:Connect(function(descendant)
								local gun = find_gun(child.Name, client.Character) or nil;

								if gun and descendant:IsDescendantOf(siren) and descendant:IsA('Beam') then
									local pos1 = (descendant.Attachment0.WorldCFrame.Position.X > gun.Handle.CFrame.Position.X) and descendant.Attachment0.WorldCFrame.Position or gun.Handle.CFrame.Position;
									local pos2 = (descendant.Attachment0.WorldCFrame.Position.X < gun.Handle.CFrame.Position.X) and descendant.Attachment0.WorldCFrame.Position or gun.Handle.CFrame.Position;

									if math.abs(client.Character.HumanoidRootPart.Velocity.X) < 22 and (pos1 - pos2).Magnitude < 5 or (pos1 - pos2).Magnitude < 20 then
										local skin_pack = InventoryChanger.Skins[skin_name];
										local guns = skin_pack and skin_pack.guns or nil
										local tween_duration = skin_pack and (skin_pack.tween_duration or guns and guns[gun.Name] and guns[gun.Name].tween_duration) or nil;
										local width = skin_pack and (skin_pack.beam_width or guns and guns[gun.Name] and guns[gun.Name].beam_width) or nil;
										local color = skin_pack and (skin_pack.color or guns and guns[gun.Name] and guns[gun.Name].color) or nil;
										local easing_direction = skin_pack and (skin_pack.easing_direction or guns and guns[gun.Name] and guns[gun.Name].easing_direction) or nil;
										local easing_style = skin_pack and (skin_pack.easing_stye or guns and guns[gun.Name] and guns[gun.Name].easing_style) or nil;

										if skin_pack and tween_duration and color then
											local clonedParent = descendant.Parent:Clone();

											clonedParent.Parent = workspace.Vehicles;
											descendant.Parent:Destroy();
											if width then
												clonedParent:FindFirstChild('GunBeam').Width1 = width;
											end;
											clonedParent:FindFirstChild('GunBeam').Color = color;
											Utilities.Tween({
												object = clonedParent:FindFirstChild('GunBeam'),
												info = { tween_duration, easing_style, easing_direction },
												properties = { Width1 = 0 },
												callback = function()
													clonedParent:Destroy();
												end
											})
										elseif color then
											descendant.Color = color;
										end;
									end;
								end;
							end);
						else
							if InventoryChanger.Skins[skin_name].guns[child.Name].TracerLoop then
								InventoryChanger.Skins[skin_name].guns[child.Name].TracerLoop:Disconnect();
								InventoryChanger.Skins[skin_name].guns[child.Name].TracerLoop = nil;
							end;
						end;
					end;
				end;
			end);

			getgenv().InventoryConnections.ChildRemoved = character.ChildRemoved:Connect(function(child)
				if child:IsA('Tool') and child:FindFirstChild('GunScript') then
					InventoryChanger.Functions.Equip(child.Name, false);

					local skin_name = InventoryChanger.Selected[child.Name];

					if skin_name then
						if InventoryChanger.Skins[skin_name].guns[child.Name].TracerLoop then
							InventoryChanger.Skins[skin_name].guns[child.Name].TracerLoop:Disconnect();
							InventoryChanger.Skins[skin_name].guns[child.Name].TracerLoop = nil;
						end;
					end;
				end;
			end);
			
			InventoryChanger.Functions.Reload();
		end;

		if getgenv().InventoryConnections.CharacterAdded then
			getgenv().InventoryConnections.CharacterAdded:Disconnect();
			getgenv().InventoryConnections.CharacterAdded = nil;
		end;
		getgenv().InventoryConnections.CharacterAdded = client.CharacterAdded:Connect(InventoryChanger.Functions.CharacterAdded);    InventoryChanger.Functions.CharacterAdded(client.Character);end;
    end,
    DoubleClick = false,
    Tooltip = 'Gives you skins in your inventory'
})

LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Auto Stomp')

    _G.autoStomp = _G.autoStomp or false  -- Default is false if not already set

    if _G.autoStompReady == nil then
    -- Ensures this part only runs once to save resources
    _G.autoStompReady = true

    -- Variables
    local stompRemote = game.ReplicatedStorage.MainEvent -- The event you're firing
    local player = game.Players.LocalPlayer
    local stompInterval = 0.10 -- seconds between each stomp (default)
    local isLooping = false -- Start with stomping disabled
    local stompKey = Enum.KeyCode.F -- Default hotkey

    -- Cache frequently used objects
    local userInputService = game:GetService("UserInputService")
    local runService = game:GetService("RunService")
    local debrisService = game:GetService("Debris")
    
    -- Store common references once and reuse
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Store Enum values for reusability
    local keyEnum = Enum.KeyCode.F

    -- Function to display notifications
    local function showNotification(title, text, duration)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 2 -- Default duration of 2 seconds
        })
    end

    -- Function to start stomping with precise timing
    local function startStomping()
        local lastStompTime = tick()  -- Store the current time at the start
        local stompConnection
        stompConnection = runService.Heartbeat:Connect(function()
            if isLooping then
                local currentTime = tick()
                if currentTime - lastStompTime >= stompInterval then
                    if humanoid and humanoid.Parent then
                        stompRemote:FireServer("Stomp")
                        lastStompTime = currentTime  -- Update the last stomp time
                    end
                end
            end
        end)
        _G.stompConnection = stompConnection
    end

    -- Function to stop stomping
    local function stopStomping()
        if _G.stompConnection then
            _G.stompConnection:Disconnect()
            _G.stompConnection = nil
        end
    end

    -- Function to toggle stomping with the F key or any configured key
    local function onKeyPress(input, gameProcessed)
        if not gameProcessed then
            if _G.autoStomp and input.KeyCode == stompKey then
                isLooping = not isLooping
                if isLooping then
                    showNotification("Auto Stomp Enabled", "🎭  Hexploit 🎭", 3)
                    startStomping()  -- Now calling startStomping properly
                else
                    showNotification("Auto Stomp Disabled", "🎭  Hexploit 🎭", 3)
                    stopStomping()
                end
            end
        end
    end

    -- UI Integration
    LeftGroupBox:AddToggle('MyToggle', {
        Text = 'Toggle Auto Stomp',
        Default = false, -- Default value (true / false)
        Tooltip = 'Toggles Stomps when walking over players', -- Information shown when you hover over the toggle
        Callback = function(Value)
            print('[cb] MyToggle changed to:', Value)
            _G.autoStomp = Value
            if _G.autoStomp then
                showNotification("Auto Stomp Enabled", "🎭  Hexploit 🎭", 3)
            else
                showNotification("Auto Stomp Disabled", "🎭  Hexploit 🎭", 3)
            end
        end
    })

    LeftGroupBox:AddLabel('Keybind'):AddKeyPicker('KeyPicker', {
        Default = 'F', -- String as the name of the keybind (MB1, MB2 for mouse buttons)
        SyncToggleState = false,
        Mode = 'Toggle', -- Modes: Always, Toggle, Hold
        Text = 'Auto Stomp', -- Text to display in the keybind menu
        NoUI = false, -- Set to true if you want to hide from the Keybind menu
        Callback = function(Value)
            print('[cb] Keybind clicked!', Value)
        end,
        ChangedCallback = function(New)
            print('[cb] Keybind changed!', New)
            stompKey = New -- Update the hotkey dynamically when changed
        end
    })

    LeftGroupBox:AddSlider('MySlider', {
        Text = 'Time between stomps',
        Default = stompInterval,
        Min = 0,
        Max = 1,
        Rounding = 1,
        Compact = false,
        Callback = function(Value)
            print('[cb] MySlider was changed! New value:', Value)
            stompInterval = Value -- Update stomp interval value dynamically

            -- Restart the stomping loop if it's running
            if isLooping then
                stopStomping()  -- Stop the current stomping loop
                startStomping() -- Restart it with the new interval
            end
        end
    })

    -- Connect key press event if autoStomp is true
    _G.autoStompKeyConnection = userInputService.InputBegan:Connect(onKeyPress)

    else
    -- Ensure the key press event is only active if autoStomp is true
    if _G.autoStomp then
        -- Disconnect the key press event
        if _G.autoStompKeyConnection then
            _G.autoStompKeyConnection:Disconnect()
            _G.autoStompKeyConnection = nil
        end

        -- Reset the stomp loop
        _G.autoStomp = false
    end
    _G.autoStompReady = nil
    end

  LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Tp Stomp')

    -- Predefine commonly used services
    local gameReplicatedStorage = game:GetService("ReplicatedStorage")
    local userInputService = game:GetService("UserInputService")
    local starterGui = game:GetService("StarterGui")
    local runService = game:GetService("RunService")

    -- Optimize FindFirstChild usage
    local function findChild(parent, name)
    return parent:FindFirstChild(name)
    end

    -- Object Pooling for Repeatedly Used Instances (e.g., BodyEffects)
    local function getBodyEffects(player)
    return findChild(player.Character, "BodyEffects")
    end

    -- UI Setup for Tp Stomp Toggle
    LeftGroupBox:AddToggle('MyToggle', {
    Text = 'Toggle Tp Stomp',
    Default = false,
    Tooltip = 'Toggle Teleporting to players and stomping',
    Callback = function(Value)
        _G.autoTP = Value
        if Value then
        end
        print('[cb] MyToggle changed to:', Value)
    end
    })

    -- UI Setup for Tp Back Toggle
    LeftGroupBox:AddToggle('TpBackToggle', {
    Text = 'Tp back to original position',
    Default = false,
    Tooltip = 'This makes it so after each stomp it tps back to your original position',
    Callback = function(Value)
        _G.tpBackToOriginal = Value
        print('[cb] Tp Back Toggle changed to:', Value)
    end
    })

    -- Keybind for Tp Stomp
    LeftGroupBox:AddLabel('Keybind'):AddKeyPicker('KeyPicker', {
    Default = 'F',
    SyncToggleState = false,
    Mode = 'Hold',
    Text = 'Tp Stomp Keybind',
    NoUI = false,
    Callback = function(Value)
        print('[cb] Keybind clicked!', Value)
    end,
    ChangedCallback = function(New)
        _G.tpStompKey = New
        print('[cb] Keybind changed to:', New)
    end
    })

    -- Slider to change teleport range (studs)
    LeftGroupBox:AddSlider('MySlider', {
    Text = 'Teleport Range',
    Default = 100,
    Min = 0,
    Max = 5000,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        _G.teleportRange = Value
        print('[cb] MySlider was changed! New value:', Value)
    end
    })

    -- Script for teleportation functionality
    if _G.autoTP == nil then
    _G.autoTP = false
    end

    if _G.autoTPReady == nil then
    _G.autoTPReady = true

    -- Variables
    local player = game.Players.LocalPlayer
    _G.teleportRange = _G.teleportRange or 100 -- Set default range if not set
    _G.tpStompKey = _G.tpStompKey or Enum.KeyCode.F -- Default key for teleport stomp
    _G.tpBackToOriginal = _G.tpBackToOriginal == nil and false or _G.tpBackToOriginal

    -- Function to display notifications
    local function showNotification(title, text, duration)
        starterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 2 -- Default duration of 2 seconds
        })
    end

    -- Function to find the nearest knocked player within range
    local function findNearestKnockedPlayer()
        local nearestPlayer = nil
        local shortestDistance = _G.teleportRange

        for _, otherPlayer in pairs(game.Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local bodyEffects = getBodyEffects(otherPlayer)
                local isKnocked = bodyEffects and findChild(bodyEffects, "K.O") and bodyEffects["K.O"].Value == true
                if isKnocked then
                    local torso = findChild(otherPlayer.Character, "UpperTorso") or findChild(otherPlayer.Character, "LowerTorso")
                    local playerRoot = findChild(player.Character, "HumanoidRootPart")
                    if torso and playerRoot then
                        local distance = (playerRoot.Position - torso.Position).Magnitude
                        if distance <= _G.teleportRange and distance < shortestDistance then
                            shortestDistance = distance
                            nearestPlayer = otherPlayer
                        end
                    end
                end
            end
        end
        return nearestPlayer
    end

    -- Function to teleport above a knocked player's torso, stomp, and teleport back (based on Tp Back toggle)
    local function teleportAndStomp(targetPlayer)
        if targetPlayer and targetPlayer.Character then
            local targetHumanoid = findChild(targetPlayer.Character, "Humanoid")
            local torso = findChild(targetPlayer.Character, "UpperTorso") or findChild(targetPlayer.Character, "LowerTorso")
            local playerRoot = findChild(player.Character, "HumanoidRootPart")

            if targetHumanoid and torso and playerRoot then
                -- Save the original position
                local originalPosition = playerRoot.CFrame

                -- Teleport above the player's torso (3 studs above)
                playerRoot.CFrame = CFrame.new(torso.Position + Vector3.new(0, 3, 0))

                -- Wait 0.35 seconds before stomping
                wait(0.35)

                -- Trigger the stomp action
                gameReplicatedStorage.MainEvent:FireServer("Stomp")

                -- Notify about the stomp
                showNotification("Stomping", "🎭  Hexploit 🎭", 3)

                -- Wait 0.10 seconds before teleporting back (if TpBack is enabled)
                wait(0.20)

                if _G.tpBackToOriginal then
                    -- Teleport back to the original position
                    playerRoot.CFrame = originalPosition
                end
            end
        else
            showNotification("No Target Found", "🎭  Hexploit 🎭", 3)
        end
    end

    -- Function to handle key press
    local function onKeyPress(input)
        if _G.autoTP and input.KeyCode == _G.tpStompKey then
            local targetPlayer = findNearestKnockedPlayer()
            teleportAndStomp(targetPlayer)
        end
    end

    -- Connect key press event
    _G.autoTPKeyConnection = userInputService.InputBegan:Connect(onKeyPress)
    else
    -- Disconnect the key press event
    if _G.autoTPKeyConnection then
        _G.autoTPKeyConnection:Disconnect()
        _G.autoTPKeyConnection = nil
    end

    -- Reset the script state
    _G.autoTP = false
    _G.autoTPReady = nil
    end

LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Anti Stomp')

local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local debris = game:GetService("Debris")  -- For cleanup

-- Assuming LeftGroupBox and other UI elements are set up previously
local antiStompEnabled = false  -- Default value for anti-stomp toggle

-- Cache Enum values that are used frequently
local HumanoidStateType = Enum.HumanoidStateType
local KOD = "K.O"
local GRABBING_CONSTRAINT = "GRABBING_CONSTRAINT"

-- Add the Anti Stomp toggle
LeftGroupBox:AddToggle('MyToggle', {
    Text = 'Anti Stomp',
    Default = false, -- Default value (true / false)
    Tooltip = 'Destroys character when knocked preventing stomps',
    
    Callback = function(Value)
        antiStompEnabled = Value  -- Update the toggle value
    end
})

-- RunService heartbeat to monitor character state
RunService.Heartbeat:Connect(function()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    -- Check if the character and humanoid exist
    if character and humanoid then
        -- Use a variable for BodyEffects and K.O state to avoid repeated calls
        local bodyEffects = character:FindFirstChild("BodyEffects")
        local KOd = bodyEffects and bodyEffects[KOD] and bodyEffects[KOD].Value
        local Grabbed = character:FindFirstChild(GRABBING_CONSTRAINT) ~= nil

        -- Only execute if Anti Stomp is enabled
        if antiStompEnabled and (KOd or Grabbed) then
            -- Prevent interaction by disabling humanoid interactions
            humanoid.PlatformStand = true  -- Disable normal character movements
            humanoid.WalkSpeed = 0  -- Prevent walking
            humanoid.JumpHeight = 0  -- Prevent jumping
            humanoid.Health = 0  -- Force kill the character immediately

            -- Disable collision to make it untouchable by other players
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false  -- Disable collision with other players
                end
            end

            -- Disable unnecessary humanoid states
            humanoid:SetStateEnabled(HumanoidStateType.Physics, false)
            humanoid:SetStateEnabled(HumanoidStateType.Seated, false)
            humanoid:SetStateEnabled(HumanoidStateType.Climbing, false)
            humanoid:SetStateEnabled(HumanoidStateType.Freefall, false)
            humanoid:SetStateEnabled(HumanoidStateType.Ragdoll, false)

            -- Prevent health changes from other players
            humanoid.MaxHealth = humanoid.Health

            -- Clean up BodyEffects to remove any effects causing interaction
            if bodyEffects then
                bodyEffects:ClearAllChildren()
            end

            -- Prevent stomping or any other interaction from players
            local collisionParts = character:GetChildren()
            for _, part in pairs(collisionParts) do
                if part:IsA("BasePart") then
                    part.CanCollide = false  -- Fully prevent collision interactions
                end
            end

            -- Immediately reset the character to remove any potential interaction
            player:LoadCharacter()  -- Reload the character to reset the player
        end
    end
end)

LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Force Reset')

MyButton = LeftGroupBox:AddButton({
    Text = 'Force Reset',
    Func = function()
        local Players = game:GetService("Players")
        local StarterGui = game:GetService("StarterGui")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            StarterGui:SetCore("SendNotification", {
                Title = "🖤🦇Emo aah🥀⛓",
                Text = "🎭 Hexploit 🎭",
                Duration = 2
            })
            humanoid.Health = 0
        end
    end,
    DoubleClick = false,
    Tooltip = 'Forces the game into resetting your character'
})

LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Auto Redeem Codes')

MyButton = LeftGroupBox:AddButton({
    Text = 'Auto Redeem Codes',
    Func = function()
        local codes = {
            "SHRIMP",
            "VIP",
            "2025",
            "DACARNIVAL",
            "RUBY",
            "THANKSGIVING24",
            "HALLOWEEN2024",
            "pumpkins2023",
            "TRADEME!",
            "Beary",
            "ShortCake",
            "DAUP"
        }
        
        -- Table to track successful codes
        local successfulCodes = {}
        
        -- Function to redeem a code
        local function redeemCode(code)
            -- Arguments for the server event
            local args = {
                [1] = "EnterPromoCode",
                [2] = code
            }
        
            -- Fire the server event
            game:GetService("ReplicatedStorage").MainEvent:FireServer(unpack(args))
        
            -- Wait for response or success (adjust the response as needed)
            local successIndicator = false
            game:GetService("ReplicatedStorage").MainEvent.OnClientEvent:Connect(function(response)
                if response == "CodeRedeemed" then  -- Adjust response check as per actual server logic
                    successIndicator = true
                end
            end)
        
            -- Wait for a short time before proceeding to next code
            wait(6)  -- 6 second wait between attempts (you can adjust this)
        
            -- If successfully redeemed, log the code
            if successIndicator then
                table.insert(successfulCodes, code)
            end
        
            print("Attempted to redeem code: " .. code)
        end
        
        -- Attempt to redeem each code
        for _, code in ipairs(codes) do
            redeemCode(code)
        end        
    end,
    DoubleClick = false,
    Tooltip = 'Redeems Active codes in the game'
})

LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Spin Bot')

--[[ 
Controls:
- Use the toggle in the UI to enable or disable SpinBot.
- Use the slider to adjust the SpinBot speed.
]]

-- Ensure proper initialization
if _G.spinBotInitialized == nil then
    _G.spinBotInitialized = false
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer
local humRoot, humanoid

-- Function to apply SpinBot
local function applySpinBot()
    if _G.spinBotActive and humRoot and humanoid then
        humanoid.AutoRotate = false
        local velocity = Instance.new("AngularVelocity")
        velocity.Attachment0 = humRoot:FindFirstChild("RootAttachment")
        velocity.MaxTorque = math.huge
        velocity.AngularVelocity = Vector3.new(0, _G.spinBotSpeed or 50, 0)
        velocity.Parent = humRoot
        velocity.Name = "Spinbot"
    end
end

-- Function to update character references
local function updateCharacterReferences()
    local character = plr.Character or plr.CharacterAdded:Wait()
    humRoot = character:WaitForChild("HumanoidRootPart")
    humanoid = character:FindFirstChildOfClass("Humanoid")
    
    -- Restore SpinBot after respawn if it was active
    task.wait(0.5)
    applySpinBot()
end

updateCharacterReferences()
plr.CharacterAdded:Connect(updateCharacterReferences)

-- UI Toggle for SpinBot
LeftGroupBox:AddToggle('SpinBotToggle', {
    Text = 'Spin Bot',
    Default = false,
    Tooltip = 'Makes you spin',
    Callback = function(Value)
        if Value then
            _G.spinBotActive = true
            _G.spinBotInitialized = true
            applySpinBot()
        else
            _G.spinBotActive = false
            _G.spinBotInitialized = false
            
            if humRoot and humanoid then
                humRoot.CFrame = CFrame.new(humRoot.Position)
                humanoid.AutoRotate = true
            end
            
            local velocity = humRoot and humRoot:FindFirstChild("Spinbot")
            if velocity then
                velocity:Destroy()
            end
        end
    end
})

-- UI Slider for SpinBot Speed
LeftGroupBox:AddSlider('SpinBotSpeed', {
    Text = 'SpinBot Speed',
    Default = 50,
    Min = 1,
    Max = 150,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        _G.spinBotSpeed = Value
        if _G.spinBotActive and humRoot then
            local velocity = humRoot:FindFirstChild("Spinbot")
            if velocity then
                velocity.AngularVelocity = Vector3.new(0, Value, 0)
            end
        end
    end
})

LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Infinite Zoom')

LeftGroupBox:AddToggle('MyToggle', {
    Text = 'Infinite Zoom',
    Default = false, -- Default value (true / false) 
    Tooltip = 'Lets you zoom out infinitely', -- Information shown when you hover over the toggle

    Callback = function(Value)

        -- Initialize zoom if it's not set
        if _G.zoomInitialized == nil then
            _G.zoomInitialized = false
        end

        if Value and not _G.zoomInitialized then
            -- Enable Infinite Zoom
            player.CameraMaxZoomDistance = math.huge

            _G.zoomInitialized = true
        elseif not Value and _G.zoomInitialized then
            -- Disable Infinite Zoom
            player.CameraMaxZoomDistance = 30

            _G.zoomInitialized = false
        end
    end
})

LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Chat Spy')

MyButton = LeftGroupBox:AddButton({
    Text = 'Chat Spy',
    Func = function()
        --[[ 
    Optimized Chat Spy Script
    Uses RunService for more efficient checks and object pooling to avoid repeated operations.
]]

-- Global variable to track if the script has been executed
if _G.chatSpyExecuted then
    return  -- Prevent re-execution if the script has already been executed
end

-- Mark the script as executed to prevent further notifications
_G.chatSpyExecuted = true

-- Configurations
Config = {
    enabled = false,  -- Start with disabled by default
    spyOnMyself = true,
    public = false,
    publicItalics = true
}

-- Customizing Log Output
PrivateProperties = {
    Color = Color3.fromRGB(120, 81, 169),
    Font = Enum.Font.SourceSansBold,
    TextSize = 18
}

StarterGui = game:GetService("StarterGui")
Players = game:GetService("Players")
ReplicatedStorage = game:GetService("ReplicatedStorage")
RunService = game:GetService("RunService")
player = Players.LocalPlayer
saymsg = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
getmsg = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("OnMessageDoneFiltering")

instance = (_G.chatSpyInstance or 0) + 1
_G.chatSpyInstance = instance

-- Toggle Chat Spy on execution
_G.chatSpyEnabled = not _G.chatSpyEnabled
Config.enabled = _G.chatSpyEnabled

-- Using a Debris service to clean up connections
Debris = game:GetService("Debris")

-- Function to handle chat messages
function onChatted(p, msg)
    if _G.chatSpyInstance == instance then
        if p == player and msg:lower():sub(1, 4) == "/spy" then
            Config.enabled = not Config.enabled
            wait(0.3)
        elseif Config.enabled and (Config.spyOnMyself == true or p ~= player) then
            -- Clean message formatting
            msg = msg:gsub("[\n\r]", ''):gsub("\t", ' '):gsub("[ ]+", ' ')
            local hidden = true
            local conn

            -- Efficient connection handling, disconnect after use
            conn = getmsg.OnClientEvent:Connect(function(packet, channel)
                if packet.SpeakerUserId == p.UserId and packet.Message == msg:sub(#msg - #packet.Message + 1) and (channel == "All" or (channel == "Team" and Config.public == false and Players[packet.FromSpeaker].Team == player.Team)) then
                    hidden = false
                end
            end)

            -- Use Debris for cleanup to prevent memory leaks
            Debris:AddItem(conn, 1)

            wait(1)

            if hidden and Config.enabled then
                if Config.public then
                    saymsg:FireServer((Config.publicItalics and "/me " or '') .. "{Hexploit} [" .. p.Name .. "]: " .. msg, "All")
                else
                    PrivateProperties.Text = "{SPY} [" .. p.Name .. "]: " .. msg
                    StarterGui:SetCore("ChatMakeSystemMessage", PrivateProperties)
                end
            end
        end
    end
end

-- Using RunService for efficient player connection tracking
RunService.Heartbeat:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if not p.Chatted then
            p.Chatted:Connect(function(msg) onChatted(p, msg) end)
        end
    end
end)

-- Connect to chat events
Players.PlayerAdded:Connect(function(p)
    p.Chatted:Connect(function(msg) onChatted(p, msg) end)
end)

-- Optimize chat frame positioning
chatFrame = player.PlayerGui.Chat.Frame
chatFrame.ChatChannelParentFrame.Visible = true
chatFrame.ChatBarParentFrame.Position = chatFrame.ChatChannelParentFrame.Position + UDim2.new(UDim.new(), chatFrame.ChatChannelParentFrame.Size.Y)

    end,
    DoubleClick = false,
    Tooltip = 'Makes you able to see any chat'
})

LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Chat Bypass')

MyButton = LeftGroupBox:AddButton({
    Text = 'Chat Bypass',
    Func = function()
        -- Function to send a notification
function sendNotification(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration
    })
end

-- Example usage
sendNotification("Down", "Getting bypass method", 5)
    end,
    DoubleClick = false,
    Tooltip = 'Chat Bypass Bans in da hood'
})

LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Avatar Forcefield')

    -- References to services and default settings
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer

    -- Constants for materials and default values
    local FORCEFIELD_MATERIAL = Enum.Material.ForceField
    local DEFAULT_MATERIAL = Enum.Material.Plastic
    local DEFAULT_COLOR = Color3.fromRGB(255, 255, 255)
    local currentColor = Color3.fromRGB(108, 59, 170) -- Default forcefield color
    local forcefieldEnabled = false -- Tracks whether the forcefield effect is enabled

    -- Function to customize character parts
    local function customizeCharacter(character, newColor)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if forcefieldEnabled then
                part.Color = newColor -- Apply the new color
                part.Material = FORCEFIELD_MATERIAL -- Apply ForceField material
            else
                part.Material = DEFAULT_MATERIAL -- Default material
                part.Color = DEFAULT_COLOR -- Default white color
            end
        end
    end
    end

    -- Function to handle player character updates
    local function onCharacterAdded(character)
    if forcefieldEnabled then
        customizeCharacter(character, currentColor)
    end
    end

    -- Connection to handle new character spawns
    player.CharacterAdded:Connect(onCharacterAdded)

    -- UI Integration
    LeftGroupBox:AddToggle('ForcefieldToggle', {
    Text = 'Enable Forcefield',
    Default = false, -- Default value (disabled)
    Tooltip = 'Toggle the forcefield effect on your character.',

    Callback = function(Value)
        forcefieldEnabled = Value
        print('[cb] Forcefield toggled:', Value)

        -- Apply or remove forcefield effect immediately
        local character = player.Character
        if character then
            customizeCharacter(character, currentColor)
        end
    end
    })

    LeftGroupBox:AddLabel('Forcefield Color'):AddColorPicker('ForcefieldColorPicker', {
    Default = currentColor, -- Default color
    Title = 'Select Forcefield Color',
    Transparency = 0, -- Disable transparency changing

    Callback = function(Value)
        print('[cb] Forcefield color changed:', Value)

        -- Update current color and apply the new color if the forcefield is enabled
        currentColor = Value
        local character = player.Character
        if forcefieldEnabled and character then
            customizeCharacter(character, currentColor)
        end
    end
    })

    -- Use RunService to update forcefield effect efficiently
    RunService.Heartbeat:Connect(function()
    if forcefieldEnabled then
        local character = player.Character
        if character then
            customizeCharacter(character, currentColor)
        end
    end
    end)

    LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Cs Headless')

    -- Roblox LocalScript for Applying Headless Effect (Client-Side)

    -- Settings
    getgenv().Time = 0.1 -- Delay for applying effects
    getgenv().HeadlessOverlay = "rbxassetid://15093053680" -- Provided headless ID

    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local StarterGui = game:GetService("StarterGui")

    -- Cache player
    local LocalPlayer = Players.LocalPlayer

    -- Optimized Notify Function
    local function notifyUser(title, text)
    StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = 5})
    end

    -- Apply Headless Effect (Hides the head)
    local function applyHeadless()
    local character = LocalPlayer.Character
    if not character then return end

    local head = character:FindFirstChild("Head")
    if head and not head:GetAttribute("HeadlessApplied") then
        head.Transparency = 1
        head:SetAttribute("HeadlessApplied", true) -- Prevent redundant operations
        local faceDecal = head:FindFirstChild("face")
        if faceDecal then
            faceDecal.Transparency = 1
        end
    end
    end

    -- Revert to Normal (Restores the head and face visibility)
    local function revertToNormal()
    local character = LocalPlayer.Character
    if not character then return end

    local head = character:FindFirstChild("Head")
    if head and head:GetAttribute("HeadlessApplied") then
        head.Transparency = 0
        head:SetAttribute("HeadlessApplied", nil) -- Clear applied attribute
        local faceDecal = head:FindFirstChild("face")
        if faceDecal then
            faceDecal.Transparency = 0
        end
    end
    end

    -- Continuously ensure the headless effect is applied when active
    RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    if character then
        if _G.headlessEffectActive then
            applyHeadless()
        else
            revertToNormal()
        end
    end
    end)

    -- Integration with Toggle
    LeftGroupBox:AddToggle('HeadlessToggle', {
    Text = 'Enable Headless',
    Default = false, -- Default value (true / false)
    Tooltip = 'Toggle the headless effect on your character',

    Callback = function(Value)
        if Value then
            -- Enable headless effect
            _G.headlessEffectActive = true
            applyHeadless()
        else
            -- Revert to normal
            _G.headlessEffectActive = false
            revertToNormal()
        end
    end
    })

LeftGroupBox = Tabs.Misc:AddLeftGroupbox('Da Hood Staff Checker')

--[[ 
    Controls:
    Use the UI toggle to enable/disable the staff checker.
]]

-- Ensure staff checker state is defined
if _G.staffCheckerEnabled == nil then
    _G.staffCheckerEnabled = false -- Default value
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Configuration
local staffKeywords = {["admin"] = true, ["owner"] = true, ["devs"] = true, ["contributed"] = true, ["monetization"] = true, ["moderators"] = true} -- Hash table for faster lookup
local staffGroups = {
    [4698921] = 2,  -- Group ID -> Minimum Rank
    [10604500] = 0  -- Min rank 0 means all ranks included
}

-- State
local checkedPlayers = {} -- Object pool to store checked players
local heartbeatConnection

-- Function to check if a player is staff
local function checkForStaff(player)
    if not _G.staffCheckerEnabled or checkedPlayers[player] then return end -- Stop if disabled or already checked

    local playerNameLower = string.lower(player.Name)
    
    -- Username keyword match (faster lookup with hash table)
    if staffKeywords[playerNameLower] then
        print("[STAFF DETECTED] Username match: " .. player.Name)
        checkedPlayers[player] = true
        return
    end

    -- Check if the player is in a staff group and meets rank requirement
    for groupId, minRank in pairs(staffGroups) do
        local success, isInGroup = pcall(player.IsInGroup, player, groupId)
        if success and isInGroup then
            local rank = player:GetRankInGroup(groupId)
            if rank >= minRank then
                print("[STAFF DETECTED] Group match: " .. player.Name .. " | Rank: " .. player:GetRoleInGroup(groupId))
                checkedPlayers[player] = true
                return
            end
        end
    end
end

-- Function to enable staff checker
function enableStaffChecker()
    if heartbeatConnection then return end -- Prevent duplicate connections

    heartbeatConnection = RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            checkForStaff(player)
        end
    end)
end

-- Function to disable staff checker
function disableStaffChecker()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    -- Cleanup checked players after 5 seconds (Debris for cleanup)
    Debris:AddItem(checkedPlayers, 5)
    checkedPlayers = {} -- Reset checked players
end

-- UI Toggle Integration
LeftGroupBox:AddToggle('MyToggle', {
    Text = 'Da Hood Staff Checker',
    Default = _G.staffCheckerEnabled,
    Tooltip = 'Enables real-time staff detection',

    Callback = function(Value)
        _G.staffCheckerEnabled = Value
        if Value then
            enableStaffChecker()
        else
            disableStaffChecker()
        end
        print('[Staff Checker] Toggled:', Value)
    end
})

LeftGroupBox = Tabs.Teleport:AddLeftGroupbox('Auto Buy')

local Player = game.Players.LocalPlayer

ShopLocations = {
    ["[AK47]"] = {location = Vector3.new(-587.529, 5.395, -753.718), clickDetector = "[AK47] - $2459"},
    ["[AK47 Ammo]"] = {location = Vector3.new(-584.029, 5.393, -755.418), clickDetector = "90 [AK47 Ammo] - $87"},
    ["[AUG]"] = {location = Vector3.new(-273.048, 49.363, -213.312), clickDetector = "[AUG] - $2131"},
    ["[AUG Ammo]"] = {location = Vector3.new(-278.033, 49.365, -213.394), clickDetector = "90 [AUG Ammo] - $87"},
    ["[AR]"] = {location = Vector3.new(-591.824, 5.46, -744.732), clickDetector = "[AR] - $1200"},
    ["[AR Ammo]"] = {location = Vector3.new(-592.224, 5.456, -751.532), clickDetector = "60 [AR Ammo] - $95"},
    ["[Double-Barrel SG]"] = {location = Vector3.new(19.881, 28.976, -837.246), clickDetector = "[Double-Barrel SG] - $1475"},
    ["[Double-Barrel SG Ammo]"] = {location = Vector3.new(19.925, 28.976, -831.337), clickDetector = "18 [Double-Barrel SG Ammo] - $55"},
    ["[Drum-Shotgun]"] = {location = Vector3.new(-1193.09, 25.48, -518.45), clickDetector = "[Drum-Shotgun] - $1202"},
    ["[Drum-Shotgun Ammo]"] = {location = Vector3.new(-1193.52, 25.48, -530.23), clickDetector = "18 [Drum-Shotgun Ammo] - $71"},
    ["[DrumGun]"] = {location = Vector3.new(-1177.78, 25.58, -530.26), clickDetector = "[DrumGun] - $3278"},
    ["[DrumGun Ammo]"] = {location = Vector3.new(-1186.83, 25.58, -529.87), clickDetector = "100 [DrumGun Ammo] - $219"},
    ["[Fire Armor]"] = {location = Vector3.new(-1176.59, 28.605, -478.91), clickDetector = "[Fire Armor] - $2623"},
    ["[Glock]"] = {location = Vector3.new(498.978, 45.109, -629.531), clickDetector = "[Glock] - $546"},
    ["[Glock Ammo]"] = {location = Vector3.new(501.278, 45.108, -626.031), clickDetector = "25 [Glock Ammo] - $66"},
    ["[LMG]"] = {location = Vector3.new(-620.882, 20.3, -305.339), clickDetector = "[LMG] - $4098"},
    ["[LMG Ammo]"] = {location = Vector3.new(-616.182, 20.3, -305.339), clickDetector = "200 [LMG Ammo] - $328"},
    ["[P90]"] = {location = Vector3.new(463.777, 45.132, -619.13), clickDetector = "[P90] - $1093"},
    ["[P90 Ammo]"] = {location = Vector3.new(462.977, 45.133, -624.531), clickDetector = "120 [P90 Ammo] - $66"},
    ["[RPG]"] = {location = Vector3.new(113.625, -29.649, -267.469), clickDetector = "[RPG] - $21855"},
    ["[RPG Ammo]"] = {location = Vector3.new(118.665, -29.65, -267.47), clickDetector = "5 [RPG Ammo] - $1093"},
    ["[Revolver]"] = {location = Vector3.new(-642.21, 18.85, -119.635), clickDetector = "[Revolver] - $1421"},
    ["[Revolver Ammo]"] = {location = Vector3.new(-635.77, 18.856, -119.345), clickDetector = "12 [Revolver Ammo] - $82"},
    ["[Rifle]"] = {location = Vector3.new(-259.658, 49.363, -213.512), clickDetector = "[Rifle] - $1694"},
    ["[Rifle Ammo]"] = {location = Vector3.new(-255.258, 49.363, -213.482), clickDetector = "5 [Rifle Ammo] - $273"},
    ["[Silencer]"] = {location = Vector3.new(-579.524, 5.454, -753.032), clickDetector = "[Silencer] - $601"},
    ["[Silencer Ammo]"] = {location = Vector3.new(-575.024, 5.452, -754.732), clickDetector = "25 [Silencer Ammo] - $55"},
    ["[SilencerAR]"] = {location = Vector3.new(490.477, 45.116, -633.831), clickDetector = "[SilencerAR] - $1366"},
    ["[SilencerAR Ammo]"] = {location = Vector3.new(497.277, 45.111, -634.231), clickDetector = "120 [SilencerAR Ammo] - $82"},
    ["[Shotgun]"] = {location = Vector3.new(-578.624, 5.472, -725.132), clickDetector = "[Shotgun] - $1366"},
    ["[Shotgun Ammo]"] = {location = Vector3.new(-578.424, 5.457, -747.132), clickDetector = "20 [Shotgun Ammo] - $66"},
    ["[SMG]"] = {location = Vector3.new(-577.123, 5.477, -718.031), clickDetector = "[SMG] - $820"},
    ["[SMG Ammo]"] = {location = Vector3.new(-582.523, 5.478, -717.231), clickDetector = "80 [SMG Ammo] - $66"},
    ["[TacticalShotgun]"] = {location = Vector3.new(470.878, 45.127, -620.631), clickDetector = "[TacticalShotgun] - $1912"},
    ["[TacticalShotgun Ammo]"] = {location = Vector3.new(492.878, 45.113, -620.431), clickDetector = "20 [TacticalShotgun Ammo] - $66"},
    ["[Taser]"] = {location = Vector3.new(-270.892, 18.9, -102.716), clickDetector = "[Taser] - $1093"},
    ["[Armor]"] = {location = Vector3.new(-257.108, 18.9, -83.164), clickDetector = "[High-Medium Armor] - $3278"},
    ["[Fire Armor]"] = {location = Vector3.new(-1176.59, 28.605, -478.91), clickDetector = "[Fire Armor] - $2623"},
    ["[Grenade]"] = {location = Vector3.new(108.825, -29.65, -267.509), clickDetector = "[Grenade] - $765"},
    ["[Chicken]"] = {location = Vector3.new(300.773, 49.883, -627.567), clickDetector = "[Chicken] - $8"}
}

-- Notification function
function announce(title, text, time)
    game.StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = time or 5;
    })
end

-- Function to auto-buy a selected item
function AutoBuyOnce(itemName)
    local shopData = ShopLocations[itemName]
    if not shopData then
        warn("Item not found in ShopLocations: " .. tostring(itemName))
        return
    end

    local originalPos = Player.Character.HumanoidRootPart.CFrame
    Player.Character.HumanoidRootPart.CFrame = CFrame.new(shopData.location)
    wait(0.25)

    -- Wait for 0.1 seconds before checking for ClickDetector
    wait(0.1)

    -- Find and trigger ClickDetector
    local clicked = false
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("ClickDetector") and part.Parent.Name == shopData.clickDetector then
            fireclickdetector(part)
            clicked = true
            break
        end
    end

    if not clicked then
        warn("ClickDetector not found for: " .. tostring(itemName))
    end

    -- Always teleport back after checking for the ClickDetector
    wait(0.5)
    Player.Character.HumanoidRootPart.CFrame = originalPos
    print("Teleported back to original position.")
end

-- Auto Buy button
LeftGroupBox:AddButton({
    Text = 'Buy',
    Func = function()
        if _G.SelectedItem then
            AutoBuyOnce(_G.SelectedItem)
        else
            print("No item selected!")
        end
    end,
    DoubleClick = false,
    Tooltip = 'Buys selected item on press'
})

-- UI dropdown for selecting an item
LeftGroupBox:AddDropdown('MyDropdown', {
    Values = {
        '[AK47]', '[AK47 Ammo]',
        '[AUG]', '[AUG Ammo]',
        '[AR]', '[AR Ammo]',
        '[Chicken]',
        '[Double-Barrel SG]', '[Double-Barrel SG Ammo]',
        '[Drum-Shotgun]', '[Drum-Shotgun Ammo]',
        '[DrumGun]', '[DrumGun Ammo]',
        '[Glock]', '[Glock Ammo]',
        '[LMG]', '[LMG Ammo]',
        '[P90]', '[P90 Ammo]',
        '[Revolver]', '[Revolver Ammo]',
        '[RPG]', '[RPG Ammo]',
        '[Rifle]', '[Rifle Ammo]',
        '[Shotgun]', '[Shotgun Ammo]',
        '[Silencer]', '[Silencer Ammo]',
        '[SilencerAR]', '[SilencerAR Ammo]',
        '[TacticalShotgun]', '[TacticalShotgun Ammo]',
        '[Taser]',
        '[Armor]', '[Fire Armor]',
        '[Grenade]'
    },
    Default = 0,
    Multi = false,
    Text = 'Select an item',
    Tooltip = 'Choose an item to auto-buy',
    Callback = function(Value)
        _G.SelectedItem = Value
    end
})

LeftGroupBox = Tabs.Teleport:AddLeftGroupbox('Teleports')

MyButton = LeftGroupBox:AddButton({
    Text = 'Bank',
    Func = function()
        teleportCFrame = CFrame.new(-442, 39, -284)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'Inside Bank',
    Func = function()
        teleportCFrame = CFrame.new(-443, 23, -284)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})


MyButton = LeftGroupBox:AddButton({
    Text = 'Vault',
    Func = function()
        teleportCFrame = CFrame.new(-658, -30, -285)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'Mid Appartment Building',
    Func = function()
        teleportCFrame = CFrame.new(-323, 80, -299)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'Revolver',
    Func = function()
        teleportCFrame = CFrame.new(-634, 21, -132)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'LMG',
    Func = function()
        teleportCFrame = CFrame.new(-626, 23, -295)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'Swimming Pool',
    Func = function()
        teleportCFrame = CFrame.new(-847, 21, -279)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'Broken Fire Station',
    Func = function()
        teleportCFrame = CFrame.new(-1182, 28, -521)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'DownHill',
    Func = function()
        teleportCFrame = CFrame.new(-559, 8, -735)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'Military Base',
    Func = function()
        teleportCFrame = CFrame.new(-40, 65, -926)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'Uphill',
    Func = function()
        teleportCFrame = CFrame.new(481, 48, -602)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'Breaking Bad',
    Func = function()
        teleportCFrame = CFrame.new(598, 28, -214)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'Church',
    Func = function()
        teleportCFrame = CFrame.new(205, 21, -124)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'Police Station',
    Func = function()
        teleportCFrame = CFrame.new(-264, 21, -93)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

MyButton = LeftGroupBox:AddButton({
    Text = 'School',
    Func = function()
        teleportCFrame = CFrame.new(-594, 21, 173)  -- Change this to your desired coordinates
        game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(teleportCFrame)
    end,
    DoubleClick = false,
    Tooltip = 'Teleports you to the Bank'
})

RightGroupBox = Tabs.Teleport:AddRightGroupbox('Extra Stuff')

local savedCFrame = nil  -- Variable to store the saved location

MyButton = RightGroupBox:AddButton({
    Text = 'Save Location',
    Func = function()
        savedCFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame  -- Save the CFrame location of the player
    end,
    DoubleClick = false,
    Tooltip = 'This button saves your current location'
})

MyButton = RightGroupBox:AddButton({
    Text = 'Teleport to Saved Location',
    Func = function()
        if savedCFrame then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = savedCFrame  -- Teleport to the saved location
        else
        end
    end,
    DoubleClick = false,
    Tooltip = 'This button teleports you to the saved location'
})

MyButton = RightGroupBox:AddButton({
    Text = 'Server-Hop',
    Func = function()
TeleportService = game:GetService("TeleportService")
Players = game:GetService("Players")
player = Players.LocalPlayer

-- Function to hop to another server
function hopToAnotherServer()
    local placeId = game.PlaceId

    -- Request a new server
    TeleportService:Teleport(placeId, player)
end

-- Call the function to hop
hopToAnotherServer()
    end,
    DoubleClick = true,
    Tooltip = 'Server-Hops to a different Server'
})

MyButton = RightGroupBox:AddButton({
    Text = 'Rejoin Server',
    Func = function()
TeleportService = game:GetService("TeleportService")
Players = game:GetService("Players")
player = Players.LocalPlayer

-- Function to rejoin the current server
function rejoinServer()
    local placeId = game.PlaceId  -- Get the current place ID
    TeleportService:Teleport(placeId, player)  -- Teleport the player back into the same server
end

-- Call the function to rejoin
rejoinServer()
    end,
    DoubleClick = false,
    Tooltip = 'Rejoins Current Server'
})

LeftGroupBox = Tabs.D:AddLeftGroupbox('Dev Tools')

MyButton = LeftGroupBox:AddButton({
    Text = 'Animation Printer',
    Func = function()
    -- Access the LocalPlayer and their character's humanoid
    local player = game:GetService("Players").LocalPlayer
    local humanoid = player.Character and player.Character:WaitForChild("Humanoid")

    -- Function to track and print the animations the player performs
    local function printAnimations()
    -- Ensure the humanoid exists
    if humanoid then
        -- Get the Animator component, which plays animations
        local animator = humanoid:FindFirstChildOfClass("Animator")
        
        -- Ensure the Animator exists
        if animator then
            -- Connect to the 'AnimationPlayed' event
            animator.AnimationPlayed:Connect(function(animationTrack)
                -- Get the Animation object from the AnimationTrack
                local animation = animationTrack.Animation
                -- Print the name and AnimationId of the animation played
                print("Animation Name: " .. animation.Name .. " | AnimationId: " .. animation.AnimationId)
            end)
        else
            print("Animator not found in Humanoid.")
        end
    else
        print("Humanoid not found in character.")
    end
    end

    -- Call the function to start tracking animations
    printAnimations()

    -- Optional: Keep checking for the character's respawn (if it might respawn during the game)
    player.CharacterAdded:Connect(function(character)
    humanoid = character:WaitForChild("Humanoid")
    printAnimations()  -- Re-call the function if the player respawns
    end)
    end,
    DoubleClick = false,
    Tooltip = 'Print Animations'
    })

    MyButton = LeftGroupBox:AddButton({
        Text = 'Sound Logger',
        Func = function()
            local function logSound(sound)
                if sound.SoundId then
                    print("Sound played: " .. sound.Name .. " with Asset ID: " .. sound.SoundId)
                else
                    print("Sound played: " .. sound.Name .. " (No Asset ID)")
                end
            end
            
            -- Connect to all sounds in the game
            game.DescendantAdded:Connect(function(descendant)
                if descendant:IsA("Sound") then
                    logSound(descendant)
                end
            end)
            
            -- Loop through all existing sounds
            for _, obj in ipairs(game:GetDescendants()) do
                if obj:IsA("Sound") then
                    logSound(obj)
                end
            end            
        end,
        DoubleClick = false,
        Tooltip = 'This is the main button'
    })

MyButton = LeftGroupBox:AddButton({
        Text = 'Print Inventory',
        Func = function()
            -- List all tools in the Backpack and print their names
backpack = game.Players.LocalPlayer:WaitForChild("Backpack")

for _, item in ipairs(backpack:GetChildren()) do
    print(item.Name)  -- This will print the names of all items in your Backpack
end
        end,
        DoubleClick = false,
        Tooltip = 'prints items in inventory'
    })

MyButton = LeftGroupBox:AddButton({
        Text = 'Print Location Keybind P',
        Func = function()
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            
            -- Function to get and print the player's location
            local function getLocation()
                local location = humanoidRootPart.Position
                print("Player's location: " .. tostring(location))
            end
            
            -- Listen for the "P" key press
            local userInputService = game:GetService("UserInputService")
            
            userInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
            
                if input.KeyCode == Enum.KeyCode.P then
                    getLocation()
                end
            end)
        end,
        DoubleClick = false,
        tooltip = 'prints location on P',
    })


-- Initialize watermark visibility state
watermarkVisible = true  -- Boolean to track watermark visibility
Library:SetWatermarkVisibility(watermarkVisible)  -- Set initial visibility to true

-- Function to toggle the watermark visibility
function toggleWatermarkVisibility(Value)
    watermarkVisible = Value  -- Update the visibility state
    Library:SetWatermarkVisibility(watermarkVisible)  -- Apply the new visibility
end

-- FPS and Ping display update
FrameTimer = tick()
FrameCounter = 0
FPS = 60

-- Corrected FPS and Ping update inside RenderStepped
WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    if not watermarkVisible then return end  -- Skip updating if watermark is hidden

    FrameCounter += 1

    -- Update FPS every second
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    -- Update watermark with FPS and Ping
    local ping = math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    Library:SetWatermark(('HexploitV2 | %s fps | %s ms'):format(
        math.floor(FPS),
        ping
    ))
end)

-- UI setup
MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

-- Add a button to unload the library
MenuGroup:AddButton('Unload', function() Library:Unload() end)

-- Add a keybind for the menu
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind  -- Set custom keybind for the menu

-- Hand library to managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')

-- Build config and theme menus
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

Library.KeybindFrame.Visible = true  -- Set keybind frame visibility

-- Add a toggle for keybind frame visibility
MenuGroup:AddToggle('KeybindFrameVisibleToggle', {
    Text = 'Show Keybind List',
    Default = true,  -- Default visibility is true
    Tooltip = 'Toggle the visibility of the Keybind List',
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end
})

-- Add a toggle for watermark visibility
MenuGroup:AddToggle('WatermarkToggle', {
    Text = 'Toggle FPS and Ping Display',
    Default = true,  -- Default state is visible
    Tooltip = 'Toggle the visibility of the FPS and Ping display',
    Callback = function(Value)
        toggleWatermarkVisibility(Value)  -- Toggle watermark based on the UI toggle
    end
})
