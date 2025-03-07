package com.example.demo;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.repository.Repository;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "CompletedTransactions")
// https://www.javaguides.net/2019/08/spring-boot-spring-data-jpa-postgresql-example.html
public class CompletedTransaction extends Transaction {

	private UUID otherTransactionId;

	public CompletedTransaction() {
	}

	public CompletedTransaction(TransactionType transactionType, String itemId, int originalQuantity, int remainingQuantity, double price, String ownerId, UUID otherTransactionId) {
		this.transactionType = transactionType;
		this.itemId = itemId;
		this.originalQuantity = originalQuantity;
		this.remainingQuantity = remainingQuantity;
		this.price = price;
		this.ownerId = ownerId;
		// https://stackoverflow.com/questions/64634166/how-to-link-foreign-key-between-entity-in-spring-boot-data-jpa
		// https://www.baeldung.com/jpa-one-to-one
		// otherTransactionId is a foreign key: can be null (for non-fill orders) but must reference existing buy/sell order if not
		// @JoinColumn(name = "otherTransactionId", referencedColumnName = "transactionId")
		this.otherTransactionId = otherTransactionId;
	}

	public UUID getOtherTransactionId() {
		return otherTransactionId;
	}

	public void setOtherTransactionId(UUID otherTransactionId) {
		this.otherTransactionId = otherTransactionId;
	}

	@Override
	public String toString() {
		return "PendingTransaction [otherTransactionId=" + otherTransactionId + ", transactionType=" + transactionType
				+ ", itemId=" + itemId + ", originalQuantity=" + originalQuantity + ", remainingQuantity="
				+ remainingQuantity + ", price=" + price + ", sellerId=" + ownerId + ", transactionId=" + transactionId
				+ "]";
	}

}

