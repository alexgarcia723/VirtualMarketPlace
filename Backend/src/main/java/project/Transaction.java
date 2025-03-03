package project;

import java.util.UUID;


public class Transaction {
	private TransactionType type; 
	private UUID transactionId;
	private int quantity;
	private double price;
	private String SellerId;
	
	public Transaction() { }
	
	public Transaction(TransactionType type, UUID transactionId, String SellerId, int quantity, double price) { 
		this.type = type;
		this.transactionId = transactionId;
		this.quantity = quantity;
		this.price = price;
	}
}
