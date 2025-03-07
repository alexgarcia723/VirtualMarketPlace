local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local getOrdersPage = remotesFolder:FindFirstChild("GetOrdersPage")
local placeOrder = remotesFolder:FindFirstChild("PlaceOrder")
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
local orderConfirmationFrame = marketplaceUI:FindFirstChild("ConfirmationPane")
local orderItemSelectionFrame = mainPane:FindFirstChild("SelectedOrderItemBackground")
local orderDetailsFrame = mainPane:FindFirstChild("OrderInfoBackground")
local confirmOrderButton = orderConfirmationFrame:FindFirstChild("ConfirmOrderButton")
local cancelOrderButton = orderConfirmationFrame:FindFirstChild("CancelOrderButton")

local priceTextbox = orderDetailsFrame:FindFirstChild("PriceTextbox")
local quantityTextbox = orderDetailsFrame:FindFirstChild("QuantityTextbox")
local placeOrderButton = orderDetailsFrame:FindFirstChild("PlaceOrderButton")
local selectOrderItemButton = orderItemSelectionFrame:FindFirstChild("SelectOrderItemButton")
local toggleBuyOrderButton = orderDetailsFrame:FindFirstChild("SelectBuyToggle")
local toggleSellOrderButton = orderDetailsFrame:FindFirstChild("SelectSellToggle")

-- UI variables
local numberOfOrdersPerPage = math.floor(1 / buyOrderTemplate.Size.Y.Scale + 0.5)
local sellViewPageNumber = 1
local buyViewPageNumber = 1
local viewingItemId = "Apple"
local selectedOrderItemId = "Apple"
local selectedTransactionType = nil

local function UpdateOrderList(orderType, itemId, pageNumber, numberOfOrdersPerPage)
    local resultList = getOrdersPage:InvokeServer(orderType, itemId, pageNumber)
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
            orderLine.OwnerIdLabel.Text = resultList[i].ownerId
            orderLine.QuantityLabel.Text = resultList[i].remainingQuantity.."/"..resultList[i].originalQuantity
            orderLine.PriceLabel.Text = resultList[i].price
        else
            -- set order text to be blank
            local orderLine = ordersViewList[i] 
            orderLine.OwnerIdLabel.Text = "---"
            orderLine.QuantityLabel.Text = "---/---"
            orderLine.PriceLabel.Text = "$---"
        end
    end
end

local function NextPage(viewType)
    if viewType == 1 then
        buyViewPageNumber += 1
        buyViewPageLabel.Text = buyViewPageNumber
        UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemId, buyViewPageNumber, numberOfOrdersPerPage)

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
        UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemId, sellViewPageNumber, numberOfOrdersPerPage)
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
        UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemId, buyViewPageNumber, numberOfOrdersPerPage)
    elseif viewType == 2 and sellViewPageNumber > 1 then
        sellViewPageNumber -= 1
        sellViewPageLabel.Text = sellViewPageNumber

        for i = 1, numberOfOrdersPerPage do
            local orderLine = sellViewOrdersList[i]
            orderLine.OrderButton.NumberLabel.Text = i + (sellViewPageNumber - 1)*numberOfOrdersPerPage
        end
        UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemId, sellViewPageNumber, numberOfOrdersPerPage)
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

local function OrderDetailsValid()
    if selectedTransactionType == nil then
        return false
    end
    if selectedOrderItemId == "" then
        return false
    end
    if not tonumber(quantityTextbox.Text) then
        return false
    end
    if not tonumber(priceTextbox.Text) then
        return false
    end

    return true
end

local function DisplayOrderPlaceConfirmation()
    if OrderDetailsValid() then 
        orderConfirmationFrame.OrderItemLabel.Text = "Order Item: " .. selectedOrderItemId
        orderConfirmationFrame.OrderTypeLabel.Text = "Order Type: " .. SharedUtility.TransactionTypeLookup[selectedTransactionType]
        orderConfirmationFrame.OrderPriceLabel.Text = "Order Price: " .. priceTextbox.Text
        orderConfirmationFrame.OrderQuantityLabel.Text = "Order Quantity: " .. quantityTextbox.Text
        orderConfirmationFrame.Visible = true
    else
        -- display some sort of error message
    end
end

local function ConfirmPlaceOrder()
    orderConfirmationFrame.Visible = false

    if OrderDetailsValid() then
        local transactionDetails = {
            transactionType = selectedTransactionType,
            itemId = selectedOrderItemId,
            quantity = quantityTextbox.Text,
            price = priceTextbox.Text
        }

        local placeOrderResult = placeOrder:InvokeServer(transactionDetails)
        if placeOrderResult then
            UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemId, buyViewPageNumber, numberOfOrdersPerPage)
            UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemId, sellViewPageNumber, numberOfOrdersPerPage)
        end
    end
end

local function CancelPlaceOrder()
    orderConfirmationFrame.Visible = false
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
    end

    for i = 1, numberOfOrdersPerPage do
        local orderLine = sellOrderTemplate:Clone()
        orderLine.OrderButton.NumberLabel.Text = i
        orderLine.Visible = true
        orderLine.Name = i
        orderLine.Parent = sellViewOrdersList
    end

    -- get page from database and display it in our order list frames
    UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemId, buyViewPageNumber, numberOfOrdersPerPage)
    UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemId, sellViewPageNumber, numberOfOrdersPerPage)
end


buyViewPrevPageButton.MouseButton1Click:Connect(function() PreviousPage(1) end)
sellViewPrevPageButton.MouseButton1Click:Connect(function() PreviousPage(2) end)
buyViewNextPageButton.MouseButton1Click:Connect(function() NextPage(1) end)
sellViewNextPageButton.MouseButton1Click:Connect(function() NextPage(2) end)
toggleBuyOrderButton.MouseButton1Click:Connect(SetOrderBuySelection)
toggleSellOrderButton.MouseButton1Click:Connect(SetOrderSellSelection)
confirmOrderButton.MouseButton1Click:Connect(ConfirmPlaceOrder)
cancelOrderButton.MouseButton1Click:Connect(CancelPlaceOrder)
placeOrderButton.MouseButton1Click:Connect(DisplayOrderPlaceConfirmation)

InitializeUI()