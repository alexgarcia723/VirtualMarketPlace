local SharedUtility = {}
local ErrorMessageUI = game
SharedUtility.LocalPlayerData = nil
SharedUtility.ClientOrderHistories = nil

-- All these "Enums" should instead be generated from an HTTP request from the server.
SharedUtility.TransactionType = {
    BuyOrder = 0,
	SellOrder = 1,
	Buy = 2,
	Sell = 3
}

SharedUtility.TransactionTypeLookup = {
    [0] = "BuyOrder",
	[1] = "SellOrder",
	[2] = "Buy",
	[3] = "Sell"
}

SharedUtility.ItemTypeIcons = {
	Apple = "http://www.roblox.com/asset/?id=7892919616",
	Banana = "http://www.roblox.com/asset/?id=14334702049",
	Orange = "http://www.roblox.com/asset/?id=16098324319",
	Grape = "http://www.roblox.com/asset/?id=16098329149",
	Watermelon = "http://www.roblox.com/asset/?id=16098274639"
}

SharedUtility.ItemType = {
	Apple = 0,
	Banana = 1,
	Orange = 2,
	Grape = 3,
	Watermelon = 4
}

SharedUtility.ItemTypeLookup = {
	[0] = "Apple",
	[1] = "Banana",
	[2] = "Orange",
	[3] = "Grape",
	[4] = "Watermelon",
}

function SharedUtility.DisplayErrorMessage(message, errorLabel)
	errorLabel.Text = message
	errorLabel.Parent.Visible = true 
	task.wait(3)
	errorLabel.Parent.Visible = false 
end

function SharedUtility.GetRandomTransactionType()
    return Random.new():NextInteger(0, #SharedUtility.TransactionType)
end

function SharedUtility.GetLocalPlayerData()
	while not SharedUtility.LocalPlayerData do
		task.wait()
	end

	return SharedUtility.LocalPlayerData
end

-- The function used for deep copying a table
function SharedUtility.DeepCopy(original)
	-- Define the new table for the copy
	local copy = {}

	-- Loop through the original table to clone
	for key, value in original do
		-- If the type of the value is a table, deep copy it to the key (index)
		-- Else (or) the type isn't a table, assign the default value to the index instead
		copy[key] = type(value) == "table" and SharedUtility.DeepCopy(value) or value
	end

	-- Return the finalized copy of the deep cloned table
	return copy
end

return SharedUtility