local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local getOrdersPage = remotesFolder:FindFirstChild("GetOrdersPage")
local placeOrder = remotesFolder:FindFirstChild("PlaceOrder")
local fillOrder = remotesFolder:FindFirstChild("FillOrder")
local marketFillOrder = remotesFolder:FindFirstChild("MarketFillOrder")
local marketplaceUI = player.PlayerGui:WaitForChild("MarketplaceUI")

-- UI container frames
local mainPane = marketplaceUI:FindFirstChild("MainPane")

local buyView = mainPane:FindFirstChild("BuyView")
local sellView = mainPane:FindFirstChild("SellView")

local buyViewOrdersList = buyView:FindFirstChild("OrdersListScrollFrame")
local sellViewOrdersList = sellView:FindFirstChild("OrdersListScrollFrame")

local buyOrderTemplate = buyView:FindFirstChild("TemplateOrderLine")
local sellOrderTemplate = sellView:FindFirstChild("TemplateOrderLine")

local buyViewListHeader = buyView:FindFirstChild("ListHeader")
local sellViewListHeader = sellView:FindFirstChild("ListHeader")

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

local orderItemSelectionFrame = mainPane:FindFirstChild("SelectedOrderItemBackground")
local orderDetailsFrame = mainPane:FindFirstChild("OrderInfoBackground")

local placeOrderPriceTextbox = orderDetailsFrame:FindFirstChild("PriceTextbox")
local placeOrderQuantityTextbox = orderDetailsFrame:FindFirstChild("QuantityTextbox")
local placeOrderButton = orderDetailsFrame:FindFirstChild("PlaceOrderButton")
local selectOrderItemButton = orderItemSelectionFrame:FindFirstChild("SelectOrderItemButton")
local toggleBuyOrderButton = orderDetailsFrame:FindFirstChild("SelectBuyToggle")
local toggleSellOrderButton = orderDetailsFrame:FindFirstChild("SelectSellToggle")

local marketOrderBackground = mainPane:FindFirstChild("FilterBackground")
local marketOrderQuantityTextbox = marketOrderBackground:FindFirstChild("QuantityTextBox")
local marketOrderBuyButton = marketOrderBackground:FindFirstChild("BuyButton")
local marketOrderSellButton = marketOrderBackground:FindFirstChild("SellButton")

-- UI variables
local numberOfOrdersPerPage = math.floor(1 / buyOrderTemplate.Size.Y.Scale + 0.5)
local sellViewPageNumber = 1
local buyViewPageNumber = 1
local viewingItemType = SharedUtility.ItemType.Apple
local selectedOrderItemType = SharedUtility.ItemType.Apple
local selectedTransactionType = nil
local currentlyFocusedOrderLine = nil

local function UpdateOrderList(orderType, itemType, pageNumber, numberOfOrdersPerPage)
    local resultList = getOrdersPage:InvokeServer(orderType, itemType, pageNumber)
    local ordersViewList

    if orderType == SharedUtility.TransactionType.BuyOrder then
        ordersViewList = buyViewOrdersList
    elseif orderType == SharedUtility.TransactionType.SellOrder then
        ordersViewList = sellViewOrdersList
    end

    for i = 1, numberOfOrdersPerPage do
        if resultList[i] then
            -- update order text with data from server
            local orderLine = ordersViewList[i]
            orderLine.OwnerIdLabel.Text = resultList[i].ownerName and resultList[i].ownerName or "Anonymoose"
            orderLine.QuantityLabel.Text = resultList[i].remainingQuantity.."/"..resultList[i].originalQuantity
            orderLine.PriceLabel.Text = resultList[i].price
            orderLine:SetAttribute("TransactionId", resultList[i].transactionId)
            orderLine:SetAttribute("Price", resultList[i].price)
            orderLine:SetAttribute("RemainingQuantity", resultList[i].remainingQuantity)
        else
            -- set order text to be blank
            local orderLine = ordersViewList[i] 
            orderLine.OwnerIdLabel.Text = "---"
            orderLine.QuantityLabel.Text = "---/---"
            orderLine.PriceLabel.Text = "$---"
            orderLine:SetAttribute("TransactionId", nil)
            orderLine:SetAttribute("Price", nil)
            orderLine:SetAttribute("RemainingQuantity", nil)
        end
    end
end

local function NextPage(viewType)
    if viewType == 1 then
        buyViewPageNumber += 1
        buyViewPageLabel.Text = buyViewPageNumber
        UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemType, buyViewPageNumber, numberOfOrdersPerPage)

        for i = 1, numberOfOrdersPerPage do
            local orderLine = buyViewOrdersList[i]
            orderLine.OrderButton.NumberLabel.Text = i + (buyViewPageNumber - 1)*numberOfOrdersPerPage
        end
    elseif viewType == 2 then
        sellViewPageNumber += 1
        sellViewPageLabel.Text = sellViewPageNumber

        for i = 1, numberOfOrdersPerPage do
            local orderLine = sellViewOrdersList[i]
            orderLine.OrderButton.NumberLabel.Text = i + (sellViewPageNumber - 1)*numberOfOrdersPerPage
        end
        UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemType, sellViewPageNumber, numberOfOrdersPerPage)
    end
end

local function PreviousPage(viewType)
    if viewType == 1 and buyViewPageNumber > 1 then
        buyViewPageNumber -= 1
        buyViewPageLabel.Text = buyViewPageNumber

        for i = 1, numberOfOrdersPerPage do
            local orderLine = buyViewOrdersList[i]
            orderLine.OrderButton.NumberLabel.Text = i + (buyViewPageNumber - 1)*numberOfOrdersPerPage
        end
        UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemType, buyViewPageNumber, numberOfOrdersPerPage)
    elseif viewType == 2 and sellViewPageNumber > 1 then
        sellViewPageNumber -= 1
        sellViewPageLabel.Text = sellViewPageNumber

        for i = 1, numberOfOrdersPerPage do
            local orderLine = sellViewOrdersList[i]
            orderLine.OrderButton.NumberLabel.Text = i + (sellViewPageNumber - 1)*numberOfOrdersPerPage
        end
        UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemType, sellViewPageNumber, numberOfOrdersPerPage)
    end
end

local function SetOrderBuySelection()
    if selectedTransactionType == SharedUtility.TransactionType.BuyOrder then
        toggleBuyOrderButton.BorderSizePixel = 0
        selectedTransactionType = nil
    else
        toggleBuyOrderButton.BorderSizePixel = 5
        toggleSellOrderButton.BorderSizePixel = 0
        selectedTransactionType = SharedUtility.TransactionType.BuyOrder
    end
end

local function SetOrderSellSelection()
    if selectedTransactionType == SharedUtility.TransactionType.SellOrder then
        toggleSellOrderButton.BorderSizePixel = 0
        selectedTransactionType = nil
    else
        toggleSellOrderButton.BorderSizePixel = 5
        toggleBuyOrderButton.BorderSizePixel = 0
        selectedTransactionType = SharedUtility.TransactionType.SellOrder
    end
end

local function PlaceOrderDetailsValid()
    if selectedTransactionType == nil then
        return false
    end
    if selectedOrderItemType == "" then
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
        placeOrderConfirmationFrame.OrderItemLabel.Text = "Order Item: " .. selectedOrderItemType
        placeOrderConfirmationFrame.OrderTypeLabel.Text = "Order Type: " .. SharedUtility.TransactionTypeLookup[selectedTransactionType]
        placeOrderConfirmationFrame.OrderPriceLabel.Text = "Order Price: " .. placeOrderPriceTextbox.Text
        placeOrderConfirmationFrame.OrderQuantityLabel.Text = "Order Quantity: " .. placeOrderQuantityTextbox.Text
        placeOrderConfirmationFrame.Visible = true
    else
        -- display some sort of error message
    end
end

local function ConfirmPlaceOrder()

    if PlaceOrderDetailsValid() then
        local transactionDetails = {
            transactionType = selectedTransactionType,
            itemType = selectedOrderItemType,
            quantity = placeOrderQuantityTextbox.Text,
            price = placeOrderPriceTextbox.Text
        }

        local placeOrderResult = placeOrder:InvokeServer(transactionDetails)
        if placeOrderResult then
            UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemType, buyViewPageNumber, numberOfOrdersPerPage)
            UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemType, sellViewPageNumber, numberOfOrdersPerPage)
        end

        placeOrderConfirmationFrame.Visible = false
    end
end

local function CancelPlaceOrder()
    placeOrderConfirmationFrame.Visible = false
end

local function DisplayOrderFillConfirmation(orderLine)
    local otherTransactionId = orderLine:GetAttribute("TransactionId")
    if otherTransactionId ~= nil then
        currentlyFocusedOrderLine = orderLine;
        fillOrderConfirmationFrame.OrderItemLabel.Text = "Order Item: " .. selectedOrderItemType
        fillOrderConfirmationFrame.OrderTypeLabel.Text = "Order Type: " .. SharedUtility.TransactionTypeLookup[orderLine:GetAttribute("TransactionType")]
        fillOrderConfirmationFrame.OrderPriceLabel.Text = "Order Price: " .. orderLine:GetAttribute("Price")
        fillOrderConfirmationFrame.OrderQuantityLabel.PlaceholderText = "Quantity ..."
        fillOrderConfirmationFrame.OrderQuantityLabel.Text = ""
        fillOrderConfirmationFrame.Visible = true
    else
        currentlyFocusedOrderLine = nil
    end
end

local function ConfirmFillOrder()
    if currentlyFocusedOrderLine ~= nil then
        local desiredQuantity = tonumber(fillOrderConfirmationFrame.OrderQuantityLabel.Text)
        local transactionId = currentlyFocusedOrderLine:GetAttribute("TransactionId")
        local remainingQuantity = currentlyFocusedOrderLine:GetAttribute("RemainingQuantity")

        if desiredQuantity and desiredQuantity > 0 and desiredQuantity % 1 == 0 and desiredQuantity <= remainingQuantity then
            if transactionId then
                local fillOrderResult = fillOrder:InvokeServer(transactionId, desiredQuantity)
                if fillOrderResult then
                    UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemType, buyViewPageNumber, numberOfOrdersPerPage)
                    UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemType, sellViewPageNumber, numberOfOrdersPerPage)
                end
                
                fillOrderConfirmationFrame.Visible = false
                currentlyFocusedOrderLine = nil
            end
        else
            -- display quantity out of range method
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
        local result = marketFillOrder:InvokeServer(viewingItemType, transactionType, desiredQuantity, false)
        print(result)
    end
end

local function InitializeUI()
    buyViewPageLabel.Text = buyViewPageNumber
    sellViewPageLabel.Text = sellViewPageNumber

    -- remove sample orders
    for _, child in ipairs(sellViewOrdersList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for _, child in ipairs(buyViewOrdersList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- populate order list frames with blank orders
    for i = 1, numberOfOrdersPerPage do
        local orderLine = buyOrderTemplate:Clone()
        orderLine.OrderButton.NumberLabel.Text = i
        orderLine.Visible = true
        orderLine.Name = i
        orderLine.Parent = buyViewOrdersList
        orderLine:SetAttribute("TransactionType", SharedUtility.TransactionType.Sell)
        orderLine.OrderButton.Execute.MouseButton1Click:Connect(function() DisplayOrderFillConfirmation(orderLine) end)
    end

    for i = 1, numberOfOrdersPerPage do
        local orderLine = sellOrderTemplate:Clone()
        orderLine.OrderButton.NumberLabel.Text = i
        orderLine.Visible = true
        orderLine.Name = i
        orderLine.Parent = sellViewOrdersList
        orderLine:SetAttribute("TransactionType", SharedUtility.TransactionType.Buy)
        orderLine.OrderButton.Execute.MouseButton1Click:Connect(function() DisplayOrderFillConfirmation(orderLine) end)
    end

    -- get page from database and display it in our order list frames
    UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemType, buyViewPageNumber, numberOfOrdersPerPage)
    UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemType, sellViewPageNumber, numberOfOrdersPerPage)
end

buyViewPrevPageButton.MouseButton1Click:Connect(function() PreviousPage(1) end)
sellViewPrevPageButton.MouseButton1Click:Connect(function() PreviousPage(2) end)
buyViewNextPageButton.MouseButton1Click:Connect(function() NextPage(1) end)
sellViewNextPageButton.MouseButton1Click:Connect(function() NextPage(2) end)
toggleBuyOrderButton.MouseButton1Click:Connect(SetOrderBuySelection)
toggleSellOrderButton.MouseButton1Click:Connect(SetOrderSellSelection)
confirmPlaceOrderButton.MouseButton1Click:Connect(ConfirmPlaceOrder)
cancelPlaceOrderButton.MouseButton1Click:Connect(CancelPlaceOrder)
confirmFillOrderButton.MouseButton1Click:Connect(ConfirmFillOrder)
cancelFillOrderButton.MouseButton1Click:Connect(CancelFillOrder)
marketOrderBuyButton.MouseButton1Click:Connect(function() PlaceMarketOrder(SharedUtility.TransactionType.BuyOrder) end)
marketOrderSellButton.MouseButton1Click:Connect(function() PlaceMarketOrder(SharedUtility.TransactionType.SellOrder) end)
placeOrderButton.MouseButton1Click:Connect(DisplayOrderPlaceConfirmation)

InitializeUI()