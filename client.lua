local webhookUrl = "TVŮJ_WEBHOOK_URL"
local alreadyChecking = {}
local hexChars = '0123456789abcdef'
local foundCheat = false
local nullAddress = 0
local onCheckCheat = false

function readStringMemory(address)
    local value = ""
    xpcall(function()
        Citizen.InvokeNative(0x32ca01c3, "1337", address)
        value = GetLabelText("1337")
    end, function(err)
    end)
    return value
end

function bruteForceAddresses(offset, start, endO, start2, whatCheck, playerId, playerName)
    Citizen.CreateThread(function()
        for i = start, endO do
            if foundCheat then break end
            Wait(10)
            for j = start2, 15 do
                if foundCheat then break end
                Wait(1)
                for k = 0, 15 do
                    if foundCheat then break end
                    for l = 0, 15 do
                        if foundCheat then break end
                        for m = 0, 15 do
                            if foundCheat then break end

                            local hexAddress = offset .. hexChars:sub(i + 1, i + 1) .. hexChars:sub(j + 1, j + 1) .. hexChars:sub(k + 1, k + 1) .. hexChars:sub(l + 1, l + 1) .. hexChars:sub(m + 1, m + 1)

                            if whatCheck == "tz" then 
                                local tzAddress = tonumber(hexAddress .. "e480")
                                local tzAddressValue = readStringMemory(tzAddress)
                                if tzAddressValue == "NULL" then
                                    nullAddress = nullAddress + 1
                                end
                            else 
                                local d3d10Address = tonumber(hexAddress .. "145f")
                                local susanoAddress = tonumber(hexAddress .. "8020")
                                local d3d10AddressValue = readStringMemory(d3d10Address)
                                local susanoAddressValue = readStringMemory(susanoAddress)

                                if d3d10AddressValue == "Fd3d10.dll" then
                                    sendToWebhook(playerId, playerName, "d3d10.dll Cheat Detected")
                                    foundCheat = true
                                    return true
                                end

                                if susanoAddressValue and string.find(susanoAddressValue, "Online -") then
                                    sendToWebhook(playerId, playerName, "Susano Cheat Detected")
                                    foundCheat = true
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end

        if (nullAddress > 1750 and nullAddress < 1850 or nullAddress > 600 and nullAddress < 900) and whatCheck == "tz" then 
            sendToWebhook(playerId, playerName, "TZ Project Detected")
            foundCheat = true
            return true
        end

        if not foundCheat then
            bruteForceAddresses("0x7ff", 8, 10, 0, "allOther", playerId, playerName)
            bruteForceAddresses("0x7ff", 13, 15, 0, "allOther", playerId, playerName)
        end
    end)
end

function sendToWebhook(playerId, playerName, message)
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, "POST", json.encode({
        username = "Anti-Cheat",
        embeds = {{
            title = "Cheat Detekován",
            description = "Hráč ID: " .. playerId .. "\nJméno: " .. playerName .. "\nCheat: " .. message,
            color = 16711680
        }}
    }), { ["Content-Type"] = "application/json" })
end

function startPlayerCheck(playerId)
    if alreadyChecking[playerId] then return end
    alreadyChecking[playerId] = true
    local playerName = GetPlayerName(playerId)
    bruteForceAddresses("0x7ff", 6, 7, 1, "tz", playerId, playerName)
    alreadyChecking[playerId] = false
end

AddEventHandler("playerConnecting", function(name, setCallback, deferrals)
    local playerId = source
    Wait(2000)
    startPlayerCheck(playerId)
end)

Citizen.CreateThread(function()
    while true do
        Wait(60000)
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            startPlayerCheck(playerId)
        end
    end
end)
