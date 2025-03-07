package com.example.demo;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.repository.Repository;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "PendingTransactions")
// https://www.javaguides.net/2019/08/spring-boot-spring-data-jpa-postgresql-example.html
public class PendingTransaction extends Transaction {

	public PendingTransaction() {
	}

	public PendingTransaction(TransactionType transactionType, String itemId, int originalQuantity, int remainingQuantity, double price, String ownerId) {
		this.transactionType = transactionType;
		this.itemId = itemId;
		this.originalQuantity = originalQuantity;
		this.remainingQuantity = remainingQuantity;
		this.price = price;
		this.ownerId = ownerId;
	}

	@Override
	public String toString() {
		return "PendingTransaction [transactionType=" + transactionType + ", itemId=" + itemId + ", originalQuantity="
				+ originalQuantity + ", remainingQuantity=" + remainingQuantity + ", price=" + price + ", ownerId="
				+ ownerId + ", transactionId=" + transactionId + "]";
	}
}

