package com.example.demo;

import java.util.Random;

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
	CommandLineRunner runner(TransactionRepository repository) {
		return args -> {
			Random randomizer = new Random();
			
			// add 200 random BuyOrder/SellOrder into PendingTransactions database table
			int itemsToAdd = 200;
			for (int i = 0; i < itemsToAdd; i++) {
				int quantity = randomizer.nextInt(1, 50);
				ItemType randomItemType = ItemType.getRandomItemType();
				
				TransactionType fillOrderType = TransactionType.SellOrder;
				if (i % 2 == 0) {
					fillOrderType = TransactionType.BuyOrder;
				}
				
				int randomOwnerId = randomizer.nextInt(1, 10000);
				OrderTransaction transaction = new OrderTransaction(fillOrderType, randomItemType, quantity, randomizer.nextInt(1, quantity + 1), randomizer.nextInt(100, 20000)/100.0, randomOwnerId, null);
				repository.save(transaction);
			}
		};
	}
}
