local Players = game:GetService("Players")

local player = Players.LocalPlayer
local marketplaceUI = player.PlayerGui:WaitForChild("MarketplaceUI")

-- UI buttons/textboxes
local mainPane = marketplaceUI:FindFirstChild("MainPane")
local buyView = mainPane:FindFirstChild("BuyView")
local sellView = mainPane:FindFirstChild("SellView")
local buyViewOrdersList = buyView:FindFirstChild("OrdersListScrollFrame")
local sellViewOrdersList = sellView:FindFirstChild("OrdersListScrollFrame")
local buyOrderTemplate = buyView:FindFirstChild("TemplateOrderLine")
local sellOrderTemplate = sellView:FindFirstChild("TemplateOrderLine")

local function InitializeUI()
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

    -- populate order frames
    local numberOfOrdersPerPage = math.floor(1 / buyOrderTemplate.Size.Y.Scale + 0.5)
    for i = 1, numberOfOrdersPerPage do
        local orderLine = buyOrderTemplate:Clone()
        orderLine.OrderButton.NumberLabel.Text = i
        orderLine.Visible = true
        orderLine.Parent = buyViewOrdersList
    end

    for i = 1, numberOfOrdersPerPage do
        local orderLine = sellOrderTemplate:Clone()
        orderLine.OrderButton.NumberLabel.Text = i
        orderLine.Visible = true
        orderLine.Parent = sellViewOrdersList
    end
end

InitializeUI()