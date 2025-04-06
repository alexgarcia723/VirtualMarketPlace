package com.example.demo;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.repository.Repository;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;


/* Useful info:
 * 	https://www.javaguides.net/2019/08/spring-boot-spring-data-jpa-postgresql-example.html
 */
@Entity
@Table(name = "PendingTransactions")
public class OrderTransaction extends Transaction {

	public OrderTransaction() {
	}
	
	public OrderTransaction(OrderTransaction originalTransaction) {
		this.transactionType = originalTransaction.transactionType;
		this.itemType = originalTransaction.itemType;
		this.originalQuantity = originalTransaction.originalQuantity;
		this.remainingQuantity = originalTransaction.remainingQuantity; 
		this.price = originalTransaction.price;
		this.ownerId = originalTransaction.ownerId;
		this.ownerName = originalTransaction.ownerName;
		this.transactionId = originalTransaction.transactionId;
	}

	public OrderTransaction(TransactionType transactionType, ItemType itemType, int originalQuantity, int remainingQuantity, double price, String ownerId, String ownerName) {
		this.transactionType = transactionType;
		this.itemType = itemType;
		this.originalQuantity = originalQuantity;
		this.remainingQuantity = originalQuantity; // originalQuantity = remainingQuantity for all new orders
		this.price = price;
		this.ownerId = ownerId;
		this.ownerName = ownerName;
	}

	@Override
	public String toString() {
		return "PendingTransaction [transactionType=" + transactionType + ", itemType=" + itemType
				+ ", originalQuantity=" + originalQuantity + ", remainingQuantity=" + remainingQuantity + ", price="
				+ price + ", ownerId=" + ownerId + ", ownerName=" + ownerName + ", transactionId=" + transactionId
				+ "]";
	}
}

