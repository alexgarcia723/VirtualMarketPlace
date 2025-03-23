local Players = game:GetService("Players")
-- local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = require("./Utility")
local MarketplaceTempalateUI = StarterGui:FindFirstChild("MarketplaceUI")
local TopbarTemplateUI = StarterGui:FindFirstChild("TopbarUI")
local InventoryUI = StarterGui:FindFirstChild("InventoryUI")

local DataStoreName = "WlqwBMzNmPR"
local playerDataStore = DataStoreService:GetDataStore(DataStoreName)
local getOptions = Instance.new("DataStoreGetOptions")
getOptions.UseCache = false

local function GetInitializedPlayerData()
    local initializedPlayerData = {
        currency = 1000000,
        inventory = {
            Apple = 10000,
            Banana = 10000,
            Orange = 10000,
            Grape = 10000,
            Watermelon = 10000
        },
        pendingPlayerOrders = {}
    }
    
    return initializedPlayerData
end

local function ProcessPlayerJoin(player)
    -- add player UI
    local marketplaceUI = MarketplaceTempalateUI:Clone()
    marketplaceUI.Parent = player.PlayerGui
    local topbarUI = TopbarTemplateUI:Clone()
    topbarUI.Parent = player.PlayerGui
    local inventoryUI = InventoryUI:Clone()
    inventoryUI.Parent = player.PlayerGui
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

    -- send player data to client to update UI
    Utility.GlobalPlayerDataTable[playerId] = playerData
    Utility.UpdatePlayerData(player, 0, {})
end

local function ProcessPlayerLeave(player)
    -- save player data on leave
    local playerId = player.UserId
    local playerData = Utility.GlobalPlayerDataTable[playerId]
    local setSuccess, _ = pcall(function()
        return playerDataStore:SetAsync(playerId, playerData)
    end)

    if not setSuccess then
        -- keep retrying periodically
    end
end

Players.PlayerAdded:Connect(ProcessPlayerJoin)
Players.PlayerRemoving:Connect(ProcessPlayerLeave)