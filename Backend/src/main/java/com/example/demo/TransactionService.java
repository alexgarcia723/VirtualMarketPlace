package com.example.demo;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


@Service
public class TransactionService {
	static private final TransactionType transactionEnums[] = TransactionType.values();
	static private final ItemType itemEnums[] = ItemType.values();
	private final TransactionRepository transactionRepository;

	@Autowired
	public TransactionService(TransactionRepository transactionRepository) throws IllegalStateException {
		this.transactionRepository = transactionRepository;
	}

	public UUID PlaceOrder(OrderTransaction transactionDetails) {
		// this method adds a new buy/sell order to PendingTransactions table
		if (transactionDetails.getPrice() <= 0) {
			throw new IllegalStateException("Price must be greater than 0");
		} else if (transactionDetails.getTransactionType() == null
				|| !transactionDetails.getTransactionType().isOrder()) {
			throw new IllegalStateException("Invalid or missing TransactionType value");
		} else if (transactionDetails.getItemType() == null) {
			throw new IllegalStateException("Invalid or missing ItemType value");
		} else if (transactionDetails.getOwnerId() <= 0) {
			throw new IllegalStateException("OwnerId value must be greater than 0");
		} else if (transactionDetails.getOriginalQuantity() <= 0) {
			throw new IllegalStateException("Quantity value cannot be less than 0");
		}

		// validation passed: save the order to the database
		transactionRepository.save(transactionDetails);
		return transactionDetails.getTransactionId();
	}

	@Transactional
	public double FillMarketOrder(int itemTypeIndex, int transactonTypeIndex, int desiredQuantity, int ownerId, double availableFunds, boolean partialFill) throws IllegalStateException {
		// WE PROBABLY SHOULD HAVE A MAXIMUM desiredQuantity BECAUSE WE DON'T WANT TO SEARCH THE ENTIRE TABLE (maybe limit to 1 page?)
		
		// this method processes the player's request to buy/sell certain quantity of an item from any available unfilled orders
		ItemType itemType = itemEnums[itemTypeIndex];
		TransactionType transactionType = transactionEnums[transactonTypeIndex];
		
		Pageable sortedByPriceAsc = PageRequest.of(0, 10, Sort.by("price").ascending());
		List<OrderTransaction> pendingTransactions = transactionRepository
				.findPendingByItemTypeAndTransactionType(itemType, transactionType, sortedByPriceAsc);
		
		double runningCost = 0;
		int satisfiedQuantity = 0;
		int unsatisfiedQuantity = desiredQuantity;
		
		// attempt to satisfy order with items on 1st page
		for (OrderTransaction transaction: pendingTransactions) {
			int remainingQuantity = transaction.getRemainingQuantity();
			if (remainingQuantity >= unsatisfiedQuantity) {
				runningCost += transaction.getPrice() * unsatisfiedQuantity;
				satisfiedQuantity += unsatisfiedQuantity;
				
				transaction.setRemainingQuantity(remainingQuantity - unsatisfiedQuantity);
				unsatisfiedQuantity = 0;
				break;
			} else {
				runningCost += transaction.getPrice() * remainingQuantity;
				satisfiedQuantity += remainingQuantity;
				
				transaction.setRemainingQuantity(0);
				unsatisfiedQuantity -= remainingQuantity;
			}
		}
		
		if (runningCost > availableFunds) {
			throw new IllegalStateException("Not enough funds to complete market order without partial fill");
		}
		
		if (satisfiedQuantity != desiredQuantity) {
			throw new IllegalStateException("Insufficient quantity of item available to complete market order without partial fill");
		}
		
		return runningCost;
	}
	
	public void FillLimitOrder(UUID otherTransactionId, int desiredQuantity, int ownerId) throws IllegalStateException {
		// this method processes the player's request to fill a buy/sell order with a specific transactionId
		Optional<OrderTransaction> optionalTransaction = transactionRepository
				.findPendingByTransactionId(otherTransactionId);
		// find order we want to fulfill
		if (optionalTransaction.isPresent()) {
			OrderTransaction otherTransaction = optionalTransaction.get();
			// check that desiredQuantity <= remaining quantity
			if (otherTransaction.getRemainingQuantity() < desiredQuantity) {
				throw new IllegalStateException("Requested quantity is more than quantity that is available.");
			} else if (otherTransaction.getRemainingQuantity() >= desiredQuantity) {
				// build our fulfillment transaction and add it to CompletedTransactions
				FulfillmentTransaction transaction = new FulfillmentTransaction(desiredQuantity, ownerId, otherTransaction);
				transactionRepository.save(transaction);
				// update the transaction we are fulfilling
				otherTransaction.remainingQuantity -= desiredQuantity;
				transactionRepository.save(otherTransaction);
			}
		} else {
			throw new IllegalStateException("Order has already been fulfilled or could not be found.");
		}
	}
	
	public List<OrderTransaction> GetPageForItem(String itemTypeStr, String transactionTypeStr, String pageNum) {
		// this method returns a page of items with a specific itemType and transactionType value at page pageNum
		ItemType itemType = itemEnums[Integer.parseInt(itemTypeStr)];
		TransactionType transactionType = transactionEnums[Integer.parseInt(transactionTypeStr)];
		
		// get page from database (page number, 10 items per page, by price and ascending)
		Pageable sortedByPriceAsc = PageRequest.of(Integer.parseInt(pageNum) - 1, 10, Sort.by("price").ascending()); // Sort.by("price").and(Sort.by("quantityRemaining"))
		List<OrderTransaction> pendingTransactions = transactionRepository
				.findPendingByItemTypeAndTransactionType(itemType, transactionType, sortedByPriceAsc);

		// return our list of PendingTransaction
		return pendingTransactions;
	}
}
