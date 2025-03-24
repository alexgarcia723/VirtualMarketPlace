package com.example.demo;

import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.google.gson.Gson;

import jakarta.validation.Valid;

/* Useful info:
 * 	https://stackoverflow.com/questions/3595160/what-does-the-valid-annotation-indicate-in-spring
 */

/*
 * Two optional features to implement:
 TODO: add endpoint to fetch running price averages for a specific item in a specific time interval
	- We need to update the average every time a transaction is completed
	- We can have a script to recalculate the running average every X interval of time
 TODO: add endpoint to get transaction history for an item
 	- We should probably limit it to returning only last X transactions or only transactions in the past X hours
 	- Must add timestamp to each transaction in CompletedTransaction table
 		- then get list of up to X transactions where itemId = ?1 and time < ?2
 		- e.g SELECT * FROM completed_transactions WHERE itemId = Apple AND time < 24h
*/

@RestController
@RequestMapping("/api/v1")
public class TransactionController {
	private final TransactionService transactionService;
	static private final Gson gson = new Gson();
	
	@Autowired
	public TransactionController(TransactionService transactionService) {
		this.transactionService = transactionService;
	}
	
	@PostMapping("/placeOrder")
	public ResponseEntity<String[]> PlaceOrder(@Valid @RequestBody OrderTransaction transactionDetails) {
		// this method intercepts the user's HTTP request to place an order and forwards it to the TransactionService
			
		UUID orderId = transactionService.PlaceOrder(transactionDetails);
		return ResponseEntity.ok().body(new String[]{String.valueOf(orderId), "Order placed successfully."});
	}

	@PostMapping(path = "/fillMarketOrder", consumes = "application/json")
	public ResponseEntity<String[]> FillMarketOrder(@RequestBody String jsonBody) {
		// this method intercepts the user's HTTP request to perform a market buy/sell and forwards it to TransactionService
		
		// get our values from the user's JSON and convert them to the correct types to pass to TransactionService
		HashMap<String, String> orderDetails = gson.fromJson(jsonBody, HashMap.class);
		int itemTypeIndex =  Integer.valueOf(orderDetails.get("itemType").toString());
		int transactionTypeIndex =  Integer.valueOf(orderDetails.get("transactionType").toString());
		int desiredQuantity = Integer.valueOf(orderDetails.get("desiredQuantity").toString());
		int ownerId = Integer.valueOf(orderDetails.get("ownerId"));
		double availableFunds = Double.valueOf(orderDetails.get("availableFunds"));
		boolean partialFill = Boolean.valueOf(orderDetails.get("availableFunds"));
		
		double spentFunds = transactionService.FillMarketOrder(itemTypeIndex, transactionTypeIndex, desiredQuantity, ownerId, availableFunds, partialFill);
//		String[] returnBody = new String[]{String.valueOf(spentFunds), "Order fulfilled successfully."};
//		return ResponseEntity.ok().body(gson.toJson(returnBody));
		return ResponseEntity.ok().body(new String[]{String.valueOf(spentFunds), "Order fulfilled successfully."});
	}

	@PostMapping(path = "/fillLimitOrder", consumes = "application/json")
	public ResponseEntity<String> FillLimitOrder(@RequestBody String jsonBody) {
		// this method intercepts the user's HTTP request to fill an order and forwards it to TransactionService
		
		// get our values from the user's JSON and convert them to the correct types to pass to TransactionService
		HashMap<String, String> orderDetails = gson.fromJson(jsonBody, HashMap.class);
		UUID otherTransactionId = UUID.fromString(orderDetails.get("otherTransactionId").toString());
		int desiredQuantity = Integer.valueOf(orderDetails.get("desiredQuantity").toString());
		int ownerId = Integer.valueOf(orderDetails.get("ownerId"));
		
		transactionService.FillLimitOrder(otherTransactionId, desiredQuantity, ownerId);
		return ResponseEntity.ok().body("Order fulfilled successfully."); 
	}
 	
	@GetMapping("/getPage/{itemType}")
	public ResponseEntity<List<OrderTransaction>> GetPageForItem(@PathVariable String itemType, @RequestParam String transactionType, String pageNum) {
		// this method intercepts the user's HTTP request to get a page of itemType and forwards it to TransactionService
		List<OrderTransaction> pendingTransactions = transactionService.GetPageForItem(itemType, transactionType, pageNum);
		return ResponseEntity.ok().body(pendingTransactions); 
	}
	
	@PostMapping(path = "/cancelOrder", consumes = "application/json")
	public ResponseEntity<String[]> CancelOrder(@RequestBody String jsonBody) {
		// this method intercepts the user's HTTP request to cancel an order and forwards it to the TransactionService
		HashMap<String, String> orderDetails = gson.fromJson(jsonBody, HashMap.class);
		UUID transactionID =  UUID.fromString(orderDetails.get("transactionId").toString());
		int ownerId = Integer.valueOf(orderDetails.get("ownerId"));
		OrderTransaction canceledTransaction = transactionService.CancelOrder(transactionID, ownerId);
		String orderJson = gson.toJson(canceledTransaction);
		
		return ResponseEntity.ok().body(new String[]{orderJson, "Order canceled successfully."});
	}

	// TODO: should this be a GET mapping?
	@PostMapping("/getOrderStatus")
	public ResponseEntity<HashMap<String, ArrayList<OrderTransaction>> > GetPageForItem(@RequestBody String jsonBody) {
		// this method intercepts the user's HTTP request to get information about pending orders and forwards it to TransactionService
		HashMap<String, ArrayList<String>> orderIdList = gson.fromJson(jsonBody, HashMap.class);
		
		HashMap<String, ArrayList<OrderTransaction>> pendingTransactions = transactionService.GetOrderStatus(orderIdList);
		return ResponseEntity.ok().body(pendingTransactions);
	}
}
