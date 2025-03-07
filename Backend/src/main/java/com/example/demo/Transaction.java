package com.example.demo;

import java.util.Optional;
import java.util.Random;
import java.util.UUID;

import org.springframework.data.repository.Repository;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.Table;

@MappedSuperclass
public abstract class Transaction {

	protected TransactionType transactionType;
	protected String itemId; // should be String, enum or int?
	protected int originalQuantity;
	protected int remainingQuantity;
	protected double price;
	protected String ownerId;
	@Id
	protected UUID transactionId = UUID.randomUUID(); // can use auto-generated increments instead?
	
	
	@Column(name = "transactionType", nullable = false)
	public TransactionType getTransactionType() {
		return transactionType;
	}

	public void setTransactionType(TransactionType transactionType) {
		this.transactionType = transactionType;
	}

	@Column(name = "itemId", nullable = false)
	public String getItemId() {
		return itemId;
	}

	public void setItemId(String itemId) {
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

	@Column(name = "ownerId", nullable = false)
	public String getOwnerId() {
		return ownerId;
	}

	public void setOwnerId(String merchantId) {
		this.ownerId = merchantId;
	}

	@Column(name = "transactionId", nullable = false)
	public UUID getTransactionId() {
		return transactionId;
	}

	public void setTransactionId(UUID transactionId) {
		this.transactionId = transactionId;
	}
	
}

