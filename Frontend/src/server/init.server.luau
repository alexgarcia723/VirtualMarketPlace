local HttpService = game:GetService("HttpService")

local URL = "http://localhost:8080/"
local response = HttpService:GetAsync(URL)
--local response = HttpService:PostAsync(URL, "some text")
--local data = HttpService:JSONDecode(response)
print(response)

print("Hello world, from server!")