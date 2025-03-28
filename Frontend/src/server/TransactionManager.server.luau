local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Utility = require("./Utility")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local placeOrder = remotesFolder:FindFirstChild("PlaceOrder")
local fillOrder = remotesFolder:FindFirstChild("FillOrder")
local marketFillOrder = remotesFolder:FindFirstChild("MarketFillOrder")
local requestCancelOrder = remotesFolder:FindFirstChild("RequestCancelOrder")
local updateServerViewingPages = remotesFolder:FindFirstChild("UpdateServerViewingPages")
local getNumOrdersPerPage = remotesFolder:FindFirstChild("GetNumOrdersPerPage")
local pendingOrderUpdateTimeout = 3
local pageUpdateTimeout = 1
local orderHistoriesUpdateTimeout = 5

placeOrder.OnServerInvoke = Utility.PlaceOrder
fillOrder.OnServerInvoke = Utility.FillOrder
marketFillOrder.OnServerInvoke = Utility.MarketFillOrder
requestCancelOrder.OnServerInvoke = Utility.CancelOrder
updateServerViewingPages.OnServerEvent:Connect(Utility.UpdateViewingPages)
getNumOrdersPerPage.OnServerInvoke = (function() return Utility.OrdersPerPage end)

local function UpdatePendingOrdersStatus()
    -- pings the java server every pendingOrderUpdateTimeout seconds to check status of pending player orders
        -- if they have been fully fulfilled, then they are removed from the player's pending order list
        -- updates remaining item count for pending orders
    while true do
        Utility.UpdateOrderStatus()
        task.wait(pendingOrderUpdateTimeout)
    end
end

local function RemoveOutdatedCacheEntries() 
    -- removes outdated entries from cached pages
    local currentUnixTime = DateTime.now().UnixTimestamp
    for itemName, pageTypes in pairs(Utility.PageCache) do
        for pageIndex, pageOrderList in pairs(pageTypes.buyPages) do
            local timeDiff = currentUnixTime - pageOrderList.pageAge
            if timeDiff > Utility.CacheEntryAgeLimit then
                pageOrderList = nil
            end
        end
    end
end

local function UpdatePages()
    -- pings java server every pageUpdateTimeout seconds and gets the updated page lists
    while true do
        Utility.UpdatePages()

        -- delete cache pages beyond our age threshold
        -- RemoveOutdatedCacheEntries()

        task.wait(pageUpdateTimeout)
    end
end

local function UpdateItemOrderHistories()
    -- pings java server every pageUpdateTimeout seconds and gets the updated page lists
    while true do
        Utility.UpdateItemOrderHistories()
        task.wait(orderHistoriesUpdateTimeout)
    end
end

-- TODO: backend feature: combine new orders by same merchant with same price and same item
-- TODO: implement batch HTTP requests with request queue?

-- TODO: loop to periodically update item price histories
-- TODO: loop to peredically get average and mininum item prices
-- TODO: add flag which is set to true anytime player sends request and only set to false after result is returned
    -- if player tries to send another request while flag = true, then return message 
        -- "Wait until current request is completed before sending a new request"

Players.PlayerAdded:Wait()
task.spawn(UpdatePendingOrdersStatus)
task.spawn(UpdatePages)
task.spawn(UpdateItemOrderHistories)