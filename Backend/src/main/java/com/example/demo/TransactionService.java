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

import com.google.gson.internal.LinkedTreeMap;


@Service
public class TransactionService {
	static private final TransactionType transactionTypes[] = TransactionType.values();
	static private final ItemType itemTypes[] = ItemType.values();
	static private final TransactionType buyOrderType = TransactionType.BuyOrder;
	static private final TransactionType sellOrderType = TransactionType.SellOrder;
	static private int ordersPerPage = 10;
	static private double mandatorySpread = 0.10;
	
	private final TransactionRepository transactionRepository;

	@Autowired
	public TransactionService(TransactionRepository transactionRepository) throws IllegalStateException {
		this.transactionRepository = transactionRepository;
	}

	public OrderTransaction PlaceOrder(OrderTransaction transactionDetails) {
		// this method adds a new buy/sell order to PendingTransactions table
		if (transactionDetails.getPrice() <= 0) {
			throw new IllegalStateException("Price must be greater than 0");
		} else if (transactionDetails.getTransactionType() == null
				|| !transactionDetails.getTransactionType().isOrder()) {
			throw new IllegalStateException("Invalid or missing TransactionType value");
		} else if (transactionDetails.getItemType() == null) {
			throw new IllegalStateException("Invalid or missing ItemType value");
//		} else if (transactionDetails.getOwnerId() <= 0) {
//			throw new IllegalStateException("OwnerId value must be greater than 0");
		} else if (transactionDetails.getOriginalQuantity() <= 0) {
			throw new IllegalStateException("Quantity value cannot be less than 0");
		}

		// do not allow placing order that violates buy/sell spread
		Pageable sortByPriceOrder = null;
		ItemType itemType = transactionDetails.getItemType();
		TransactionType transactionType = transactionDetails.getTransactionType();
		TransactionType otherTranasctionType = TransactionType.BuyOrder;
		if (transactionType == TransactionType.BuyOrder) {
			sortByPriceOrder = PageRequest.of(0, 1, Sort.by("price").ascending());
			otherTranasctionType = TransactionType.SellOrder;
		} else if (transactionType == TransactionType.SellOrder) {
			sortByPriceOrder = PageRequest.of(0, 1, Sort.by("price").descending());
		}
		
		List<OrderTransaction> topTransactions = transactionRepository.findOrderByItemTypeAndTransactionType(itemType, otherTranasctionType, sortByPriceOrder);
		if (!topTransactions.isEmpty()) {
			OrderTransaction topTransaction = topTransactions.get(0);
			if (transactionType == TransactionType.BuyOrder) {
				if (transactionDetails.getPrice() > (topTransaction.getPrice() - mandatorySpread)) {
					throw new IllegalStateException("Order price cannot be greater than $" + topTransaction.getPrice() + " - " + String.valueOf(topTransaction.getPrice() - mandatorySpread));
				}
			} else if (transactionType == TransactionType.SellOrder) {
				if (transactionDetails.getPrice() < (topTransaction.getPrice() + mandatorySpread)) {
					throw new IllegalStateException("Order price must be at least $" + topTransaction.getPrice() + " + " + String.valueOf(mandatorySpread));
				}
			}
		}
		
		// validation passed: save the order to the database
		transactionRepository.save(transactionDetails);
		return transactionDetails;
	}

	@Transactional
	public double FillMarketOrder(int itemTypeIndex, int transactonTypeIndex, int desiredQuantity, String ownerId, String ownerName, double availableFunds) throws IllegalStateException {		
		// this method attempts to fulfill the player's market fill request using the orders from the first page
		ItemType itemType = itemTypes[itemTypeIndex];
		TransactionType transactionType = transactionTypes[transactonTypeIndex];
		TransactionType fulfillmentTransactionType = TransactionType.Buy;
		if (transactionType == TransactionType.BuyOrder) {
			fulfillmentTransactionType = TransactionType.Sell;
		}
		
		Pageable sortByPriceOrder = null;
		if (fulfillmentTransactionType == TransactionType.Buy) {
			sortByPriceOrder = PageRequest.of(0, ordersPerPage, Sort.by("price").ascending());
		} else {
			sortByPriceOrder = PageRequest.of(0, ordersPerPage, Sort.by("price").descending());
		}
		List<OrderTransaction> pendingTransactions = transactionRepository
				.findOrderByItemTypeAndTransactionType(itemType, transactionType, sortByPriceOrder);
		
		double runningCost = 0;
		int satisfiedQuantity = 0;
		int unsatisfiedQuantity = desiredQuantity;
		
		// attempt to satisfy order with items on 1st page
		for (OrderTransaction transaction: pendingTransactions) {
//			if (transaction.getOwnerId().equals(ownerId)) {
//				// we do not want to complete this market order with our own pending orders
//				continue;
//			}
			
			double price = transaction.getPrice();
			int remainingQuantity = transaction.getRemainingQuantity();
			if (remainingQuantity >= unsatisfiedQuantity) {
				runningCost += price * unsatisfiedQuantity;
				satisfiedQuantity += unsatisfiedQuantity;
				
				transaction.setRemainingQuantity(remainingQuantity - unsatisfiedQuantity);
				FulfillmentTransaction fulfillmentTransaction = new FulfillmentTransaction(unsatisfiedQuantity, ownerId, ownerName, transaction);
				transactionRepository.save(fulfillmentTransaction);
				unsatisfiedQuantity = 0;
				break;
			} else {
				runningCost += price * remainingQuantity;
				satisfiedQuantity += remainingQuantity;
				
				transaction.setRemainingQuantity(0);
				FulfillmentTransaction fulfillmentTransaction = new FulfillmentTransaction(remainingQuantity, ownerId, ownerName, transaction);
				transactionRepository.save(fulfillmentTransaction);
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
	
	public void FillLimitOrder(UUID otherTransactionId, int desiredQuantity, String ownerId, String ownerName) throws IllegalStateException {
		// this method processes the player's request to fill a buy/sell order with a specific transactionId
		Optional<OrderTransaction> optionalTransaction = transactionRepository
				.findOrderActiveByTransactionId(otherTransactionId);
		// find order we want to fulfill
		if (optionalTransaction.isPresent()) {
			OrderTransaction otherTransaction = optionalTransaction.get();
			// check that we aren't filling our own order
//			if (ownerId.equals(otherTransaction.getOwnerId())) {
//				throw new IllegalStateException("Request denied: you are attempting to fill your own order.");
//			}
			
			// check that desiredQuantity <= remaining quantity
			if (otherTransaction.getRemainingQuantity() < desiredQuantity) {
				throw new IllegalStateException("Requested quantity is more than quantity that is available.");
			} else if (otherTransaction.getRemainingQuantity() >= desiredQuantity) {
				// build our fulfillment transaction and add it to CompletedTransactions
				FulfillmentTransaction transaction = new FulfillmentTransaction(desiredQuantity, ownerId, ownerName, otherTransaction);
				transactionRepository.save(transaction);
				// update the transaction we are fulfilling
				otherTransaction.remainingQuantity -= desiredQuantity;
				transactionRepository.save(otherTransaction);
			}
		} else {
			throw new IllegalStateException("Order has already been fulfilled or could not be found.");
		}
	}
	
	// TODO: OrdersPerPage could be passed into this method from ROBLOX Server and used inside sorting configuration
	public HashMap<String, HashMap<String, HashMap<Integer, List<OrderTransaction>>>> GetItemOrderPages(HashMap<String, LinkedTreeMap<String, List<Number>>> requestedPages) {
		// this method returns pages from database with indices defined in requestedPages
		
		HashMap<String, HashMap<String, HashMap<Integer, List<OrderTransaction>>>> buySellOrderPages = new HashMap<>();
		for (ItemType itemType: itemTypes) {
			String itemName = itemType.name();
			LinkedTreeMap<String, List<Number>> requestedItemPageIndices = requestedPages.get(itemName);
			if (requestedItemPageIndices == null) {
				continue;
			}
			
			List<Number> buyPageIndices = requestedItemPageIndices.get("buyPageIndices");
			List<Number> sellPageIndices = requestedItemPageIndices.get("sellPageIndices");
			
			HashMap<String, HashMap<Integer, List<OrderTransaction>>> foundBuySellPages = new HashMap<>();
			foundBuySellPages.put("foundBuyPages", new HashMap<Integer, List<OrderTransaction>>());
			foundBuySellPages.put("foundSellPages", new HashMap<Integer, List<OrderTransaction>>());
			
			// get buy orders
			for (Number pageIndex: buyPageIndices) {
				// define sorting configuration
				Pageable sortPriceDesc = PageRequest.of(pageIndex.intValue() - 1, ordersPerPage, Sort.by("price").descending());
				
				// get page from database
				List<OrderTransaction> ordersPage = transactionRepository.findOrderByItemTypeAndTransactionType(itemType, buyOrderType, sortPriceDesc);
				foundBuySellPages.get("foundBuyPages").put(pageIndex.intValue(),  ordersPage);
			}
			
			// get sell orders
			for (Number pageIndex: sellPageIndices) {
				// define sorting configuration
				Pageable sortPriceAsc = PageRequest.of(pageIndex.intValue() - 1, ordersPerPage, Sort.by("price").ascending());
				
				// get page from database
				List<OrderTransaction> ordersPage = transactionRepository.findOrderByItemTypeAndTransactionType(itemType, sellOrderType, sortPriceAsc);
				foundBuySellPages.get("foundSellPages").put(pageIndex.intValue(),  ordersPage);
			}
			
			buySellOrderPages.put(itemName, foundBuySellPages);
		}
		
		return buySellOrderPages;
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
	public OrderTransaction CancelOrder(UUID transactionID, String ownerId) throws IllegalStateException {
		// this method processes the player's request to cancel their order
		
		// find order we want to cancel
		Optional<OrderTransaction> optionalTransaction = transactionRepository.findOrderByTransactionId(transactionID);
		
		// check it exists and ownerId matches
		if (optionalTransaction.isPresent()) {
			OrderTransaction canceledTransaction = optionalTransaction.get();
			if (canceledTransaction.getOwnerId().equals(ownerId)) {
				OrderTransaction transactionCopy = new OrderTransaction(canceledTransaction);
				canceledTransaction.setRemainingQuantity(0);
				return transactionCopy;
			} else {
				throw new IllegalStateException("You are not authorized to cancel this transaction");
			}
		} else {
			// TODO: remove this because it only exists for debugging purposes and allows us to cancel player orders out of sync with the java database.
//			OrderTransaction blankOrder = new OrderTransaction();
//			blankOrder.setItemType(ItemType.Apple);
//			return blankOrder;
			throw new IllegalStateException("Transaction you are trying to cancel does not exist");
		}
	}
	
	public HashMap<String, List<FulfillmentTransaction>> GetItemOrderHistories() {
		// this method retrieves transaction histories for all items with 10 entries per item
		
		HashMap<String, List<FulfillmentTransaction>> orderHistories = new HashMap<String, List<FulfillmentTransaction>>();
		Pageable sortTimeDesc = PageRequest.of(0, ordersPerPage, Sort.by("timestamp").descending());
		for (ItemType itemType: itemTypes) {
			List<FulfillmentTransaction> orderTransactions = transactionRepository.findFulfillmentOrderByItemType(itemType, sortTimeDesc);
			orderHistories.put(itemType.name(), orderTransactions);
		}
		
		return orderHistories;
	}
}
