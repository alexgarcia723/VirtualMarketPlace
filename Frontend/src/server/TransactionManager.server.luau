-- local HttpService = game:GetService("HttpService")
-- TODO: when player A buys from player B, we must update player B's datastores
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = require("./Utility")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local getOrdersPage = remotesFolder:FindFirstChild("GetOrdersPage")
local placeOrder = remotesFolder:FindFirstChild("PlaceOrder")
local fillOrder = remotesFolder:FindFirstChild("FillOrder")
local marketFillOrder = remotesFolder:FindFirstChild("MarketFillOrder")
local requestCancelOrder = remotesFolder:FindFirstChild("RequestCancelOrder")
local URL = Utility.GetServerAddress()
local pendingOrderUpdateTimeout = 5

getOrdersPage.OnServerInvoke = Utility.GetOrdersPageFromServer
placeOrder.OnServerInvoke = Utility.PlaceOrder
fillOrder.OnServerInvoke = Utility.FillOrder
marketFillOrder.OnServerInvoke = Utility.MarketFillOrder
requestCancelOrder.OnServerInvoke = Utility.CancelOrder

local function UpdatePendingTransactionStatus()
-- TODO: loop periodically to update player's pending order status
    -- order must be removed from PendingOrders if its remaining quantity = 0
    -- on status update, we give merchant their items/currency
    while true do
        Utility.UpdateOrderStatus()
        task.wait(pendingOrderUpdateTimeout)
    end
end
-- TODO: java backend feature suggestion: combine new orders by same merchant with same price and same item
-- TODO: implement caching?
-- TODO: implement batch HTTP requests with request queue?

-- test code
-- print(Utility.AddExampleTransaction())
-- test code

-- TODO: loop to periodically update item price histories
-- TODO: loop to peredically get average and mininum item prices
-- TODO: add flag which is set to true anytime player sends request and only set to false after result is returned
    -- if player tries to send another request while flag = true, then return message 
        -- "Wait until current request is completed before sending a new request"

task.spawn(UpdatePendingTransactionStatus)
print("Hello world, from server!")