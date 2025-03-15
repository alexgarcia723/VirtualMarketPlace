local Utility = {}
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)
local serverAddress = "http://localhost:8080"
local endpoints = {
    placeOrder = "/api/v1/placeOrder",
    fillLimitOrder = "/api/v1/fillLimitOrder",
    fillMarketOrder = "/api/v1/fillMarketOrder",
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
        transactionType = SharedUtility.TransactionType.BuyOrder,
        itemType = "Apple",
        -- itemType = "Orange",
        originalQuantity = 50,
        price = 149.99,
        ownerId = 99999,
        ownerName = "ExampleOwnerName"
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
    
    local price = math.floor(unformattedPrice * 100 + 0.5)/100
    local quantity = math.floor(unformattedQuantity + 0.5)

    -- validate price and quantity
    if price <= 0 or quantity <= 0 then
        return false
    end

    -- validate transactionType
    local transactionType = transactionDetails.transactionType
    if transactionType ~= SharedUtility.TransactionType.BuyOrder and transactionType ~= SharedUtility.TransactionType.SellOrder then
        return false
    end

    -- validate itemType
    local itemType = transactionDetails.itemType
    if not itemType then
        return false
    end

    local validatedTransactionDetails = {
        transactionType = transactionType,
        itemType = itemType,
        originalQuantity = quantity,
        remainingQuantity = quantity,
        price = price,
        ownerId = player.UserId,
        ownerName = "NameOfMerchant"
        -- ownerName = player.Name
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

function Utility.FillOrder(player, transactionId, desiredQuantity)
    local ownerId = player.UserId
    local unformattedQuantity = tonumber(desiredQuantity)
    if (not unformattedQuantity) then
        return false
    end
    
    local quantity = math.floor(unformattedQuantity + 0.5)

    -- validate quantity
    if quantity <= 0 then
        return false
    end

    local validatedOrderDetails = {
        otherTransactionId = tostring(transactionId),
        ownerId = tostring(ownerId),
        desiredQuantity = tostring(desiredQuantity)
    }

    local response = HttpService:RequestAsync({
		Url = serverAddress..endpoints["fillLimitOrder"],
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
		},
        Body = HttpService:JSONEncode(validatedOrderDetails)
	})

    return response
end

function Utility.GetOrdersPageFromServer(player, transactionType, itemType, pageNum)
    local response = HttpService:RequestAsync({
		Url = serverAddress..endpoints["getPage"] .. itemType .. "?transactionType=" .. transactionType .. "&pageNum=" .. pageNum,
		Method = "GET",
		Headers = {
			["Content-Type"] = "application/json",
		}
	})

    return HttpService:JSONDecode(response.Body)
end

function Utility.MarketFillOrder(player, itemType, transactionType, desiredQuantity, partialFill)
    -- int itemTypeIndex, int transactonTypeIndex, int desiredQuantity, int ownerId, double availableFunds, boolean partialFill) {
    local ownerId = player.UserId
    local unformattedQuantity = tonumber(desiredQuantity)
    if (not unformattedQuantity) then
        return false
    end
    
    local quantity = math.floor(unformattedQuantity + 0.5)

    -- validate quantity
    if quantity <= 0 then
        return false
    end

    local validatedOrderDetails = {
        ownerId = tostring(ownerId),
        desiredQuantity = tostring(desiredQuantity),
        itemType = tostring(itemType),
        transactionType = tostring(transactionType),
        availableFunds = tostring(20.0),
        partialFill = partialFill and "true" or "false"
    }

    local response = HttpService:RequestAsync({
		Url = serverAddress..endpoints["fillMarketOrder"],
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
		},
        Body = HttpService:JSONEncode(validatedOrderDetails)
	})

    return response
end

return Utility