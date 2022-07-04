require 'lua_server_commands'
require 'cmd_utils'

local CMD_NAME = 'windows'
local helper = nil

LuaServerCommands.register(CMD_NAME, function(author, command, args)

    -- Check if the correct number of arguments are passed.
    if #args > 4 or #args < 3 then
        return '/'..CMD_NAME..' [action] [player] [radius=1->32] [*chance=0.0->1.0 (DEFAULT: 1)]'
        ..'\n\tactions: open, close, thump, smash, fix, barricade, unbarricade, removebarricade, opencurtains, closecurtains'
    end

    -- NOTE: The helper only becomes visible in global scope when the first lua server command is fired.
    --       Make sure to reference the helper inside of the command's handler function.
    helper = LuaServerCommandHelper

    local action = string.lower(args[1])

    -- Attempt to resolve the player using the helper method.
    local username = args[2]
    local player = helper.getPlayerByUsername(username)
    if player == nil then return 'Player not found: '..username end

    local radius = tonumber(args[3])
    local chance = 1
    if #args == 4 then chance = tonumber(args[4]) end

    -- Clamp our values.
    if radius < 1 then radius = 1 end
    if radius > 32 then radius = 32 end
    if chance == 0 then return 'Chance given is zero. Nothing will happen.' end
    if chance > 1 then chance = 1 end

    local count = 0
    local windows = getNearbyWindows(player:getX(), player:getY(), player:getZ(), radius)

    if action == 'smash' then
        for i = 1, #windows, 1 do
            local window = windows[i]
            if window:isSmashed() == false then
                if chance == 1 or randomFloat() <= chance then
                    windows[i]:smashWindow()
                    helper.syncIsoObject(window)
                    count = count + 1
                end
            end
        end
        return tostring(count)..' window(s) smashed near the player: '..username..'.'
    elseif action == 'fix' then
        for i = 1, #windows, 1 do
            local window = windows[i]
            if window:isSmashed() == true then
                if chance == 1 or randomFloat() <= chance then
                    window:getSquare():transmitRemoveItemFromSquare(window)
                    helper.syncIsoObject(window)
                    window:addToWorld()
                    window:setSmashed(false)
                    helper.syncIsoObject(window)
                    window:transmitCompleteItemToClients()
                    helper.playWorldSoundSquare('fixwindow', window:getSquare(), 24.0)
                    count = count + 1
                end
            end
        end
        return tostring(count)..' window(s) fixed near the player: '..username..'.'
    elseif action == 'thump' then
        for i = 1, #windows, 1 do
            local window = windows[i]
            if window:isSmashed() == false then
                if chance == 1 or randomFloat() <= chance then
                    helper.playWorldSoundSquare('ZombieThumpWindow', window:getSquare(), 24.0)
                    count = count + 1
                end
            end
        end
        return tostring(count)..' window(s) thumped near the player: '..username..'.'
    elseif action == 'open' then
        for i = 1, #windows, 1 do
            local window = windows[i]
            if window:isSmashed() == false and window:IsOpen() == false then
                if chance == 1 or randomFloat() <= chance then
                    helper.playWorldSoundSquare('windowopen', window:getSquare(), 24.0)
                    window:ToggleWindow(player)
                    count = count + 1
                end
            end
        end
        return tostring(count)..' window(s) opened near the player: '..username..'.'
    elseif action == 'close' then
        for i = 1, #windows, 1 do
            local window = windows[i]
            if window:isSmashed() == false and window:IsOpen() == true then
                if chance == 1 or randomFloat() <= chance then
                    helper.playWorldSoundSquare('windowclose', window:getSquare(), 24.0)
                    window:ToggleWindow(player)
                    count = count + 1
                end
            end
        end
        return tostring(count)..' window(s) closed near the player: '..username..'.'
    elseif action == 'barricade' then
        for i = 1, #windows, 1 do
            local window = windows[i]
            if chance == 1 or randomFloat() <= chance then
                if barricade(window) then
                    helper.syncIsoObject(window)
                    count = count + 1
                end
            end
        end
        return tostring(count)..' window(s) barricaded near the player: '..username..'.'
    elseif action == 'unbarricade' then
        for i = 1, #windows, 1 do
            local window = windows[i]
            if chance == 1 or randomFloat() <= chance then
                if unbarricade(window) then
                    helper.syncIsoObject(window)
                    count = count + 1
                end
            end
        end
        return tostring(count)..' window(s) unbarricaded near the player: '..username..'.'
    elseif action == 'removebarricade' then
        for i = 1, #windows, 1 do
            local window = windows[i]
            if chance == 1 or randomFloat() <= chance then
                removeBarricade(window)
                helper.syncIsoObject(window)
            end
            count = count + 1
        end
        return tostring(count)..' window(s) have their barricades removed near the player: '..username..'.'
    elseif action == 'opencurtains' then
        for i = 1, #windows, 1 do
            local window = windows[i]
            local square = window:getSquare()
            if chance == 1 or randomFloat() <= chance then
                if openCurtain(window:HasCurtains()) then
                    count = count + 1
                end
            end
        end
        return tostring(count)..' window-curtains opened near the player: '..username..'.'
    elseif action == 'closecurtains' then
        for i = 1, #windows, 1 do
            local window = windows[i]
            if chance == 1 or randomFloat() <= chance then
                if closeCurtain(window:HasCurtains()) then
                    count = count + 1
                end
            end
        end
        return tostring(count)..' window-curtains closed near the player: '..username..'.'
    else
        return 'Unknown window action: '..tostring(action)
    end
end)

print('Registered Lua Server Command: '..CMD_NAME)
