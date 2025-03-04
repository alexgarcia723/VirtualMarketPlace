package com.example.demo;

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

			PendingTransaction pendingTransaction = new PendingTransaction("PendingBuy", 12345, 50, 17, 49.99, "John Doe", UUID.randomUUID());

			repository.save(pendingTransaction);
//			Person saved = repository.findById(person.getId()).orElseThrow(NoSuchElementException::new);
		};
	}
}
