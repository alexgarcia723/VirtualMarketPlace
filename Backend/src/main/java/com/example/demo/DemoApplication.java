package com.example.demo;

import java.util.Random;
import java.util.UUID;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class DemoApplication {

	public static void main(String[] args) {
		SpringApplication.run(DemoApplication.class, args);
	}

	@Bean
	CommandLineRunner runner(PendingTransactionRepository repository) {
		return args -> {
			Random rand = new Random();
			
			// Pre-populate our DB with some random fill buy/sell orders
			int itemId = 12345;
			int itemsToAdd = 50;
			for (int i = 0; i < itemsToAdd; i++) {
				int quantity = rand.nextInt(1, 50);
				PendingTransaction pendingTransaction = new PendingTransaction("BuyOrder", itemId, quantity, rand.nextInt(1, quantity + 1), rand.nextDouble(1, 200), "John Doe", UUID.randomUUID());
				repository.save(pendingTransaction);
			}
			
			for (int i = 0; i < itemsToAdd; i++) {
				int quantity = rand.nextInt(1, 50);
				PendingTransaction pendingTransaction = new PendingTransaction("BuyOrder", itemId, quantity, rand.nextInt(1, quantity + 1), rand.nextDouble(1, 200), "John Doe", UUID.randomUUID());
				repository.save(pendingTransaction);
			}
			
//			Person saved = repository.findById(person.getId()).orElseThrow(NoSuchElementException::new);
		};
	}
}
