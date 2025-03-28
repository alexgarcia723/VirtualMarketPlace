API Info: 

/api/v1/getPages POST
	Input JSON Format:
	{
		<String> itemName1 = {
			<String> buyPageIndices = {
				<Integer> pageIndex1,
				...
			},
			<String> sellPageIndices = {
				<Integer> pageIndex1,
				...
			}	
		}, 
		...
	}

	Output JSON Format: 
	{
		<String> itemName2 = {
			<String> foundBuyPages = {
				<Integer> pageIndex1 = {
					<OrderTransction> order1,
					...
				}
			},
			<String> foundSellPages = {
				<Integer> pageIndex1 = {
					<OrderTransction> order1,
					...
				}
			}
		},
		...
	}
		

/api/v1/placeOrder POST
	Input JSON Format:
	{
		<TransactionType> transactionType = transactionTypeName,
		<ItemType> itemType = itemTypeName,
		<Integer> originalQuantity = originalQuantity,
		<Integer> remainingQuantity = remainingQuantity,
		<Double> price = price,
		<Integer> ownerId = ownerId,
		<String> ownerName = ownerName
	}
	
	Output JSON Format: 
 	{
		<String> orderId,
		<String> successMessage
	}
	
/api/v1/cancelOrder POST
	Input JSON Format:
	{
		<UUID> transactionId = transactionId,
		<Integer> ownerId = ownerId,
	}
	
	Output JSON Format: 
 	{
		<OrderTransaction> canceledTransaction = canceledTransaction,
		<String> successMessage
	}