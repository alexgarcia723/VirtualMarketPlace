package com.example.demo;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.repository.Repository;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "PendingTransactions")
// https://www.javaguides.net/2019/08/spring-boot-spring-data-jpa-postgresql-example.html
public class PendingTransaction {

	private String transactionType; // should be enum
	private int itemId; // should be String, enum or int?
	private int originalQuantity;
	private int remainingQuantity;
	private double price;
	private String sellerId;
	@Id
	private UUID transactionId; // can use auto-generated increments instead?

	public PendingTransaction() {
	}

	public PendingTransaction(String transactionType, int itemId, int originalQuantity, int remainingQuantity, double price, String sellerId, UUID transactionId) {
		this.transactionType = transactionType;
		this.originalQuantity = originalQuantity;
		this.remainingQuantity = remainingQuantity;
		this.price = price;
		this.sellerId = sellerId;
		this.transactionId = transactionId;
	}
	
	
	@Column(name = "transactionType", nullable = false)
	public String getTransactionType() {
		return transactionType;
	}

	public void setTransactionType(String transactionType) {
		this.transactionType = transactionType;
	}

	@Column(name = "itemId", nullable = false)
	public int getItemId() {
		return itemId;
	}

	public void setItemId(int itemId) {
		this.itemId = itemId;
	}

	@Column(name = "originalQuantity", nullable = false)
	public int getOriginalQuantity() {
		return originalQuantity;
	}

	public void setOriginalQuantity(int originalQuantity) {
		this.originalQuantity = originalQuantity;
	}

	@Column(name = "remainingQuantity", nullable = false)
	public int getRemainingQuantity() {
		return remainingQuantity;
	}

	public void setRemainingQuantity(int remainingQuantity) {
		this.remainingQuantity = remainingQuantity;
	}

	@Column(name = "price", nullable = false)
	public double getPrice() {
		return price;
	}

	public void setPrice(double price) {
		this.price = price;
	}

	@Column(name = "sellerId", nullable = false)
	public String getSellerId() {
		return sellerId;
	}

	public void setSellerId(String sellerId) {
		this.sellerId = sellerId;
	}

	@Column(name = "transactionId", nullable = false)
	public UUID getTransactionId() {
		return transactionId;
	}

	public void setTransactionId(UUID transactionId) {
		this.transactionId = transactionId;
	}
	
	@Override
	public String toString() {
		return "PendingTransaction [transactionType=" + transactionType + ", itemId=" + itemId + ", originalQuantity="
				+ originalQuantity + ", remainingQuantity=" + remainingQuantity + ", price=" + price + ", sellerId="
				+ sellerId + ", transactionId=" + transactionId + "]";
	}
}

