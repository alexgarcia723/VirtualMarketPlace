package com.example.demo;

import java.util.Random;


public enum TransactionType {
	BuyOrder,
	SellOrder,
	Buy,
	Sell;
	
	static Random random = new Random();
	public static TransactionType getRandomTransactionType() {
		return values()[random.nextInt(values().length)];
	}
}