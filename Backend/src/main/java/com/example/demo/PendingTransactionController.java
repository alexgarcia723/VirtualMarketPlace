package com.example.demo;

import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1")
public class PendingTransactionController {
	@Autowired
	private PendingTransactionRepository pendingTransactionRepository;
	
	@PostMapping("/placeOrder")
	// input validation https://stackoverflow.com/questions/3595160/what-does-the-valid-annotation-indicate-in-spring
	public PendingTransaction PlaceOrder(@Valid @RequestBody PendingTransaction transactionDetails) {
		return pendingTransactionRepository.save(transactionDetails);
	}
	
//	@PostMapping("/fillOrder")
//	// input validation https://stackoverflow.com/questions/3595160/what-does-the-valid-annotation-indicate-in-spring
//	public PendingTransaction PlaceOrder(@PathVariable(value = "transactionId") UUID transactionId, @Valid @RequestBody PendingTransaction ) {
//		
//	}
	
//	@GetMapping("/getOrder/{itemId}/{pageNum}")
//	public PendingTransaction ExampleTransaction() {
//		// returns page of items with specific itemId
//		return new PendingTransaction("PendingBuy", 12345, 50, 17, 49.99, "John Doe", UUID.randomUUID());
//	}
	
	@GetMapping("/exampleTransaction")
	public PendingTransaction ExampleTransaction() {
		return new PendingTransaction("PendingBuy", 12345, 50, 17, 49.99, "John Doe", UUID.randomUUID());
	}
	
}
