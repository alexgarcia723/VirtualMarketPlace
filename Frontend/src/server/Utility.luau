local Utility = {}

local HttpService = game:GetService("HttpService")
local serverAddress = "http://localhost:8080"
local endpoints = {
    placeOrder = "/api/v1/placeOrder"
}

function Utility.GetViewingPageData(pageIndex)
    HttpService:GetAsync(serverAddress)
end

function Utility.GetServerAddress()
    return serverAddress
end

function Utility.AddExampleTransaction()
    -- {"transactionType":"PendingBuy","itemId":0,"originalQuantity":50,"remainingQuantity":17,"price":49.99,"sellerId":"John Doe","transactionId":"cbd78608-bc1c-4497-b529-0dac08c40490"}
    local transactionDetails = {
        transactionType = "PendingBuy",
        itemId = 1234567,
        originalQuantity = 50,
        remaningQuantity = 17,
        price = 49.99,
        sellerId = "John Doe",
        transactionId = HttpService:GenerateGUID(false)
    }

    local response = HttpService:RequestAsync({
		Url = serverAddress..endpoints["placeOrder"],
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json", -- When sending JSON, set this!
		},
		Body = HttpService:JSONEncode(transactionDetails)
	})

    return response
end


return Utility