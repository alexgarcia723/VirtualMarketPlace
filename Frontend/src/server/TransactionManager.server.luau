-- local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = require("./Utility")
local SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local getOrdersPage = remotesFolder:FindFirstChild("GetOrdersPage")
local placeOrder = remotesFolder:FindFirstChild("PlaceOrder")
local URL = Utility.GetServerAddress()


-- local response = Utility.GetViewingPageData()
local response = Utility.AddExampleTransaction()
--local data = HttpService:JSONDecode(response)
print(response)

getOrdersPage.OnServerInvoke = Utility.GetOrdersPageFromServer
placeOrder.OnServerInvoke = Utility.PlaceOrder

print("Hello world, from server!")