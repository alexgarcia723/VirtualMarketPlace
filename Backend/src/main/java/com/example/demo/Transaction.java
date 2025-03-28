package com.example.demo;

import java.util.UUID;
import java.util.Date;
import jakarta.persistence.Column;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import java.sql.Timestamp;

@MappedSuperclass
public abstract class Transaction {

	protected TransactionType transactionType;
	protected ItemType itemType;
	protected int originalQuantity;
	protected int remainingQuantity;
	protected double price;
	protected int ownerId;
	protected String ownerName;
	protected Timestamp timestamp = new Timestamp((new Date()).getTime());
	@Id
	protected UUID transactionId = UUID.randomUUID();
	
	@Column(name = "timestamp", nullable = false)
	public Timestamp getTimestamp() {
		return timestamp;
	}

	public void setTimestamp(Timestamp timestamp) {
		this.timestamp = timestamp;
	}
	
	
	@Column(name = "ownerName", nullable = true)
	public String getOwnerName() {
		return ownerName;
	}

	public void setOwnerName(String ownerName) {
		this.ownerName = ownerName;
	}

	@Column(name = "transactionType", nullable = false)
	public TransactionType getTransactionType() {
		return transactionType;
	}

	public void setTransactionType(TransactionType transactionType) {
		this.transactionType = transactionType;
	}

	@Column(name = "itemType", nullable = false)
	public ItemType getItemType() {
		return itemType;
	}

	public void setItemType(ItemType itemType) {
		this.itemType = itemType;
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
	public int getOwnerId() {
		return ownerId;
	}

	public void setOwnerId(int ownerId) {
		this.ownerId = ownerId;
	}

	@Column(name = "transactionId", nullable = false)
	public UUID getTransactionId() {
		return transactionId;
	}

	public void setTransactionId(UUID transactionId) {
		this.transactionId = transactionId;
	}
	
}

