-- TODO: fix the SelectedOrderItemBackground aspect ratio when resizing
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local playerDataUpdate = remotesFolder:FindFirstChild("PlayerDataUpdate")
local requestCancelOrder = remotesFolder:FindFirstChild("RequestCancelOrder")
local notifyOrderCanceled = remotesFolder:FindFirstChild("NotifyOrderCancel")
local topbarUI = player.PlayerGui:WaitForChild("TopbarUI")
local inventoryUI = player.PlayerGui:WaitForChild("InventoryUI")
local marketplaceUI = player.PlayerGui:WaitForChild("MarketplaceUI")
local SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)

-- UI container frames
local currencyFrame = topbarUI:FindFirstChild("CurrencyFrame")
local inventoryFrame = inventoryUI:FindFirstChild("InventoryFrame")
local transactionContainer = inventoryFrame:FindFirstChild("TransactionContainer")
local inventoryItemTemplate = inventoryFrame:FindFirstChild("TemplateItemFrame")
local orderTemplate = inventoryFrame:FindFirstChild("TemplateOrderFrame")

-- UI variables

local function FormatNumber(n)
    return n:reverse():gsub("...","%0,",math.floor((#n-1)/3)):reverse()
end

local function SubmitOrderCancelRequest(orderLine)
    local transactionId = orderLine:GetAttribute("TransactionId")
    local result = requestCancelOrder:InvokeServer(transactionId)

    if result.statusCode ~= -1 then
        orderLine:Destroy()
        notifyOrderCanceled:Fire()
    else 
        -- could not cancel order: display error message 
    end
end

local function UpdateUI(data)
    SharedUtility.LocalPlayerData = data
    -- update currency
    -- local currencyStr = tostring(data.currency)
    -- local dollars = string.match(currencyStr, "(%d+).*%d*")
    -- local formattedDollars = FormatNumber(dollars)
    -- local remainderStr = string.match(currencyStr, "%d+.*(%d*)")
    -- local remainder = tonumber(remainderStr)
    -- currencyFrame.CurrencyLabel.Text = string.format("$%s.%02d", formattedDollars, remainder or 0)
    currencyFrame.CurrencyLabel.Text = string.format("$%.2f", data.currency)

    -- update inventory
    local inventoryData = data.inventory
    for itemName, quantity in pairs(inventoryData) do
        local itemFrame = inventoryFrame.ItemContainerFrame:FindFirstChild(itemName)
        itemFrame.ItemCount.Text = tostring(quantity)
    end

    -- update pending transactions
    local pendingPlayerOrders = data.pendingPlayerOrders
    for _, transaction in pairs(pendingPlayerOrders) do
        local orderLine = transactionContainer.OrdersList:FindFirstChild(transaction.transactionId) or orderTemplate:Clone()
        local itemName = SharedUtility.ItemTypeLookup[transaction.itemType]
        orderLine.Name = transaction.transactionId
        orderLine.ItemFrame.ItemLabel.Text = itemName
        orderLine.ItemFrame.ImageLabel.Image = SharedUtility.ItemTypeIcons[itemName]
        orderLine.PriceLabel.Text = transaction.price
        orderLine.QuantityLabel.Text = transaction.remainingQuantity .. "/" .. transaction.originalQuantity
        orderLine.TimeLabel.Text = "---"

        if transaction.transactionType == SharedUtility.TransactionType.BuyOrder then
            orderLine.TypeFrame.BuyLabel.Visible = true
        else
            orderLine.TypeFrame.SellLabel.Visible = true
        end

        orderLine.Visible = true
        orderLine:SetAttribute("TransactionId", transaction.transactionId)
        orderLine.Parent = transactionContainer.OrdersList

        orderLine.TypeFrame.CancelButton.MouseButton1Click:Connect(function() SubmitOrderCancelRequest(orderLine) end)
    end
end

local function ToggleInventory()
    inventoryUI.Enabled = not inventoryUI.Enabled
    marketplaceUI.Enabled = not inventoryUI.Enabled
end

local function InitializeUI()
    for itemName, _ in pairs(SharedUtility.ItemType) do
        local itemFrame = inventoryItemTemplate:Clone()
        itemFrame.ItemIcon.Image = SharedUtility.ItemTypeIcons[itemName]
        itemFrame.ItemName.Text = itemName
        itemFrame.ItemCount.Text = "~~~"
        itemFrame.Name = itemName
        itemFrame.Visible = true
        itemFrame.Parent = inventoryFrame.ItemContainerFrame
    end
end

InitializeUI()

currencyFrame.InventoryButton.MouseButton1Click:Connect(ToggleInventory)
inventoryFrame.CloseButton.MouseButton1Click:Connect(ToggleInventory)
playerDataUpdate.OnClientEvent:Connect(UpdateUI)