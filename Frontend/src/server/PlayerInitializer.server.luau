local Players = game:GetService("Players")
-- local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local DataStoreService = game:GetService("DataStoreService")
local Utility = require("./Utility")
local MarketplaceTempalateUI = StarterGui:FindFirstChild("MarketplaceUI")
local TopbarTemplateUI = StarterGui:FindFirstChild("TopbarUI")
local InventoryUI = StarterGui:FindFirstChild("InventoryUI")

local DataStoreName = "M93sjmcNt1X6"
-- local DataStoreName = tostring(Random.new():NextInteger(1, 999999))
local playerDataStore = DataStoreService:GetDataStore(DataStoreName)
local getOptions = Instance.new("DataStoreGetOptions")
getOptions.UseCache = false

local function GetInitializedPlayerData()
    local startingItemCount = 20
    local initializedPlayerData = {
        currency = 1000000,
        inventory = {
            Apple = startingItemCount,
            Banana = startingItemCount,
            Orange = startingItemCount,
            Grape = startingItemCount,
            Watermelon = startingItemCount
        },
        pendingPlayerOrders = {},
        orderProcessing = false
    }
    
    return initializedPlayerData
end

local function ProcessPlayerJoin(player)
    -- add player UI
    local marketplaceUI = MarketplaceTempalateUI:Clone()
    marketplaceUI.Parent = player.PlayerGui
    local topbarUI = TopbarTemplateUI:Clone()
    topbarUI.Parent = player.PlayerGui
    local playerId = player.UserId

    -- get player data
    local playerData = nil
    local getSuccess, getResult = pcall(function()
        return playerDataStore:GetAsync(playerId, getOptions)
    end)

    if not getSuccess or not getResult then
        local initialPlayerData = GetInitializedPlayerData()
        local setSuccess, _ = pcall(function()
            return playerDataStore:SetAsync(playerId, initialPlayerData)
        end)
        
        if not setSuccess then
            -- keep retrying periodically
        else
            playerData = initialPlayerData
        end
    else
        playerData = getResult
    end

    print(playerData)

    -- send player data to client to update UI
    Utility.GlobalPlayerDataTable[playerId] = playerData
    Utility.UpdatePlayerData(player, 0, {})
end

local function ProcessPlayerLeave(player)
    -- save player data on leave
    local playerId = player.UserId
    local playerData = Utility.GlobalPlayerDataTable[playerId]
    playerData.orderProcessing = false
    local setSuccess, _ = pcall(function()
        return playerDataStore:SetAsync(playerId, playerData)
    end)

    -- print("Saved player data for " .. player.Name)

    if not setSuccess then
        -- keep retrying periodically
    else
        Utility.GlobalPlayerDataTable[playerId] = nil
        Utility.PlayerViewingPages[playerId] = nil
    end
end

local function AwaitDataSave()
    local numItems = 0
    for key, value in pairs(Utility.GlobalPlayerDataTable) do
        numItems += 1
        -- playerDataStore:SetAsync(playerId, playerData)
    end

    if numItems ~= 0 then
        print("Waiting 1s for save to finish ...")
        task.wait(1)
    end
end


Players.PlayerAdded:Connect(ProcessPlayerJoin)
Players.PlayerRemoving:Connect(ProcessPlayerLeave)
game:BindToClose(AwaitDataSave)