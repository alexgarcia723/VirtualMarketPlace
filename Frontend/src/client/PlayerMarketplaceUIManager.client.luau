-- TODO: fix the SelectedOrderItemBackground aspect ratio when resizing
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
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
local errorFrame = marketplaceUI:FindFirstChild("ErrorFrame")
local errorLabel = errorFrame:FindFirstChild("ErrorLabel")

local buyView = mainPane:FindFirstChild("BuyView")
local sellView = mainPane:FindFirstChild("SellView")

local buyViewOrdersList = buyView:FindFirstChild("OrdersListScrollFrame")
local sellViewOrdersList = sellView:FindFirstChild("OrdersListScrollFrame")

local orderItemSelectionFrame = mainPane:FindFirstChild("SelectedOrderItemBackground")
local orderDetailsFrame = mainPane:FindFirstChild("OrderInfoBackground")
local itemViewPane = mainPane:FindFirstChild("ItemView")
local itemViewItemIcon = itemViewPane:FindFirstChild("SelectedItemIcon")
local itemSelectFrame = marketplaceUI:FindFirstChild("MainPaneItemSelect")
local itemSelectListFrame = itemSelectFrame:FindFirstChild("ItemListScrollFrame")

local buyOrderTemplate = buyView:FindFirstChild("TemplateOrderLine")
local sellOrderTemplate = sellView:FindFirstChild("TemplateOrderLine")
local selectItemTemplate = itemSelectFrame:FindFirstChild("TemplateOrderLine")

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

local placeOrderPriceTextbox = orderDetailsFrame:FindFirstChild("PriceTextbox")
local placeOrderQuantityTextbox = orderDetailsFrame:FindFirstChild("QuantityTextbox")
local placeOrderButton = orderDetailsFrame:FindFirstChild("PlaceOrderButton")
local selectOrderItemButton = orderItemSelectionFrame:FindFirstChild("SelectOrderItemButton")
local toggleBuyOrderButton = orderDetailsFrame:FindFirstChild("SelectBuyToggle")
local toggleSellOrderButton = orderDetailsFrame:FindFirstChild("SelectSellToggle")

local selectedItemIcon = orderItemSelectionFrame:FindFirstChild("SelectedItemIcon")
local selectedItemLabel = orderItemSelectionFrame:FindFirstChild("SelectedItemLabel")

local marketOrderBackground = mainPane:FindFirstChild("FilterBackground")
local marketOrderQuantityTextbox = marketOrderBackground:FindFirstChild("QuantityTextBox")
local marketOrderBuyButton = marketOrderBackground:FindFirstChild("BuyButton")
local marketOrderSellButton = marketOrderBackground:FindFirstChild("SellButton")

-- UI variables
local numberOfOrdersPerPage = math.floor(1 / buyOrderTemplate.Size.Y.Scale + 0.5)
local sellViewPageNumber = 1
local buyViewPageNumber = 1
local viewingItemType = SharedUtility.ItemType.Apple -- TODO: i think we can combine viewingItemType and selectedOrderItemType
local selectedOrderItemType = SharedUtility.ItemType.Apple
local selectedTransactionType = nil
local currentlyFocusedOrderLine = nil
local UnselectedColor = Color3.fromRGB(60, 118, 193)
local SelectedColor = Color3.fromRGB(79, 158, 255)


local function UpdateOrderList(orderType, itemType, pageNumber, numberOfOrdersPerPage) -- TODO: should this send combined HTTP request for sell AND buy orders?
    local resultList = getOrdersPage:InvokeServer(orderType, itemType, pageNumber)
    local ordersViewList

    if orderType == SharedUtility.TransactionType.BuyOrder then
        ordersViewList = buyViewOrdersList
    elseif orderType == SharedUtility.TransactionType.SellOrder then
        ordersViewList = sellViewOrdersList
    end

    for i = 1, numberOfOrdersPerPage do
        local orderLine = ordersViewList[i]
        orderLine.OrderButton.NumberLabel.Text = i + (buyViewPageNumber - 1) * numberOfOrdersPerPage
        if resultList and resultList[i] then
            -- update order text with data from server
            orderLine.OwnerIdLabel.Text = resultList[i].ownerName and resultList[i].ownerName or "Anonymoose"
            orderLine.QuantityLabel.Text = resultList[i].remainingQuantity.."/"..resultList[i].originalQuantity
            orderLine.PriceLabel.Text = resultList[i].price
            orderLine:SetAttribute("TransactionId", resultList[i].transactionId)
            orderLine:SetAttribute("Price", resultList[i].price)
            orderLine:SetAttribute("RemainingQuantity", resultList[i].remainingQuantity)
        else
            -- set order text to be blank
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
    elseif viewType == 2 then
        sellViewPageNumber += 1
        sellViewPageLabel.Text = sellViewPageNumber
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
        toggleBuyOrderButton.BackgroundColor3 = UnselectedColor
        -- toggleBuyOrderButton.BorderSizePixel = 0
        selectedTransactionType = nil
    else
        -- toggleBuyOrderButton.BorderSizePixel = 5
        toggleBuyOrderButton.BackgroundColor3 = SelectedColor
        -- toggleSellOrderButton.BorderSizePixel = 0
        toggleSellOrderButton.BackgroundColor3 = UnselectedColor
        selectedTransactionType = SharedUtility.TransactionType.BuyOrder
    end
end

local function SetOrderSellSelection()
    if selectedTransactionType == SharedUtility.TransactionType.SellOrder then
        -- toggleSellOrderButton.BorderSizePixel = 0
        toggleSellOrderButton.BackgroundColor3 = UnselectedColor
        selectedTransactionType = nil
    else
        -- toggleSellOrderButton.BorderSizePixel = 5
        toggleSellOrderButton.BackgroundColor3 = SelectedColor
        -- toggleBuyOrderButton.BorderSizePixel = 0
        toggleBuyOrderButton.BackgroundColor3 = UnselectedColor
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
        if placeOrderResult.statusCode ~= -1 then
            UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemType, buyViewPageNumber, numberOfOrdersPerPage)
            UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemType, sellViewPageNumber, numberOfOrdersPerPage)
        else 
            task.spawn(SharedUtility.DisplayErrorMessage, placeOrderResult.message, errorLabel)
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
        fillOrderConfirmationFrame.OrderItemLabel.Text = "Order Item: " .. SharedUtility.ItemTypeLookup[selectedOrderItemType]
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
                local fillOrderResult = fillOrder:InvokeServer(transactionId, desiredQuantity, price, transactionType, viewingItemType)
                if fillOrderResult.statusCode ~= -1 then
                    UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemType, buyViewPageNumber, numberOfOrdersPerPage)
                    UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemType, sellViewPageNumber, numberOfOrdersPerPage)
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
        local result = marketFillOrder:InvokeServer(viewingItemType, transactionType, desiredQuantity, false)
        if result.statusCode ~= -1 then
            UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemType, buyViewPageNumber, numberOfOrdersPerPage)
            UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemType, sellViewPageNumber, numberOfOrdersPerPage)
        else
            task.spawn(SharedUtility.DisplayErrorMessage, result.message, errorLabel)
        end
    end
end

local function UpdateItemSelection(itemName)
    viewingItemType = SharedUtility.ItemType[itemName]
    selectedOrderItemType = SharedUtility.ItemType[itemName]

    selectedItemIcon.Image = SharedUtility.ItemTypeIcons[itemName]
    itemViewItemIcon.Image = SharedUtility.ItemTypeIcons[itemName]
    selectedItemLabel.Text = itemName

    -- update page text
    sellViewPageNumber = 1
    buyViewPageNumber = 1
    buyViewPageLabel.Text = buyViewPageNumber
    sellViewPageLabel.Text = sellViewPageNumber
    
    itemSelectFrame.Visible = false
    UpdateOrderList(SharedUtility.TransactionType.BuyOrder, viewingItemType, buyViewPageNumber, numberOfOrdersPerPage) -- TODO: access cached item page instead of sending new HTTP request
    UpdateOrderList(SharedUtility.TransactionType.SellOrder, viewingItemType, sellViewPageNumber, numberOfOrdersPerPage) -- TODO: access cached item page instead of sending new HTTP request
end

local function UpdateItemSelectPane()
    for _, orderLine in ipairs(itemSelectListFrame:GetChildren()) do
        if (not orderLine:IsA("UIListLayout")) then
            local itemName = orderLine:GetAttribute("ItemName")
            orderLine.PriceLabel.Text = 0 -- TODO: GET AVERAGE/MINIMUM PRICE FROM SERVER USING itemName
            orderLine.QuantitySelect.QuantityLabel.Text = 0 -- TODO: GET NUMBERS OF ITEM FOR SALE FROM SERVER USING itemName
        end
    end
end

local function InitializeItemSelectPane()
    for _, child in ipairs(itemSelectListFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    for itemName, iconURL in pairs(SharedUtility.ItemTypeIcons) do
        local orderLine = selectItemTemplate:Clone()
        orderLine.ItemIconFrame.ItemIcon.Image = iconURL
        orderLine.Name = itemName .. "Line"
        orderLine.ItemName.Text = itemName
        orderLine.Parent = itemSelectListFrame
        orderLine:SetAttribute("ItemName", itemName)
        orderLine.Visible = true
        orderLine.QuantitySelect.SelectButton.MouseButton1Click:Connect(function() UpdateItemSelection(itemName) end)
    end

    UpdateItemSelectPane()
    UpdateItemSelection(SharedUtility.ItemTypeLookup[viewingItemType])
end

local function DisplaySelectOrderItem() 
    itemSelectFrame.Visible = true
end

local function InitializeUI()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

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
selectOrderItemButton.MouseButton1Click:Connect(DisplaySelectOrderItem)

InitializeUI()