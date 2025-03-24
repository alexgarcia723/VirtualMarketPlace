package com.example.demo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
		// TODO: WE PROBABLY SHOULD HAVE A MAXIMUM desiredQuantity BECAUSE WE DON'T WANT TO SEARCH THE ENTIRE TABLE (maybe limit to 1 page?)
		
		// this method processes the player's request to buy/sell certain quantity of an item from any available unfilled orders
		ItemType itemType = itemEnums[itemTypeIndex];
		TransactionType transactionType = transactionEnums[transactonTypeIndex];
		
		Pageable sortedByPriceAsc = PageRequest.of(0, 10, Sort.by("price").ascending());
		List<OrderTransaction> pendingTransactions = transactionRepository
				.findOrderByItemTypeAndTransactionType(itemType, transactionType, sortedByPriceAsc);
		
		double runningCost = 0;
		int satisfiedQuantity = 0;
		int unsatisfiedQuantity = desiredQuantity;
		
		// attempt to satisfy order with items on 1st page
		for (OrderTransaction transaction: pendingTransactions) {
			if (transaction.getOwnerId() == ownerId) {
				// we do not want to complete this market order with our own pending orders
				continue;
			}
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
				.findOrderActiveByTransactionId(otherTransactionId);
		// find order we want to fulfill
		if (optionalTransaction.isPresent()) {
			OrderTransaction otherTransaction = optionalTransaction.get();
			// check that we aren't filling our own order
			if (ownerId == otherTransaction.getOwnerId()) {
				throw new IllegalStateException("Request denied: you are attempting to fill your own order.");
			}
			
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
				.findOrderByItemTypeAndTransactionType(itemType, transactionType, sortedByPriceAsc);

		// return our list of PendingTransaction
		return pendingTransactions;
	}
	
	
	public HashMap<String, ArrayList<OrderTransaction>> GetOrderStatus(HashMap<String, ArrayList<String>> orderIdList) {
		// this method returns a list of transactions that match a UUID in orderIdList
		
		HashMap<String, ArrayList<OrderTransaction>> playersOrderStatus = new HashMap<>();
		for (Map.Entry<String, ArrayList<String>> set: orderIdList.entrySet()) {
			String ownerIdStr = set.getKey();
			ArrayList<String> orderList = set.getValue();			
			List<OrderTransaction> orderTransactions = transactionRepository.findOrderByOwnerId(ownerIdStr);
			
			ArrayList<OrderTransaction> orderStatusList = new ArrayList<OrderTransaction>();
			// TODO: (bad) this searches through all the orders ever placed by any of the users in our map
			//  		it might be better to only search for the IDs in ArrayList<UUID> each of which len <= 10
            for (OrderTransaction transaction: orderTransactions) {
            	if (orderList.contains(String.valueOf(transaction.transactionId))) {
            		orderStatusList.add(transaction);
            	}
            }
            playersOrderStatus.put(ownerIdStr, orderStatusList);
        }
		 
		return playersOrderStatus;
	}
	
	@Transactional
	public OrderTransaction CancelOrder(UUID transactionID, int ownerId) throws IllegalStateException {
		// this method processes the player's request to cancel their order
		
		// find order we want to cancel
		Optional<OrderTransaction> optionalTransaction = transactionRepository.findOrderByTransactionId(transactionID);
		
		// check it exists and ownerId matches
		if (optionalTransaction.isPresent()) {
			OrderTransaction canceledTransaction = optionalTransaction.get();
			if (canceledTransaction.getOwnerId() == ownerId) {
				OrderTransaction transactionCopy = new OrderTransaction(canceledTransaction);
				canceledTransaction.setRemainingQuantity(0);
				return transactionCopy;
			} else {
				throw new IllegalStateException("You are not authorized to cancel this transaction");
			}
		} else {
			// TODO: remove this because it only exists for debugging purposes.
			OrderTransaction blankOrder = new OrderTransaction();
			blankOrder.setItemType(ItemType.Apple);
			return blankOrder;
//			throw new IllegalStateException("Transaction you are trying to cancel does not exist");
		}
	}
}
