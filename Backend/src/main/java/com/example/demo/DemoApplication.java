package com.example.demo;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.UUID;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.data.domain.PageRequest;
//import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.Sort.TypedSort;


@SpringBootApplication
public class DemoApplication {

	public static void main(String[] args) {
		SpringApplication.run(DemoApplication.class, args);
	}

	@Bean
	CommandLineRunner runner(TransactionRepository repository) {
		return args -> {
			Random randomizer = new Random();
			
			// Pre-populate our DB with some randomly-generated buy/sell orders
			ArrayList<String> items = new ArrayList<>();
			items.add("Apple");
			items.add("Banana");
			items.add("Orange");
			
			int itemsToAdd = 200;
				// PendingTransactions
			for (int i = 0; i < itemsToAdd; i++) {
				int quantity = randomizer.nextInt(1, 50);
				String randomItemId = items.get(randomizer.nextInt(items.size()));
				TransactionType fillOrderType = TransactionType.getRandomTransactionType();
				PendingTransaction transaction = new PendingTransaction(fillOrderType, randomItemId, quantity, randomizer.nextInt(1, quantity + 1), randomizer.nextInt(100, 20000)/100., "John Doe");
				repository.save(transaction);
			}
			
				// Completed Transactions
			for (int i = 0; i < itemsToAdd; i++) {
				int quantity = randomizer.nextInt(1, 100);
				String randomItemId = items.get(randomizer.nextInt(items.size()));
				TransactionType fillOrderType = TransactionType.getRandomTransactionType();
				CompletedTransaction transaction = new CompletedTransaction(fillOrderType, randomItemId, quantity, randomizer.nextInt(1, quantity + 1), randomizer.nextInt(100, 20000)/100.0, "John Doe", UUID.randomUUID());
				repository.save(transaction);
			}
			
			
			// get some sorted pages from the database
			
			// sort by multiple attributes: Sort.by("price").ascending().and(Sort.by("quantityRemaining").descending()
			// PageRequest.of(pageIndex, itemsPerPage, sort criteria)
			Pageable sortedByPrice = PageRequest.of(0, 10, Sort.by("price").ascending());
			List<PendingTransaction> transactions1 = repository.findPendingByItemId("Apple", sortedByPrice);
			for (PendingTransaction transaction: transactions1) {
				System.out.println(transaction.getPrice());
			}
			
			List<CompletedTransaction> transactions2 = repository.findCompletedByItemId("Apple", sortedByPrice);
			System.out.println(transactions2.size());
			for (CompletedTransaction transaction: transactions2) {
				System.out.println(transaction.getPrice());
			}

//			Person saved = repository.findById(person.getId()).orElseThrow(NoSuchElementException::new);
		};
	}
}
