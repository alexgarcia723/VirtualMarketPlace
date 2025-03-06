local Players = game:GetService("Players")
-- local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")

-- local MarketplaceUI = ServerStorage:FindFirstChild("MarketplaceUI")
local MarketplaceTempalateUI = StarterGui:FindFirstChild("MarketplaceUI")

local function InitializePlayer(player)
    local marketplaceUI = MarketplaceTempalateUI:Clone()
    marketplaceUI.Parent = player.PlayerGui


end

Players.PlayerAdded:Connect(InitializePlayer)