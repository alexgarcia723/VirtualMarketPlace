-- TODO: fix the SelectedOrderItemBackground aspect ratio when resizing
-- TODO: replace huge item icon on top right with client order history tab from inventory
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)

local player = Players.LocalPlayer
-- remote events/functions
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local placeOrder = remotesFolder:FindFirstChild("PlaceOrder")
local fillOrder = remotesFolder:FindFirstChild("FillOrder")
local marketFillOrder = remotesFolder:FindFirstChild("MarketFillOrder")
local updateServerViewingPages = remotesFolder:FindFirstChild("UpdateServerViewingPages")
local updateClientPages = remotesFolder:FindFirstChild("UpdateClientPages")
local getNumOrdersPerPage = remotesFolder:FindFirstChild("GetNumOrdersPerPage")
local playerDataUpdate = remotesFolder:FindFirstChild("PlayerDataUpdate")
local requestCancelOrder = remotesFolder:FindFirstChild("RequestCancelOrder")
local updateClientItemOrderHistories = remotesFolder:FindFirstChild("UpdateClientItemOrderHistories")

-- screen GUIs
local marketplaceUI = player.PlayerGui:WaitForChild("MarketplaceUI")
local topbarUI = player.PlayerGui:WaitForChild("TopbarUI")

-- UI container frames
local mainPane = marketplaceUI:FindFirstChild("MainPane")
local errorFrame = marketplaceUI:FindFirstChild("ErrorFrame")
local errorLabel = errorFrame:FindFirstChild("ErrorLabel")

local orderListFrames = mainPane:FindFirstChild("OrderListFrames")
local buyView = orderListFrames:FindFirstChild("BuyView")
local sellView = orderListFrames:FindFirstChild("SellView")

local buyViewOrdersList = buyView:FindFirstChild("OrdersListScrollFrame")
local sellViewOrdersList = sellView:FindFirstChild("OrdersListScrollFrame")

local orderItemSelectionFrame = mainPane:FindFirstChild("SelectedOrderItemBackground")
local orderDetailsFrame = mainPane:FindFirstChild("OrderInfoBackground")
local historyFrame = mainPane:FindFirstChild("HistoryFrame")
local itemSelectFrame = marketplaceUI:FindFirstChild("MainPaneItemSelect")
local itemSelectListFrame = itemSelectFrame:FindFirstChild("ItemListScrollFrame")

local buyOrderTemplate = buyView:FindFirstChild("TemplateOrderFrame")
local sellOrderTemplate = sellView:FindFirstChild("TemplateOrderFrame")
local selectItemTemplate = itemSelectFrame:FindFirstChild("TemplateOrderFrame")

local buyViewListHeader = buyView:FindFirstChild("ListHeader")
local sellViewListHeader = sellView:FindFirstChild("ListHeader")

local transactionContainer = historyFrame:FindFirstChild("PendingOrdersContainer")
local pendingOrderTemplateFrame = transactionContainer:FindFirstChild("TemplateOrderFrame")
local currencyFrame = topbarUI:FindFirstChild("CurrencyFrame")

local orderHistory = historyFrame:FindFirstChild("ItemTransactionHistory")
local itemOrderHistoryList = orderHistory:FindFirstChild("OrdersList")

-- UI page buttons/labels
local buyViewPrevPageButton = buyViewListHeader.OrderButton:FindFirstChild("PreviousPageButton")
local sellViewPrevPageButton = sellViewListHeader.OrderButton:FindFirstChild("PreviousPageButton")
local buyViewNextPageButton = buyViewListHeader.OrderOwnerFrame:FindFirstChild("NextPageButton")
local sellViewNextPageButton = sellViewListHeader.OrderOwnerFrame:FindFirstChild("NextPageButton")

local buyViewPageLabel = buyView:FindFirstChild("PageLabel")
local sellViewPageLabel = sellView:FindFirstChild("PageLabel")

-- UI buy/sell order buttons/labels
local placeOrderConfirmationFrame = marketplaceUI:FindFirstChild("PlaceOrderConfirmationPane")
local confirmPlaceOrderButton = placeOrderConfirmationFrame:FindFirstChild("ConfirmOrderButton")
local cancelPlaceOrderButton = placeOrderConfirmationFrame:FindFirstChild("CancelOrderButton")

local fillOrderConfirmationFrame = marketplaceUI:FindFirstChild("FillOrderConfirmationPane")
local confirmFillOrderButton = fillOrderConfirmationFrame:FindFirstChild("ConfirmOrderButton")
local cancelFillOrderButton = fillOrderConfirmationFrame:FindFirstChild("CancelOrderButton")

local placeOrderPriceContainer = orderDetailsFrame:FindFirstChild("PriceSelectContainer")
local placeOrderPriceTextbox = placeOrderPriceContainer:FindFirstChild("PriceTextbox")
local placeOrderQuantityContainer = orderDetailsFrame:FindFirstChild("QuantitySelectContainer")
local placeOrderQuantityTextbox = placeOrderQuantityContainer:FindFirstChild("QuantityTextbox")
local placeOrderButton = orderDetailsFrame:FindFirstChild("PlaceOrderButton")
local selectOrderItemButton = orderItemSelectionFrame:FindFirstChild("SelectOrderItemButton")
local toggleBuyOrderButton = orderDetailsFrame:FindFirstChild("SelectBuyToggle")
local toggleSellOrderButton = orderDetailsFrame:FindFirstChild("SelectSellToggle")

local selectedItemIcon = orderItemSelectionFrame:FindFirstChild("SelectedItemIcon")
local selectedItemLabel = orderItemSelectionFrame:FindFirstChild("SelectedItemLabel")

local marketOrderBackground = mainPane:FindFirstChild("FilterBackground")
local quantitySelectContainer = marketOrderBackground:FindFirstChild("QuantitySelectContainer")
local marketOrderQuantityTextbox = quantitySelectContainer:FindFirstChild("QuantityTextbox")
local marketOrderBuyButton = marketOrderBackground:FindFirstChild("BuyButton")
local marketOrderSellButton = marketOrderBackground:FindFirstChild("SellButton")

-- UI variables
-- local numberOfOrdersPerPage = math.floor(1 / buyOrderTemplate.Size.Y.Scale + 0.5)
local numberOfOrdersPerPage = getNumOrdersPerPage:InvokeServer()
local sellPageIndex = 1
local buyPageIndex = 1
local selectedItemType = SharedUtility.ItemType.Apple
local selectedTransactionType = nil
local currentlyFocusedOrderLine = nil
local UnselectedColor = Color3.fromRGB(60, 118, 193)
local SelectedColor = Color3.fromRGB(79, 158, 255)
local viewingMarketplace = marketplaceUI.Enabled


local function WipeOrderLine(orderLine)
    -- reset order line to a blank state
    orderLine.OwnerIdLabel.Text = "---"
    orderLine.QuantityLabel.Text = "---/---"
    orderLine.PriceLabel.Text = "$---"
    orderLine:SetAttribute("TransactionId", nil)
    orderLine:SetAttribute("Price", nil)
    orderLine:SetAttribute("RemainingQuantity", nil)
end

local function GetTimeDisplay(currentTimeUnixMilliseconds, otherTimeUnixMilliseconds)
    local timediffSeconds= currentTimeUnixMilliseconds.UnixTimestamp - otherTimeUnixMilliseconds.UnixTimestamp
    local timeDiffObj = DateTime.fromUnixTimestamp(timediffSeconds):ToUniversalTime()
    local timeDiffMins = timeDiffObj.Minute

    if timeDiffMins < 1 then
        return "< 1 min"
    elseif timeDiffMins < 60 then
        return timeDiffObj.Minute .. " mins"
    elseif timeDiffMins < 1440 then
        return timeDiffObj.Hour .. " hours"
    else
        return timeDiffObj.Day .. " days"
    end
end

local function UpdateOrderPages(updateItemType, receivedBuyPageIndex, receivedSellPageIndex, orderPages)
    -- this method receives updated pages from server and updates the order list UI

    -- discard data if pages received are out of sync with client item selection
    if (updateItemType ~= selectedItemType) then
        return
    end

    -- update selected item label
    local playerData = SharedUtility.GetLocalPlayerData()
    local itemName = SharedUtility.ItemTypeLookup[selectedItemType]
    local itemCount = playerData.inventory[itemName]
    selectedItemLabel.Text = itemName .. " (" .. itemCount .. ")"

    if not orderPages then
        return
    end

    -- repopulate order lines
    local buyOrders = orderPages[1]
    local sellOrders = orderPages[2]
    for i = 1, numberOfOrdersPerPage do
        local buyOrderLine = buyViewOrdersList[i]
        local buyOrder = buyOrders and buyOrders[i]
        if buyOrder and receivedBuyPageIndex == buyPageIndex then
            buyOrderLine.OwnerIdLabel.Text = buyOrder.ownerName and buyOrder.ownerName or "DefaultMerchantID"
            buyOrderLine.QuantityLabel.Text = buyOrder.remainingQuantity.."/"..buyOrder.originalQuantity
            buyOrderLine.PriceLabel.Text = string.format("%.2f", buyOrder.price)
            buyOrderLine:SetAttribute("TransactionId", buyOrder.transactionId)
            buyOrderLine:SetAttribute("Price", buyOrder.price)
            buyOrderLine:SetAttribute("RemainingQuantity", buyOrder.remainingQuantity)
        else
            WipeOrderLine(buyOrderLine)
        end

        local sellOrderLine = sellViewOrdersList[i]
        local sellOrder = sellOrders and sellOrders[i]
        if sellOrder and receivedSellPageIndex == sellPageIndex then
            sellOrderLine.OwnerIdLabel.Text = sellOrder.ownerName and sellOrder.ownerName or "DefaultMerchantID"
            sellOrderLine.QuantityLabel.Text = sellOrder.remainingQuantity.."/"..sellOrder.originalQuantity
            sellOrderLine.PriceLabel.Text = string.format("%.2f", sellOrder.price)
            sellOrderLine:SetAttribute("TransactionId", sellOrder.transactionId)
            sellOrderLine:SetAttribute("Price", sellOrder.price)
            sellOrderLine:SetAttribute("RemainingQuantity", sellOrder.remainingQuantity)
        else
            WipeOrderLine(sellOrderLine)
        end
    end

    for _, orderLine in itemSelectListFrame:GetChildren() do
        if (not orderLine:IsA("UIListLayout")) then
            local orderLineItemName = orderLine:GetAttribute("ItemName")
            orderLine.QuantitySelect.QuantityLabel.Text = playerData.inventory[orderLineItemName]
        end
    end
end

local function ChangePage(viewType, increment)
    if viewType == 1 then
        buyPageIndex = math.max(1, buyPageIndex + increment)
        buyViewPageLabel.Text = buyPageIndex

        for i = 1, numberOfOrdersPerPage do
            local orderLine = buyViewOrdersList[i]
            orderLine.OrderButton.NumberLabel.Text = i + (buyPageIndex - 1) * numberOfOrdersPerPage
            WipeOrderLine(orderLine)
        end
    elseif viewType == 2 then
        sellPageIndex = math.max(1, sellPageIndex + increment)
        sellViewPageLabel.Text = sellPageIndex

        for i = 1, numberOfOrdersPerPage do
            local orderLine = sellViewOrdersList[i]
            orderLine.OrderButton.NumberLabel.Text = i + (sellPageIndex - 1) * numberOfOrdersPerPage
            WipeOrderLine(orderLine)
        end
    end

    updateServerViewingPages:FireServer(selectedItemType, buyPageIndex, sellPageIndex, viewingMarketplace)
end

local function SetOrderBuySelection()
    if selectedTransactionType == SharedUtility.TransactionType.BuyOrder then
        toggleBuyOrderButton.BackgroundColor3 = UnselectedColor
        toggleBuyOrderButton.BorderSizePixel = 0
        selectedTransactionType = nil
    else
        toggleBuyOrderButton.BorderSizePixel = 5
        toggleBuyOrderButton.BackgroundColor3 = SelectedColor
        toggleSellOrderButton.BorderSizePixel = 0
        toggleSellOrderButton.BackgroundColor3 = UnselectedColor
        selectedTransactionType = SharedUtility.TransactionType.BuyOrder
    end
end

local function SetOrderSellSelection()
    if selectedTransactionType == SharedUtility.TransactionType.SellOrder then
        toggleSellOrderButton.BorderSizePixel = 0
        toggleSellOrderButton.BackgroundColor3 = UnselectedColor
        selectedTransactionType = nil
    else
        toggleSellOrderButton.BorderSizePixel = 5
        toggleSellOrderButton.BackgroundColor3 = SelectedColor
        toggleBuyOrderButton.BorderSizePixel = 0
        toggleBuyOrderButton.BackgroundColor3 = UnselectedColor
        selectedTransactionType = SharedUtility.TransactionType.SellOrder
    end
end

local function PlaceOrderDetailsValid()
    if selectedTransactionType == nil then
        return false
    end
    if selectedItemType == "" then
        return false
    end
    if not tonumber(placeOrderQuantityTextbox.Text) then
        return false
    end
    if not tonumber(placeOrderPriceTextbox.Text) then
        return false
    end

    return true
end

local function DisplayOrderPlaceConfirmation()
    if PlaceOrderDetailsValid() then 
        placeOrderConfirmationFrame.OrderItemLabel.Text = "Order Item: " .. SharedUtility.ItemTypeLookup[selectedItemType]
        placeOrderConfirmationFrame.OrderTypeLabel.Text = "Order Type: " .. SharedUtility.TransactionTypeLookup[selectedTransactionType]
        placeOrderConfirmationFrame.OrderPriceLabel.Text = "Order Price: " .. placeOrderPriceTextbox.Text
        placeOrderConfirmationFrame.OrderQuantityLabel.Text = "Order Quantity: " .. placeOrderQuantityTextbox.Text
        placeOrderConfirmationFrame.Visible = true
        mainPane.Interactable = false
    else
        -- display some sort of error message
    end
end

local function ConfirmPlaceOrder()
    if PlaceOrderDetailsValid() then
        local transactionDetails = {
            transactionType = selectedTransactionType,
            itemType = selectedItemType,
            quantity = placeOrderQuantityTextbox.Text,
            price = placeOrderPriceTextbox.Text
        }

        local placeOrderResult = placeOrder:InvokeServer(transactionDetails)
        if placeOrderResult.statusCode ~= -1 then
            -- display success message
        else 
            task.spawn(SharedUtility.DisplayErrorMessage, placeOrderResult.message, errorLabel)
        end

        placeOrderConfirmationFrame.Visible = false
        mainPane.Interactable = true
    end
end

local function CancelPlaceOrder()
    placeOrderConfirmationFrame.Visible = false
    mainPane.Interactable = true
end

local function DisplayOrderFillConfirmation(orderLine)
    local otherTransactionId = orderLine:GetAttribute("TransactionId")
    if otherTransactionId ~= nil then
        currentlyFocusedOrderLine = orderLine;
        fillOrderConfirmationFrame.OrderItemLabel.Text = "Order Item: " .. SharedUtility.ItemTypeLookup[selectedItemType]
        fillOrderConfirmationFrame.OrderTypeLabel.Text = "Order Type: " .. SharedUtility.TransactionTypeLookup[orderLine:GetAttribute("TransactionType")]
        fillOrderConfirmationFrame.OrderPriceLabel.Text = "Order Price: " .. orderLine:GetAttribute("Price")
        fillOrderConfirmationFrame.QuantityFrame.OrderQuantitySelect.PlaceholderText = "Remaining quantity ..."
        fillOrderConfirmationFrame.QuantityFrame.OrderQuantitySelect.Text = ""
        fillOrderConfirmationFrame.QuantityFrame.RemainingQuantity.Text = "Available: " .. orderLine:GetAttribute("RemainingQuantity")
        fillOrderConfirmationFrame.Visible = true
    else
        currentlyFocusedOrderLine = nil
    end
end

local function ConfirmFillOrder()
    if currentlyFocusedOrderLine ~= nil then
        local desiredQuantity = tonumber(fillOrderConfirmationFrame.QuantityFrame.OrderQuantitySelect.Text)
        local transactionId = currentlyFocusedOrderLine:GetAttribute("TransactionId")
        local remainingQuantity = currentlyFocusedOrderLine:GetAttribute("RemainingQuantity")
        local price = currentlyFocusedOrderLine:GetAttribute("Price")
        local transactionType = currentlyFocusedOrderLine:GetAttribute("TransactionType")

        if desiredQuantity and desiredQuantity > 0 and desiredQuantity % 1 == 0 and desiredQuantity <= remainingQuantity then
            if transactionId then
                local fillOrderResult = fillOrder:InvokeServer(transactionId, desiredQuantity, price, transactionType, selectedItemType)
                if fillOrderResult.statusCode ~= -1 then
                    -- display success message
                else 
                    task.spawn(SharedUtility.DisplayErrorMessage, fillOrderResult.message, errorLabel)
                end
                
                fillOrderConfirmationFrame.Visible = false
                currentlyFocusedOrderLine = nil
            end
        else
            SharedUtility.DisplayErrorMessage("The requested quantity amount is invalid.", errorLabel)
        end
    end

end

local function CancelFillOrder()
    fillOrderConfirmationFrame.Visible = false
    currentlyFocusedOrderLine = nil
end

local function PlaceMarketOrder(transactionType) 
    local desiredQuantity = tonumber(marketOrderQuantityTextbox.Text)

    if desiredQuantity ~= nil then
        local result = marketFillOrder:InvokeServer(selectedItemType, transactionType, desiredQuantity, false)
        if result.statusCode ~= -1 then
            -- display success message
        else
            task.spawn(SharedUtility.DisplayErrorMessage, result.message, errorLabel)
        end
    end
end


local function DisplaySelectOrderItem()
    itemSelectFrame.Visible = not itemSelectFrame.Visible
end

local function UpdateMarketplaceViewingStatus()
    viewingMarketplace = marketplaceUI.Enabled;
    updateServerViewingPages:FireServer(selectedItemType, buyPageIndex, sellPageIndex, viewingMarketplace)
end

local function RemoveFulfilledOrders(transactionList)
    for _, orderLine in transactionContainer.OrdersList:GetChildren() do
        if orderLine:IsA("Frame") then
            local transactionId = orderLine:GetAttribute("TransactionId")
            local orderExists = false
            for _, transaction in transactionList do
                if transactionId == transaction.transactionId then
                    orderExists = true
                    break
                end
            end

            if not orderExists then
                orderLine:Destroy()
            end
        end
    end
end

local function UpdateItemOrderHistories(itemOrderHistoryData)
    if itemOrderHistoryData ~= nil then
        SharedUtility.ClientOrderHistories = itemOrderHistoryData
    else
        if SharedUtility.ClientOrderHistories == nil then
            return
        end
    end

    local itemName = SharedUtility.ItemTypeLookup[selectedItemType]
    local orderHistoryData = SharedUtility.ClientOrderHistories[itemName]
    local buyTransactionTypeName = SharedUtility.TransactionTypeLookup[SharedUtility.TransactionType.Buy]
    local historyListChildren = itemOrderHistoryList:GetChildren()
    local index = 1
    local currentTime = DateTime.now()
    for _, orderFrame in pairs(historyListChildren) do
        if orderFrame:IsA("Frame") then
            local orderHistoryEntry = orderHistoryData[index]
            if orderHistoryEntry then
                orderFrame.OwnerIdLabel.Text = orderHistoryEntry.ownerName
                orderFrame.PriceLabel.Text = orderHistoryEntry.price
                orderFrame.QuantityLabel.Text = orderHistoryEntry.originalQuantity
                orderFrame.TimeLabel.Text = GetTimeDisplay(currentTime, DateTime.fromIsoDate(orderHistoryEntry.timestamp))
                orderFrame.LayoutOrder = index
                if orderHistoryEntry.transactionType == buyTransactionTypeName then
                    orderFrame.TypeFrame.BuyType.Visible = true
                    orderFrame.TypeFrame.SellType.Visible = false
                else
                    orderFrame.TypeFrame.SellType.Visible = true
                    orderFrame.TypeFrame.BuyType.Visible = false
                end
                orderFrame.Visible = true
            else
                orderFrame.Visible = false
            end
            index += 1
        end
    end
end

local function UpdateItemSelection(itemName)
    local playerData = SharedUtility.GetLocalPlayerData()
    local itemCount = playerData.inventory[itemName]

    selectedItemType = SharedUtility.ItemType[itemName]
    selectedItemType = SharedUtility.ItemType[itemName]

    selectedItemIcon.Image = SharedUtility.ItemTypeIcons[itemName]
    selectedItemLabel.Text = itemName .. " (" .. itemCount .. ")"

    -- update page text
    sellPageIndex = 1
    buyPageIndex = 1
    buyViewPageLabel.Text = buyPageIndex
    sellViewPageLabel.Text = sellPageIndex
    
    itemSelectFrame.Visible = false
    updateServerViewingPages:FireServer(selectedItemType, buyPageIndex, sellPageIndex, viewingMarketplace)
    UpdateItemOrderHistories()

end

local function SubmitOrderCancelRequest(orderLine)
    local transactionId = orderLine:GetAttribute("TransactionId")
    local result = requestCancelOrder:InvokeServer(transactionId)

    if result.statusCode ~= -1 then
        orderLine:Destroy()
        UpdateItemSelection(SharedUtility.ItemTypeLookup[selectedItemType])
    else 
        -- could not cancel order: display error message 
        task.spawn(SharedUtility.DisplayErrorMessage, result.message, errorLabel)
    end
end

local function UpdateOrderUI(data)
    SharedUtility.LocalPlayerData = data

    -- update currency
    currencyFrame.CurrencyLabel.Text = string.format("$%.2f", data.currency)

    -- update pending transactions
    local pendingPlayerOrders = data.pendingPlayerOrders
    for _, transaction in pairs(pendingPlayerOrders) do
        local orderLine = transactionContainer.OrdersList:FindFirstChild(transaction.transactionId) 
        if not orderLine then 
            orderLine = pendingOrderTemplateFrame:Clone()
            orderLine.TypeFrame.CancelButton.MouseButton1Click:Connect(function() 
                SubmitOrderCancelRequest(orderLine) 
            end)
        end

        local itemName = SharedUtility.ItemTypeLookup[transaction.itemType]
        orderLine.Name = transaction.transactionId
        orderLine.ItemFrame.ItemLabel.Text = itemName
        orderLine.ItemFrame.ImageLabel.Image = SharedUtility.ItemTypeIcons[itemName]
        orderLine.PriceLabel.Text = transaction.price
        orderLine.QuantityLabel.Text = transaction.remainingQuantity .. "/" .. transaction.originalQuantity

        local currentTime = DateTime.now()
        orderLine.TimeLabel.Text = GetTimeDisplay(currentTime, DateTime.fromIsoDate(transaction.timestamp))

        if transaction.transactionType == SharedUtility.TransactionType.BuyOrder then
            orderLine.TypeFrame.BuyLabel.Visible = true
        else
            orderLine.TypeFrame.SellLabel.Visible = true
        end

        orderLine.Visible = true
        orderLine:SetAttribute("TransactionId", transaction.transactionId)
        orderLine.Parent = transactionContainer.OrdersList
    end

    RemoveFulfilledOrders(data.pendingPlayerOrders)
end

local function InitializeItemSelectPane()
    for _, child in itemSelectListFrame:GetChildren() do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    local playerData = SharedUtility.GetLocalPlayerData()
    for itemName, iconURL in pairs(SharedUtility.ItemTypeIcons) do
        local orderLine = selectItemTemplate:Clone()
        orderLine.ItemIconFrame.ItemIcon.Image = iconURL
        orderLine.Name = itemName .. "Line"
        orderLine.ItemName.Text = itemName
        orderLine.Parent = itemSelectListFrame
        orderLine.QuantitySelect.QuantityLabel.Text = playerData.inventory[itemName]
        orderLine:SetAttribute("ItemName", itemName)
        orderLine.Visible = true
        orderLine.QuantitySelect.SelectButton.MouseButton1Click:Connect(function() UpdateItemSelection(itemName) end)
    end

    UpdateItemSelection(SharedUtility.ItemTypeLookup[selectedItemType])
end

local function InitializeUI()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    marketplaceUI.Enabled = true
    topbarUI.Enabled = true

    buyViewPageLabel.Text = buyPageIndex
    sellViewPageLabel.Text = sellPageIndex

    -- remove sample orders
    for _, child in sellViewOrdersList:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for _, child in buyViewOrdersList:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- populate order list frames with blank orders
    for i = 1, numberOfOrdersPerPage do
        local orderLine = buyOrderTemplate:Clone()
        orderLine.OrderButton.NumberLabel.Text = i
        orderLine.Name = i
        orderLine.Parent = buyViewOrdersList
        orderLine:SetAttribute("TransactionType", SharedUtility.TransactionType.Sell)
        orderLine.Visible = true
        orderLine.OrderButton.Execute.MouseButton1Click:Connect(function() DisplayOrderFillConfirmation(orderLine) end)
    end

    for i = 1, numberOfOrdersPerPage do
        local orderLine = sellOrderTemplate:Clone()
        orderLine.OrderButton.NumberLabel.Text = i
        orderLine.Name = i
        orderLine.Parent = sellViewOrdersList
        orderLine:SetAttribute("TransactionType", SharedUtility.TransactionType.Buy)
        orderLine.Visible = true
        orderLine.OrderButton.Execute.MouseButton1Click:Connect(function() DisplayOrderFillConfirmation(orderLine) end)
    end

    InitializeItemSelectPane()
    updateServerViewingPages:FireServer(selectedItemType, buyPageIndex, sellPageIndex, viewingMarketplace)
end

-- UI events
buyViewPrevPageButton.MouseButton1Click:Connect(function() ChangePage(1, -1) end)
sellViewPrevPageButton.MouseButton1Click:Connect(function() ChangePage(2, -1) end)
buyViewNextPageButton.MouseButton1Click:Connect(function() ChangePage(1, 1) end)
sellViewNextPageButton.MouseButton1Click:Connect(function() ChangePage(2, 1) end)
toggleBuyOrderButton.MouseButton1Click:Connect(SetOrderBuySelection)
toggleSellOrderButton.MouseButton1Click:Connect(SetOrderSellSelection)
confirmPlaceOrderButton.MouseButton1Click:Connect(ConfirmPlaceOrder)
cancelPlaceOrderButton.MouseButton1Click:Connect(CancelPlaceOrder)
confirmFillOrderButton.MouseButton1Click:Connect(ConfirmFillOrder)
cancelFillOrderButton.MouseButton1Click:Connect(CancelFillOrder)
marketOrderBuyButton.MouseButton1Click:Connect(function() PlaceMarketOrder(SharedUtility.TransactionType.BuyOrder) end)
marketOrderSellButton.MouseButton1Click:Connect(function() PlaceMarketOrder(SharedUtility.TransactionType.SellOrder) end)
placeOrderButton.MouseButton1Click:Connect(DisplayOrderPlaceConfirmation)
selectOrderItemButton.MouseButton1Click:Connect(DisplaySelectOrderItem)
marketplaceUI:GetPropertyChangedSignal("Enabled"):Connect(UpdateMarketplaceViewingStatus)

-- remote events
playerDataUpdate.OnClientEvent:Connect(UpdateOrderUI)
updateClientPages.OnClientEvent:Connect(UpdateOrderPages)
updateClientItemOrderHistories.OnClientEvent:Connect(UpdateItemOrderHistories)


InitializeUI()