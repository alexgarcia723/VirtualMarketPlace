package com.example.demo;

import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.google.gson.Gson; // can use jackson ObjectMapper() instead
import com.google.gson.internal.LinkedTreeMap;

import jakarta.validation.Valid;

/* Useful info:
 * 	https://stackoverflow.com/questions/3595160/what-does-the-valid-annotation-indicate-in-spring
 */

/*
 * Optional average price feature:
 TODO: add endpoint to fetch running price averages for a specific item in a specific time interval
	- We need to update the average every time a transaction is completed
	- We can have a script to recalculate the running average every X interval of time
	- On server startup, we look through the previous transactions and for each item
		- for transactions where transaction.timestamp.isWithin(runningAverageTimeInterval), we add them up
		- and compute the average and store this in a list which is retrieved by our /getAverages endpoint
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
		// accepts HTTP requests with JSON describing order to place and returns orderId of placed order + success message
			
		UUID orderId = transactionService.PlaceOrder(transactionDetails);
		return ResponseEntity.ok().body(new String[]{String.valueOf(orderId), "Order placed successfully."});
	}

	@PostMapping(path = "/fillMarketOrder", consumes = "application/json")
	public ResponseEntity<String[]> FillMarketOrder(@RequestBody String jsonBody) {
		// accepts HTTP requests with JSON describing market order request parameters and returns spent funds amount + success/failure message
		
		// get our values from the user's JSON and convert them to the correct types to pass to TransactionService
		HashMap<String, String> orderDetails = gson.fromJson(jsonBody, HashMap.class);
		int itemTypeIndex =  Integer.valueOf(orderDetails.get("itemType").toString());
		int transactionTypeIndex =  Integer.valueOf(orderDetails.get("transactionType").toString());
		int desiredQuantity = Integer.valueOf(orderDetails.get("desiredQuantity").toString());
		int ownerId = Integer.valueOf(orderDetails.get("ownerId"));
		String ownerName = String.valueOf(orderDetails.get("ownerName"));
		double availableFunds = Double.valueOf(orderDetails.get("availableFunds"));
		
		double spentFunds = transactionService.FillMarketOrder(itemTypeIndex, transactionTypeIndex, desiredQuantity, ownerId, ownerName, availableFunds);
		return ResponseEntity.ok().body(new String[]{String.valueOf(spentFunds), "Order fulfilled successfully."});
	}

	@PostMapping(path = "/fillLimitOrder", consumes = "application/json")
	public ResponseEntity<String> FillLimitOrder(@RequestBody String jsonBody) {
		// accepts HTTP requests with JSON describing limit order request parameters and returns success/failure message
		
		// get our values from the user's JSON and convert them to the correct types to pass to TransactionService
		HashMap<String, String> orderDetails = gson.fromJson(jsonBody, HashMap.class);
		UUID otherTransactionId = UUID.fromString(orderDetails.get("otherTransactionId").toString());
		int desiredQuantity = Integer.valueOf(orderDetails.get("desiredQuantity").toString());
		int ownerId = Integer.valueOf(orderDetails.get("ownerId"));
		String ownerName = String.valueOf(orderDetails.get("ownerName"));
		
		transactionService.FillLimitOrder(otherTransactionId, desiredQuantity, ownerId, ownerName);
		return ResponseEntity.ok().body("Order fulfilled successfully."); 
	}
 	
	@PostMapping(path = "/getPages")
	public ResponseEntity<HashMap<String, HashMap<String, HashMap<Integer, List<OrderTransaction>>>>> GetItemOrderPages(@RequestBody String jsonBody) {
		// accepts HTTP requests with input dictionary representing the requested page indices and returns such pages from DB

		HashMap<String, LinkedTreeMap<String, List<Number>>> requestedPages = gson.fromJson(jsonBody, HashMap.class);
		HashMap<String, HashMap<String, HashMap<Integer, List<OrderTransaction>>>> buySellOrderPages = transactionService.GetItemOrderPages(requestedPages);
		return ResponseEntity.ok().body(buySellOrderPages); 
	}
	
	@PostMapping(path = "/cancelOrder", consumes = "application/json")
	public ResponseEntity<String[]> CancelOrder(@RequestBody String jsonBody) {
		// accepts HTTP requests with JSON describing order to cancel and returns the order we canceled + success message
		HashMap<String, String> orderDetails = gson.fromJson(jsonBody, HashMap.class);
		UUID transactionID =  UUID.fromString(orderDetails.get("transactionId").toString());
		int ownerId = Integer.valueOf(orderDetails.get("ownerId"));
		OrderTransaction canceledTransaction = transactionService.CancelOrder(transactionID, ownerId);
		String orderJson = gson.toJson(canceledTransaction);
		
		return ResponseEntity.ok().body(new String[]{orderJson, "Order canceled successfully."});
	}

	@PostMapping("/getOrderStatus")
	public ResponseEntity<HashMap<String, ArrayList<OrderTransaction>> > GetOrderStatus(@RequestBody String jsonBody) {
		// accepts HTTP requests with JSON of itemType mapped to list of transactionIds and returns list of these orders from database
		HashMap<String, ArrayList<String>> orderIdList = gson.fromJson(jsonBody, HashMap.class);
		
		HashMap<String, ArrayList<OrderTransaction>> pendingTransactions = transactionService.GetOrderStatus(orderIdList);
		return ResponseEntity.ok().body(pendingTransactions);
	}
	
	@GetMapping(path = "/getItemOrderHistories")
	public ResponseEntity<HashMap<String, List<FulfillmentTransaction>>> GetItemOrderHistories() {
		// accepts HTTP request with no parameters to retrieve list of order histories for all available items
		HashMap<String, List<FulfillmentTransaction>> orderHistories = transactionService.GetItemOrderHistories();
		
		return ResponseEntity.ok().body(orderHistories);
	}
}
