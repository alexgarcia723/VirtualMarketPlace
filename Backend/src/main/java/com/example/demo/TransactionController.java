package com.example.demo;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1")
public class TransactionController {
	static private TransactionType enumValues[] = TransactionType.values();
	
	@Autowired
	private TransactionRepository transactionRepository;
	
	@PostMapping("/placeOrder")
	// input validation
	// https://stackoverflow.com/questions/3595160/what-does-the-valid-annotation-indicate-in-spring
	public PendingTransaction PlaceOrder(@Valid @RequestBody PendingTransaction transactionDetails) {
		return transactionRepository.save(transactionDetails);
	}

	@PostMapping("/fillOrder")
	// input validation
	// https://stackoverflow.com/questions/3595160/what-does-the-valid-annotation-indicate-in-spring
	public PendingTransaction FillOrder(@Valid @RequestBody PendingTransaction transactionDetails) {
		return new PendingTransaction();
//		return pendingTransactionRepository.save(transactionDetails);
	}

	@GetMapping("/getPage/{itemId}")
	// input validation
	// https://stackoverflow.com/questions/3595160/what-does-the-valid-annotation-indicate-in-spring
	public List<PendingTransaction> GetPageForItem(@PathVariable("itemId") String itemId, @RequestParam("transactionType") String transactionType, @RequestParam("pageNum") String pageNum) {
		Pageable sortedByPrice = PageRequest.of(Integer.parseInt(pageNum) - 1, 10, Sort.by("price").ascending());
		List<PendingTransaction> pendingTransactions = transactionRepository.findPendingByItemIdAndTransactionType(itemId, enumValues[Integer.parseInt(transactionType)], sortedByPrice);
		return pendingTransactions;
//		return user.map(ResponseEntity::ok)
//				.orElseThrow(() -> new RecordNotFoundException("User not found for ID " + id));
//		System.out.println(transactionType + "   " + pageNum + "   " + itemId);
//		return new PendingTransaction();
	}

	@GetMapping("/exampleTransaction")
	public PendingTransaction ExampleTransaction() {
		return new PendingTransaction(TransactionType.getRandomTransactionType(), "Apple", 50, 17, 49.99, "John Doe");
	}

}
