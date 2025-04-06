package com.example.demo;

import java.util.Random;
import java.lang.Math;
import java.util.HashMap;
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
			double spreadAnchor = randomizer.nextInt(100, 1000)/100.0;
			double spread = 0.5;
			HashMap<ItemType, Double> lowestItemPrices = new HashMap<>();

			// add 100 random BuyOrders into OrderTransaction database table
			int itemsToAdd = 100;
			
			for (int i = 0; i < itemsToAdd; i++) {
				int quantity = randomizer.nextInt(1, 50);
				ItemType randomItemType = ItemType.getRandomItemType();
				TransactionType fillOrderType = TransactionType.SellOrder;
				
				double randomPrice = randomizer.nextDouble(spreadAnchor, 200);
				randomPrice = Math.floor(randomPrice * 100) / 100;
				
				Double lowestPrice = lowestItemPrices.get(randomItemType);
				if ((lowestPrice == null) || (randomPrice < lowestPrice)) {
					lowestItemPrices.put(randomItemType, randomPrice);
				}
				
				String randomOwnerId = String.valueOf(randomizer.nextInt(1, 10000));
				OrderTransaction transaction = new OrderTransaction(fillOrderType, randomItemType, quantity, randomizer.nextInt(1, quantity + 1), randomPrice, randomOwnerId, null);
				repository.save(transaction);
			}
			
			// add 100 random SellOrders into OrderTransaction database table
			for (int i = 0; i < itemsToAdd; i++) {
				int quantity = randomizer.nextInt(1, 50);
				ItemType randomItemType = ItemType.getRandomItemType();
				TransactionType fillOrderType = TransactionType.BuyOrder;
				
				Double lowestPrice = lowestItemPrices.get(randomItemType);
				double randomPrice = randomizer.nextDouble(lowestPrice + spread, 200);
				randomPrice = Math.floor(randomPrice * 100) / 100;
				
				String randomOwnerId = String.valueOf(randomizer.nextInt(1, 10000));
				OrderTransaction transaction = new OrderTransaction(fillOrderType, randomItemType, quantity, randomizer.nextInt(1, quantity + 1), randomPrice, randomOwnerId, null);
				repository.save(transaction);
			}
		};
	}
}
