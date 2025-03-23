local Utility = {}
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local playerDataUpdate = remotesFolder:FindFirstChild("PlayerDataUpdate")
SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)
local serverAddress = "http://localhost:8080"
local endpoints = {
    placeOrder = "/api/v1/placeOrder",
    fillLimitOrder = "/api/v1/fillLimitOrder",
    fillMarketOrder = "/api/v1/fillMarketOrder",
    getPage = "/api/v1/getPage/"
}

Utility.GlobalPlayerDataTable = {}
-- TODO: if transaction is canceled, then currency/items should be returned to player
-- TODO: construct gui to display player's pending orders from which they can monitor their status or cancel them

function Utility.GetViewingPageData(pageIndex)
    HttpService:GetAsync(serverAddress)
end

function Utility.GetServerAddress()
    return serverAddress
end

function Utility.PlaceOrder(player, transactionDetails)
    local playerId = player.UserId
    local playerData = Utility.GlobalPlayerDataTable[playerId]
    local playerPendingOrdersTable = playerData.pendingPlayerOrders
    if (#playerPendingOrdersTable >= 10) then
        return {statusCode = -1, message = "You have reached the 10 pending order limit. Cancel an order to place another."}
    end

    local unformattedPrice = tonumber(transactionDetails.price)
    local unformattedQuantity = tonumber(transactionDetails.quantity)
    if (not unformattedPrice) or (not unformattedQuantity) then
        return {statusCode = -1, message = "Missing quantity or price value."}
    end
    
    local price = math.floor(unformattedPrice * 100 + 0.5)/100
    local quantity = math.floor(unformattedQuantity + 0.5)

    -- validate price and quantity
    if price <= 0 or quantity <= 0 then
        return {statusCode = -1, message = "Invalid quantity or price value."}
    end

    -- validate transactionType
    local transactionType = transactionDetails.transactionType
    if transactionType ~= SharedUtility.TransactionType.BuyOrder and transactionType ~= SharedUtility.TransactionType.SellOrder then
        return {statusCode = -1, message = "Order type selection is invalid."}
    end

    -- validate itemType
    local itemType = transactionDetails.itemType
    if not itemType then
        return {statusCode = -1, message = "Item selection is invalid."}
    end

    -- check that player has enough items or money to fill the order
    if transactionType == SharedUtility.TransactionType.SellOrder then
        local itemName = SharedUtility.ItemTypeLookup[itemType]
        if (quantity > playerData.inventory[itemName]) then
            return {statusCode = -1, message = "You do not have enough of " .. itemName .. " to place this order."}
        end
    else 
        local totalPrice = quantity * price
        -- TODO: use epsilon value or store (integer * 100) or use metatable to round currency on every update
        if (totalPrice > math.floor(playerData.currency * 100 + 0.5) / 100) then
            return {statusCode = -1, message = "You do not have enough currency ($" .. totalPrice .. ") to place this order."}
        end
    end

    local validatedTransactionDetails = {
        transactionType = transactionType,
        itemType = itemType,
        originalQuantity = quantity,
        remainingQuantity = quantity,
        price = price,
        ownerId = playerId,
        ownerName = "NameOfMerchant"
        -- ownerName = player.Name
    }

    local response = nil
    local httpSuccess, statusMessage = pcall(function() 
        response = HttpService:RequestAsync({
            Url = serverAddress..endpoints["placeOrder"],
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode(validatedTransactionDetails)
        })
    end)

    if httpSuccess and response.StatusCode == 200 then
        local responseData = nil
        local jsonSuccess, errorMessage = pcall(function() 
            responseData = HttpService:JSONDecode(response.Body)
        end)

        if jsonSuccess then
            local funds = price * quantity
            local formattedFunds = math.ceil(funds * 100)/100
            if transactionType == SharedUtility.TransactionType.SellOrder then
                formattedFunds = 0
            else 
                quantity = 0
            end

            -- update player funds/inventory and add pending transaction to player data
            validatedTransactionDetails.transctionId = responseData[0]
            Utility.UpdatePlayerData(player, -formattedFunds, {[SharedUtility.ItemTypeLookup[itemType]] = -quantity})
            table.insert(playerPendingOrdersTable, validatedTransactionDetails)
            return {statusCode = 1, message = responseData[1]}
        end
    end

    return {statusCode = -1, message = response.Body}
end

function Utility.UpdatePlayerData(player, fundsIncrement, inventoryIncrements)
    local playerId = player.UserId
    Utility.GlobalPlayerDataTable[playerId].currency += fundsIncrement

    for itemName, itemQuantity in pairs(inventoryIncrements) do
        Utility.GlobalPlayerDataTable[playerId].inventory[itemName] += itemQuantity
    end

    -- print(Utility.GlobalPlayerDataTable[playerId])
    playerDataUpdate:FireClient(player, Utility.GlobalPlayerDataTable[playerId])
end

function Utility.FillOrder(player, transactionId, desiredQuantity, price, transactionType, itemType)
    local playerId = player.UserId
    local playerData = Utility.GlobalPlayerDataTable[playerId]
    local unformattedQuantity = tonumber(desiredQuantity)
    if (not unformattedQuantity) then
        return {statusCode = -1, message = "Quantity must be a positive integer."}
    end
    
    local quantity = math.floor(unformattedQuantity + 0.5)

    -- validate quantity
    if quantity <= 0 then
        return {statusCode = -1, message = "Quantity must be a positive integer."}
    end

    -- check that player has enough items or money to fill the order
    print(transactionType)
    if transactionType == SharedUtility.TransactionType.Sell then
        local itemName = SharedUtility.ItemTypeLookup[itemType]
        if (quantity > playerData.inventory[itemName]) then
            return {statusCode = -1, message = "You do not have enough of " .. itemName .. " to fill this order."}
        end
    else 
        local totalPrice = quantity * price
        if (totalPrice > playerData.currency) then
            return {statusCode = -1, message = "You do not have enough currency ($" .. totalPrice .. ") to fill this order."}
        end
    end

    local validatedOrderDetails = {
        otherTransactionId = tostring(transactionId),
        ownerId = tostring(playerId),
        desiredQuantity = tostring(desiredQuantity)
    }

    local response = nil
    local httpSuccess, statusMessage = pcall(function() 
        response = HttpService:RequestAsync({
            Url = serverAddress..endpoints["fillLimitOrder"],
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode(validatedOrderDetails)
        })
    end)

    if httpSuccess and response.StatusCode == 200 then
        local funds = price * desiredQuantity
        local formattedFunds = math.ceil(funds * 100)/100
        if transactionType == SharedUtility.TransactionType.Sell then
            formattedFunds *= -1
        else 
            desiredQuantity *= -1
        end

        print(SharedUtility.ItemTypeLookup[itemType])
        -- update player funds/inventory and add pending transaction to player data
        Utility.UpdatePlayerData(player, -formattedFunds, {[SharedUtility.ItemTypeLookup[itemType]] = -desiredQuantity})
        return {statusCode = 1, message = response.Body}
    end

    return {statusCode = -1, message = response.Body}
end

function Utility.GetOrdersPageFromServer(player, transactionType, itemType, pageNum)
    local response = nil
    local success, statusMessage = pcall(function() 
        response = HttpService:RequestAsync({
            Url = serverAddress..endpoints["getPage"] .. itemType .. "?transactionType=" .. transactionType .. "&pageNum=" .. pageNum,
            Method = "GET",
            Headers = {
                ["Content-Type"] = "application/json",
            }
	    })
    end)
    
    return success and HttpService:JSONDecode(response.Body) or nil
end

function Utility.MarketFillOrder(player, itemType, transactionType, desiredQuantity, partialFill)
    -- TODO: if transactionType == SellOrder, then check if player has enough quantity to sell
    -- int itemTypeIndex, int transactonTypeIndex, int desiredQuantity, int ownerId, double availableFunds, boolean partialFill) {
    local ownerId = player.UserId
    local playerFunds = Utility.GlobalPlayerDataTable[ownerId].currency
    local unformattedQuantity = tonumber(desiredQuantity)
    if (not unformattedQuantity) then
        return {statusCode = -1, message = "Quantity must be a positive integer."}
    end
    
    local quantity = math.floor(unformattedQuantity + 0.5)

    -- validate quantity
    if quantity <= 0 then
        return {statusCode = -1, message = "Quantity must be a positive integer."}
    end

    local validatedOrderDetails = {
        ownerId = tostring(ownerId),
        desiredQuantity = tostring(desiredQuantity),
        itemType = tostring(itemType),
        transactionType = tostring(transactionType),
        availableFunds = tostring(playerFunds),
        partialFill = partialFill and "true" or "false"
    }

    local response = nil
    local httpSuccess, statusMessage = pcall(function() 
        response = HttpService:RequestAsync({
            Url = serverAddress..endpoints["fillMarketOrder"],
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode(validatedOrderDetails)
        })    
    end)

    if httpSuccess then
        local responseData = nil
        local jsonSuccess, errorMessage = pcall(function() 
            responseData = HttpService:JSONDecode(response.Body)
        end)
            
        if jsonSuccess and response.StatusCode == 200 then
            local spentFunds = tonumber(responseData[1])
            local formattedSpentFunds = math.ceil(spentFunds * 100)/100
            if transactionType == SharedUtility.TransactionType.SellOrder then
                formattedSpentFunds *= -1
                desiredQuantity *= -1
            end

            Utility.UpdatePlayerData(player, -formattedSpentFunds, {[SharedUtility.ItemTypeLookup[itemType]] = desiredQuantity})
            return {statusCode = 1, message = responseData[1]}
        end
    end

    return {statusCode = -1, message = response.Body}
end

return Utility