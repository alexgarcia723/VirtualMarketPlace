-- local HttpService = game:GetService("HttpService")
local Utility = require("./Utility")
local URL = Utility.GetServerAddress()


-- local response = Utility.GetViewingPageData()
local response = Utility.AddExampleTransaction()
--local data = HttpService:JSONDecode(response)
print(response)


print("Hello world, from server!")