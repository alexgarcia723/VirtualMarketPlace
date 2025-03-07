local SharedUtility = {}

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

function SharedUtility.GetRandomTransactionType()
    return Random.new():NextInteger(0, #SharedUtility.TransactionType)
end

return SharedUtility