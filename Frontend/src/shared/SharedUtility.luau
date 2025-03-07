local SharedUtility = {}

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

function SharedUtility.GetRandomTransactionType()
    return Random.new():NextInteger(0, #SharedUtility.TransactionType)
end

return SharedUtility