local Utility = {}
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local playerDataUpdate = remotesFolder:FindFirstChild("PlayerDataUpdate")
local updateClientPages = remotesFolder:FindFirstChild("UpdateClientPages")
local updateClientItemOrderHistories = remotesFolder:FindFirstChild("UpdateClientItemOrderHistories")
SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)
local serverAddress = "http://localhost:8080"
local endpoints = {
    placeOrder = "/api/v1/placeOrder",
    fillLimitOrder = "/api/v1/fillLimitOrder",
    fillMarketOrder = "/api/v1/fillMarketOrder",
    getPages = "/api/v1/getPages",
    cancelOrder = "/api/v1/cancelOrder",
    getOrderStatus = "/api/v1/getOrderStatus",
    getItemOrderHistories = "/api/v1/getItemOrderHistories"
}

Utility.GlobalPlayerDataTable = {}
Utility.PlayerViewingPages = {}
Utility.PageCache = {}
Utility.OrdersPerPage = 10 -- how many orders are in each page returned from the server
Utility.CacheEntryAgeLimit = 60 -- delete any cache entry older than 1 min

function Utility.UpdateViewingPages(player, itemType, buyPageIndex, sellPageIndex, beingViewed)
    local userId = player.UserId
    Utility.PlayerViewingPages[userId] = {itemType = itemType, buyPageIndex = buyPageIndex, sellPageIndex = sellPageIndex, beingViewed = beingViewed}
end

function Utility.UpdatePages()
    -- construct empty page request list
    local pageRequestList = {}
    for _, itemName in pairs(SharedUtility.ItemTypeLookup) do
        pageRequestList[itemName] = {buyPageIndices = {}, sellPageIndices = {}}
    end

    -- populate page request list
    for _, viewingPageInfo in pairs(Utility.PlayerViewingPages) do
        -- skip this player's pages since they do not have the marketplace window open
        if not viewingPageInfo.beingViewed then
            continue
        end

        local itemName = SharedUtility.ItemTypeLookup[viewingPageInfo.itemType]
        local itemPages = pageRequestList[itemName]

        -- insert unique buyPageIndices
        if not table.find(itemPages.buyPageIndices, viewingPageInfo.buyPageIndex) then
            -- TODO: request buyPageIndex + 1 as well to have 1 page ready when player switches to next page (only if using PageCache)
            table.insert(itemPages.buyPageIndices, viewingPageInfo.buyPageIndex)
        end

        -- insert unique sellPageIndices
        if not table.find(itemPages.sellPageIndices, viewingPageInfo.sellPageIndex) then
            -- TODO: request buyPageIndex + 1 as well to have 1 page ready when player switches to next page (only if using PageCache)
            table.insert(itemPages.sellPageIndices, viewingPageInfo.sellPageIndex)
        end
    end

    -- trim emtpy item pages from our request list
    local allPagesTrimmed = true
    for itemName, pageIndices in pairs(pageRequestList) do
        local noBuyPageIndices = #pageIndices.buyPageIndices == 0
        local noSellPageIndices = #pageIndices.sellPageIndices == 0
        if noBuyPageIndices and noSellPageIndices then
            pageRequestList[itemName] = nil
        else
            allPagesTrimmed = false
        end
    end

    -- skip server poll if no actively-viewed pages exist
    if allPagesTrimmed then
        return
    end

    -- send our HTTP POST request to get pages from Java server
    local httpSuccess, response = pcall(function() 
         return HttpService:RequestAsync({
            Url = serverAddress..endpoints["getPages"],
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode(pageRequestList)
	    })
    end)

    if (not httpSuccess) then
        -- uncaught error in Java backend or HTTPService unavailable
        return
    end

    if response.StatusCode == 200 then
        local jsonSuccess, updatedPages = pcall(function() 
            return HttpService:JSONDecode(response.Body)
        end)

        if not jsonSuccess then
            -- json decode failure or HTTPService unavailable
            return
        end

        -- update page cache
        for itemName, pageIndices in pairs(updatedPages) do
            local itemPageCache = Utility.PageCache[itemName]
            if not itemPageCache then
                Utility.PageCache[itemName] = {buyPages = {}, sellPages = {}}
                itemPageCache = Utility.PageCache[itemName]
            end

            -- update buy page cache
            for pageIndex, orderList in pairs(updatedPages[itemName].foundBuyPages) do
                itemPageCache.buyPages[tonumber(pageIndex)] = orderList
                itemPageCache.buyPages[tonumber(pageIndex)].pageAge = DateTime.now().UnixTimestamp
            end

            -- update sell page cache
            for pageIndex, orderList in pairs(updatedPages[itemName].foundSellPages) do
                itemPageCache.sellPages[tonumber(pageIndex)] = orderList
                itemPageCache.sellPages[tonumber(pageIndex)].pageAge = DateTime.now().UnixTimestamp
            end
        end

        -- send updated pages to clients
        for _, player in Players:GetPlayers() do
            local playerViewingPages = Utility.PlayerViewingPages[player.userId]
            if not playerViewingPages then
                continue
            end

            local itemType = playerViewingPages.itemType
            local itemName = SharedUtility.ItemTypeLookup[itemType]
            local buyPageIndex = Utility.PlayerViewingPages[player.userId].buyPageIndex
            local sellPageIndex = Utility.PlayerViewingPages[player.userId].sellPageIndex
            local buyPage = Utility.PageCache[itemName].buyPages[buyPageIndex]
            local sellPage = Utility.PageCache[itemName].sellPages[sellPageIndex]
            updateClientPages:FireClient(player, itemType, buyPageIndex, sellPageIndex, {buyPage, sellPage})
        end
    end
end

function Utility.UpdateItemOrderHistories()
    local httpSuccess, response = pcall(function() 
        return HttpService:RequestAsync({
            Url = serverAddress..endpoints["getItemOrderHistories"],
            Method = "GET",
            Headers = {
                ["Content-Type"] = "application/json",
            }
        })
    end)

    if httpSuccess then
        local jsonSuccess, itemOrderHistories = pcall(function() 
            return HttpService:JSONDecode(response.Body)
        end)

        if jsonSuccess then
            updateClientItemOrderHistories:FireAllClients(itemOrderHistories)
        end
    end
end

function Utility.GetPlayerOrderCount(player)
    -- TODO: instead have an integer and update it whenever we add/remove orders
    local playerData = Utility.GlobalPlayerDataTable[player.UserId]
    local playerPendingOrdersTable = playerData.pendingPlayerOrders
    local orderCount = 0
    for _, order in pairs(playerPendingOrdersTable) do
        orderCount += 1
    end

    return orderCount
end

function Utility.RemovePlayerOrder(playerId, transactionId)
    local playerData = Utility.GlobalPlayerDataTable[playerId]
    local playerPendingOrdersTable = playerData.pendingPlayerOrders
    playerPendingOrdersTable[transactionId] = nil
end

function Utility.PlaceOrder(player, transactionDetails)
    local costEpsilon = 0.00001
    local playerId = player.UserId
    local playerData = Utility.GlobalPlayerDataTable[playerId]
    local playerPendingOrdersTable = playerData.pendingPlayerOrders
    if (Utility.GetPlayerOrderCount(player) >= 10) then
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
        -- if (totalPrice > math.floor(playerData.currency * 100 + 0.5) / 100)  + costEpsilon then
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
        ownerName = player.DisplayName or player.Name
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
            if transactionType == SharedUtility.TransactionType.SellOrder then
                funds = 0
            else 
                quantity = 0
            end

            -- update player funds/inventory and add pending transaction to player data
            validatedTransactionDetails.transactionId = responseData[1]
            playerPendingOrdersTable[validatedTransactionDetails.transactionId] = validatedTransactionDetails
            Utility.UpdatePlayerData(player, -funds, {[SharedUtility.ItemTypeLookup[itemType]] = -quantity})
            return {statusCode = 1, message = responseData[2]}
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
    -- TODO: check order id against some local cache and deny order if player.userId = transaction.ownerId
    local playerId = player.UserId
    local ownerName = player.DisplayName or player.Name
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
        ownerName = ownerName,
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

        -- update player funds/inventory and add pending transaction to player data
        Utility.UpdatePlayerData(player, -formattedFunds, {[SharedUtility.ItemTypeLookup[itemType]] = -desiredQuantity})
        return {statusCode = 1, message = response.Body}
    end

    return {statusCode = -1, message = response.Body}
end

function Utility.MarketFillOrder(player, itemType, transactionType, desiredQuantity, partialFill)
    -- TODO: how to handle self-fill? skip over these orders?
    local ownerId = player.UserId
    local ownerName = player.DisplayName or player.Name
    local playerFunds = Utility.GlobalPlayerDataTable[ownerId].currency
    local itemName = SharedUtility.ItemTypeLookup[itemType]
    local itemCount = Utility.GlobalPlayerDataTable[ownerId].inventory[itemName]
    local unformattedQuantity = tonumber(desiredQuantity)
    if (not unformattedQuantity) then
        return {statusCode = -1, message = "Quantity must be a positive integer."}
    end
    
    local quantity = math.floor(unformattedQuantity + 0.5)

    -- validate quantity
    if quantity <= 0 then
        return {statusCode = -1, message = "Quantity must be a positive integer."}
    end

    -- we must flip the order type since we are filling, not placing
    local orderFillType = nil
    if transactionType == SharedUtility.TransactionType.BuyOrder then
        orderFillType = SharedUtility.TransactionType.SellOrder
    elseif transactionType == SharedUtility.TransactionType.SellOrder then
        orderFillType = SharedUtility.TransactionType.BuyOrder

        if (desiredQuantity > itemCount) then
            return {statusCode = -1, message = "You do not have enough of " .. itemName .. " to complete this market order."}
        end
    end

    local validatedOrderDetails = {
        ownerId = tostring(ownerId),
        ownerName = ownerName,
        desiredQuantity = tostring(desiredQuantity),
        itemType = tostring(itemType),
        transactionType = tostring(orderFillType),
        availableFunds = tostring(playerFunds),
        partialFill = false
        -- partialFill = partialFill and "true" or "false"
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

            Utility.UpdatePlayerData(player, -formattedSpentFunds, {[itemName] = desiredQuantity})
            return {statusCode = 1, message = responseData[2]}
        end
    end

    return {statusCode = -1, message = response.Body}
end

function Utility.CancelOrder(player, transactionId)
    local playerId = player.UserId

    local cancelDetails = {
        transactionId = tostring(transactionId),
        ownerId = tostring(playerId)
    }

    local response = nil
    local httpSuccess, statusMessage = pcall(function() 
        response = HttpService:RequestAsync({
            Url = serverAddress..endpoints["cancelOrder"],
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode(cancelDetails)
        })
    end)

    if httpSuccess and response.StatusCode == 200 then
        local responseData = nil
        local canceledTransaction = nil
        local jsonSuccess, errorMessage = pcall(function() 
            responseData = HttpService:JSONDecode(response.Body)
            canceledTransaction = HttpService:JSONDecode(responseData[1])
        end)
        
        if jsonSuccess then
            local returnedFunds = canceledTransaction.remainingQuantity * canceledTransaction.price
            local returnedQuantity = canceledTransaction.remainingQuantity
            local itemName = canceledTransaction.itemType
            local transactionType = canceledTransaction.transactionType
            if SharedUtility.TransactionType[transactionType] == SharedUtility.TransactionType.SellOrder then
                returnedFunds = 0
            else
                returnedQuantity = 0
            end

            print(canceledTransaction.remainingQuantity)
            Utility.RemovePlayerOrder(playerId, transactionId)
            Utility.UpdatePlayerData(player, returnedFunds, {[itemName] = returnedQuantity})
            return {statusCode = 1, message = responseData[2]}
        end
    end

    return {statusCode = -1, message = response.Body}
end

function Utility.UpdateOrderStatus()
    -- TODO: send list of entire transaction instead of just IDs
        -- then on Java backend only return transactions which are out of date
    local orderIdList = {}
    local listIsEmpty = true
    for userId, data in pairs(Utility.GlobalPlayerDataTable) do
        local playerPendingOrderIds = {}
        for orderId, transaction in pairs(data.pendingPlayerOrders) do 
            table.insert(playerPendingOrderIds, transaction.transactionId)
        end

        if #playerPendingOrderIds ~= 0 then
            orderIdList[userId] = playerPendingOrderIds
            listIsEmpty = false
        end
    end

    if listIsEmpty then
        return
    end
    
    local response = nil
    local httpSuccess, statusMessage = pcall(function() 
        response = HttpService:RequestAsync({
            Url = serverAddress..endpoints["getOrderStatus"],
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode(orderIdList)
        })
    end)

    if httpSuccess and response.StatusCode == 200 then
        local responseData = nil
        local jsonSuccess, errorMessage = pcall(function() 
            responseData = HttpService:JSONDecode(response.Body)
        end)

        if jsonSuccess then
            local playerPendingOrders = responseData
            for userId, transactionList in pairs(playerPendingOrders) do
                userId = tonumber(userId)
                local player = Players:GetPlayerByUserId(userId)
                local playerData = Utility.GlobalPlayerDataTable[userId]
                local oldPlayerOrders = playerData.pendingPlayerOrders
                for _, updatedTransaction in ipairs(transactionList) do
                    if oldPlayerOrders[updatedTransaction.transactionId] == nil then
                        -- order was canceled
                        continue
                    end

                    local newQuantity = updatedTransaction.remainingQuantity
                    local oldQuantity = oldPlayerOrders[updatedTransaction.transactionId].remainingQuantity
                    local quantityDiff = oldQuantity - newQuantity
                    if quantityDiff == 0 then
                        -- order status has not changed
                        continue
                    end
                    print(updatedTransaction.transactionType)
                    local earnedCurrency = quantityDiff * updatedTransaction.price
                    local earnedItemQuantity = quantityDiff
                    if SharedUtility.TransactionType[updatedTransaction.transactionType] == SharedUtility.TransactionType.BuyOrder then
                        earnedCurrency = 0
                    else
                        earnedItemQuantity = 0
                    end

                    local itemName = updatedTransaction.itemType
                    if updatedTransaction.remainingQuantity == 0 then
                        -- transaction has been fulfilled and must be deleted
                        Utility.RemovePlayerOrder(userId, updatedTransaction.transactionId)
                    else
                        updatedTransaction.itemType = SharedUtility.ItemType[itemName]
                        Utility.GlobalPlayerDataTable[userId].pendingPlayerOrders[updatedTransaction.transactionId] = updatedTransaction
                    end
                    
                    Utility.UpdatePlayerData(player, earnedCurrency, {[itemName] = earnedItemQuantity})
                end
            end
        end
    end

    return {statusCode = -1, message = response.Body}
end

return Utility