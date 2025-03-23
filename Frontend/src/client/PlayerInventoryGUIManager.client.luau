-- TODO: fix the SelectedOrderItemBackground aspect ratio when resizing
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local playerDataUpdate = remotesFolder:FindFirstChild("PlayerDataUpdate")
local topbarUI = player.PlayerGui:WaitForChild("TopbarUI")
local inventoryUI = player.PlayerGui:WaitForChild("InventoryUI")
local marketplaceUI = player.PlayerGui:WaitForChild("MarketplaceUI")
local SharedUtility = require(ReplicatedStorage.Shared.SharedUtility)

-- UI container frames
local currencyFrame = topbarUI:FindFirstChild("CurrencyFrame")
local inventoryFrame = inventoryUI:FindFirstChild("InventoryFrame")
local inventoryItemTemplate = inventoryFrame:FindFirstChild("TemplateItemFrame")

-- UI variables

local function FormatNumber(n)
    return n:reverse():gsub("...","%0,",math.floor((#n-1)/3)):reverse()
end

local function UpdateUI(data)
    -- update currency
    -- local currencyStr = tostring(data.currency)
    -- local dollars = string.match(currencyStr, "(%d+).*%d*")
    -- local formattedDollars = FormatNumber(dollars)
    -- local remainderStr = string.match(currencyStr, "%d+.*(%d*)")
    -- local remainder = tonumber(remainderStr)
    -- currencyFrame.CurrencyLabel.Text = string.format("$%s.%02d", formattedDollars, remainder or 0)
    currencyFrame.CurrencyLabel.Text = string.format("$%.2f", data.currency)

    -- update inventory below
    local inventoryData = data.inventory
    for itemName, quantity in pairs(inventoryData) do
        local itemFrame = inventoryFrame.ItemContainerFrame:FindFirstChild(itemName)
        itemFrame.ItemCount.Text = tostring(quantity)
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