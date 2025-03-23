-- local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = require("./Utility")
local SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)

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

print("Hello world, from server!")