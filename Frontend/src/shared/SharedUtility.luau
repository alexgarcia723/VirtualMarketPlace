local SharedUtility = {}

-- All these "Enums" should instead be generated from an HTTP request from the server.
SharedUtility.TransactionType = {
    BuyOrder = 0,
	SellOrder = 1,
	Buy = 2,
	Sell = 3
}

SharedUtility.TransactionTypeLookup = {
    [0] = "Buy Order",
	[1] = "Sell Order",
	[2] = "Buy",
	[3] = "Sell"
}

SharedUtility.ItemTypeIcons = {
	Apple = "http://www.roblox.com/asset/?id=7892919616",
	Banana = "",
	Orange = "",
	Grape = "",
	Watermelon = ""
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

function SharedUtility.GetRandomTransactionType()
    return Random.new():NextInteger(0, #SharedUtility.TransactionType)
end

return SharedUtility