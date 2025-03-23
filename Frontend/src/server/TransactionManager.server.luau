-- local HttpService = game:GetService("HttpService")
-- TODO: when player A buys from player B, we must update player B's datastores
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = require("./Utility")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local getOrdersPage = remotesFolder:FindFirstChild("GetOrdersPage")
local placeOrder = remotesFolder:FindFirstChild("PlaceOrder")
local fillOrder = remotesFolder:FindFirstChild("FillOrder")
local marketFillOrder = remotesFolder:FindFirstChild("MarketFillOrder")
local URL = Utility.GetServerAddress()

getOrdersPage.OnServerInvoke = Utility.GetOrdersPageFromServer
placeOrder.OnServerInvoke = Utility.PlaceOrder
fillOrder.OnServerInvoke = Utility.FillOrder
marketFillOrder.OnServerInvoke = Utility.MarketFillOrder

-- TODO: java backend feature suggestion: combine new orders by same merchant with same price and same item
-- TODO: implement caching?
-- TODO: implement batch HTTP requests with request queue?

-- test code
-- print(Utility.AddExampleTransaction())
-- test code

-- TODO: loop to periodically update item price histories
-- TODO: loop to peredically get average and mininum item prices

print("Hello world, from server!")