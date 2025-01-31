local isFreemode = false
local camera = nil
local maxDistance = 10.0
local moveSpeed = 0.5
local showUI = false

-- Default keybinds
local keybinds = {
    toggle_camera_key = 311,  -- K key
    move_up_key = 172,        -- Arrow Up
    move_down_key = 173,      -- Arrow Down
    move_left_key = 174,      -- Arrow Left
    move_right_key = 175,     -- Arrow Right
    increase_speed_key = 82,  -- , key
    decrease_speed_key = 81,  -- . key
    move_camera_up_key = 39,  -- ' key
    move_camera_down_key = 40,-- # key
    rotate_camera_key = 25,   -- Right mouse button
    exit_camera_key = 322     -- ESC key
}

-- Load keybinds from config
local config = LoadResourceFile(GetCurrentResourceName(), "config.cfg")
if config then
    for line in config:gmatch("[^\r\n]+") do
        local key, value = line:match("(%w+)%s*=%s*(%d+)")
        if key and value then
            keybinds[key] = tonumber(value)
        end
    end
else
    print("Failed to load config.cfg, using default keybinds")
end

-- Function to toggle freemode camera
function ToggleFreemodeCamera()
    local playerPed = PlayerPedId()
    if isFreemode then
        -- Disable freemode camera
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(camera, false)
        camera = nil
        isFreemode = false
        showUI = false
        print("Freemode camera disabled")
    else
        -- Enable freemode camera
        camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        if camera then
            SetCamCoord(camera, GetEntityCoords(playerPed))
            SetCamRot(camera, GetEntityRotation(playerPed))
            RenderScriptCams(true, false, 0, true, true)
            isFreemode = true
            showUI = true
            print("Freemode camera enabled")
        else
            print("Failed to create camera")
        end
    end
end

-- Function to get the forward vector of the camera
function GetCamForwardVector(cam)
    local rot = GetCamRot(cam, 2)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosX = math.cos(rotX)
    return {
        x = -math.sin(rotZ) * cosX,
        y = math.cos(rotZ) * cosX,
        z = math.sin(rotX)
    }
end

-- Function to handle camera movement
function HandleCameraMovement()
    if isFreemode and camera then
        local x, y, z = table.unpack(GetCamCoord(camera))
        local rotX, rotY, rotZ = table.unpack(GetCamRot(camera, 2))
        local forward = GetCamForwardVector(camera)

        -- Move camera with arrow keys
        if IsControlPressed(0, keybinds.move_up_key) then -- Arrow Up
            x = x + forward.x * moveSpeed
            y = y + forward.y * moveSpeed
            print("Arrow Up pressed")
        end
        if IsControlPressed(0, keybinds.move_down_key) then -- Arrow Down
            x = x - forward.x * moveSpeed
            y = y - forward.y * moveSpeed
            print("Arrow Down pressed")
        end
        if IsControlPressed(0, keybinds.move_left_key) then -- Arrow Left
            x = x - forward.y * moveSpeed
            y = y + forward.x * moveSpeed
            print("Arrow Left pressed")
        end
        if IsControlPressed(0, keybinds.move_right_key) then -- Arrow Right
            x = x + forward.y * moveSpeed
            y = y - forward.x * moveSpeed
            print("Arrow Right pressed")
        end
        if IsControlPressed(0, keybinds.move_camera_up_key) then -- ' key
            z = z + moveSpeed
            print("' key pressed")
        end
        if IsControlPressed(0, keybinds.move_camera_down_key) then -- # key
            z = z - moveSpeed
            print("# key pressed")
        end

        -- Adjust camera speed with , and . keys
        if IsControlJustPressed(0, keybinds.increase_speed_key) then -- , key
            moveSpeed = moveSpeed + 0.1
            print(", key pressed, moveSpeed: " .. moveSpeed)
        end
        if IsControlJustPressed(0, keybinds.decrease_speed_key) then -- . key
            moveSpeed = moveSpeed - 0.1
            if moveSpeed < 0.1 then
                moveSpeed = 0.1
            end
            print(". key pressed, moveSpeed: " .. moveSpeed)
        end

        -- Check distance limit
        local playerCoords = GetEntityCoords(PlayerPedId())
        if Vdist(playerCoords, x, y, z) > maxDistance then
            print("Distance limit reached")
            return
        end

        -- Update camera position
        SetCamCoord(camera, x, y, z)
        SetCamRot(camera, rotX, rotY, rotZ, 2)
        print(string.format("Camera moved to: x=%f, y=%f, z=%f", x, y, z))
    end
end

-- Function to handle mouse movement
function HandleMouseMovement()
    if isFreemode and camera and IsControlPressed(0, keybinds.rotate_camera_key) then -- Right mouse button
        local mouseX = GetDisabledControlNormal(0, 1) * 8.0
        local mouseY = GetDisabledControlNormal(0, 2) * 8.0
        local rotX, rotY, rotZ = table.unpack(GetCamRot(camera, 2))
        rotX = rotX - mouseY
        rotZ = rotZ - mouseX
        SetCamRot(camera, rotX, rotY, rotZ, 2)
    end
end

-- Function to draw UI
function DrawUI()
    if showUI then
        SetTextFont(0)
        SetTextProportional(1)
        SetTextScale(0.0, 0.3) -- Adjusted scale to make the UI smaller
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString("Controls:\nArrow Keys: Move\nScroll Wheel Up: Move Up\nScroll Wheel Down: Move Down\n,: Increase Speed\n.: Decrease Speed\nRotate: Right Mouse\nExit: ESC")
        DrawText(0.85, 0.1)
    end
end

-- Main thread
Citizen.CreateThread(function()
    print("Freemode camera script started")
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, keybinds.toggle_camera_key) then -- K key
            print("K key pressed")
            ToggleFreemodeCamera()
        end
        if isFreemode and IsControlJustPressed(0, keybinds.exit_camera_key) then -- ESC key
            print("ESC key pressed")
            ToggleFreemodeCamera()
        end
        HandleCameraMovement()
        HandleMouseMovement()
        DrawUI()
    end
end)
