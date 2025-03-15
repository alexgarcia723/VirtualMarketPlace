package com.example.demo;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/*
 * Useful info:
 * 	https://www.javaguides.net/2019/08/spring-boot-spring-data-jpa-postgresql-example.html
 * 	https://stackoverflow.com/questions/64634166/how-to-link-foreign-key-between-entity-in-spring-boot-data-jpa
 *  https://www.baeldung.com/jpa-one-to-one
 *  
 */

@Entity
@Table(name = "CompletedTransactions")
public class FulfillmentTransaction extends Transaction {

	@ManyToOne(cascade = CascadeType.ALL)
	@JoinColumn(name = "otherTransactionId", referencedColumnName = "transactionId", nullable = false)
	// Foreign key which references a PendingTransaction that is fulfilled by this CompletedTransaction
	private OrderTransaction otherTransaction;

	public FulfillmentTransaction() {
	}

	public FulfillmentTransaction(TransactionType transactionType, ItemType itemType, int originalQuantity, double price, int ownerId, OrderTransaction otherTransaction) {
		this.transactionType = transactionType;
		this.itemType = itemType;
		this.originalQuantity = originalQuantity;
		this.price = price;
		this.ownerId = ownerId;
		this.otherTransaction = otherTransaction;
	}
	
	public FulfillmentTransaction(int desiredQuantity, int ownerId, OrderTransaction otherTransaction) {
		if (otherTransaction.getTransactionType() == TransactionType.SellOrder) {
			this.transactionType = TransactionType.Buy;
		} else if (otherTransaction.getTransactionType() == TransactionType.BuyOrder) {
			this.transactionType = TransactionType.Sell;
		}
		
		this.itemType = otherTransaction.getItemType();
		this.originalQuantity = otherTransaction.getOriginalQuantity();
		this.price = otherTransaction.getPrice();
		this.ownerId = ownerId;
		this.otherTransaction = otherTransaction;
	}

	public OrderTransaction getOtherTransaction() {
		return otherTransaction;
	}

	public void setOtherTransaction(OrderTransaction otherTransaction) {
		this.otherTransaction = otherTransaction;
	}

	@Override
	public String toString() {
		return "CompletedTransaction [otherTransaction=" + otherTransaction + ", transactionType=" + transactionType
				+ ", itemType=" + itemType + ", originalQuantity=" + originalQuantity + ", remainingQuantity="
				+ remainingQuantity + ", price=" + price + ", ownerId=" + ownerId + ", ownerName=" + ownerName
				+ ", transactionId=" + transactionId + "]";
	}
}

