local Utility = {}
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)
local serverAddress = "http://localhost:8080"
local endpoints = {
    placeOrder = "/api/v1/placeOrder",
    getPage = "/api/v1/getPage/"
}

function Utility.GetViewingPageData(pageIndex)
    HttpService:GetAsync(serverAddress)
end

function Utility.GetServerAddress()
    return serverAddress
end

function Utility.AddExampleTransaction()
    local transactionDetails = {
        transactionType = SharedUtility.GetRandomTransactionType(),
        itemId = "Orange",
        originalQuantity = 50,
        remaningQuantity = 17,
        price = 49.99,
        ownerId = "John Doe",
    }

    local response = HttpService:RequestAsync({
		Url = serverAddress..endpoints["placeOrder"],
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
		},
		Body = HttpService:JSONEncode(transactionDetails)
	})

    return response
end

function Utility.PlaceOrder(player, transactionDetails)
    local unformattedPrice = tonumber(transactionDetails.price)
    local unformattedQuantity = tonumber(transactionDetails.quantity)
    if (not unformattedPrice) or (not unformattedQuantity) then
        return false
    end
    
    price = math.floor(unformattedPrice * 100 + 0.5)/100
    quantity = math.floor(unformattedQuantity+ 0.5)

    -- validate price and quantity
    if price < 0 or quantity < 0 then
        return false
    end

    -- validate transactionType
    local transactionType = transactionDetails.transactionType
    if transactionType ~= SharedUtility.TransactionType.BuyOrder and transactionType ~= SharedUtility.TransactionType.SellOrder then
        return false
    end

    -- validate itemId
    local itemId = transactionDetails.itemId
    if not itemId then
        return false
    end

    local validatedTransactionDetails = {
        transactionType = transactionType,
        itemId = itemId,
        originalQuantity = quantity,
        remainingQuantity = quantity,
        price = price,
        ownerId = "NameOfMerchant"
        -- ownerId = player.Name
    }

    local response = HttpService:RequestAsync({
		Url = serverAddress..endpoints["placeOrder"],
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
		},
		Body = HttpService:JSONEncode(validatedTransactionDetails)
	})

    return response
end

function Utility.GetOrdersPageFromServer(player, transactionType, itemId, pageNum)
    local response = HttpService:RequestAsync({
		Url = serverAddress..endpoints["getPage"] .. itemId .. "?transactionType=" .. transactionType .. "&pageNum=" .. pageNum,
		Method = "GET",
		Headers = {
			["Content-Type"] = "application/json",
		}
	})

    return HttpService:JSONDecode(response.Body)
end


return Utility