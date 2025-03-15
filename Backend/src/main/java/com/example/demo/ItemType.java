package com.example.demo;

import java.util.Random;

// TODO: should have some endpoint for client to fetch this enum info as dictionary?
public enum ItemType {
	// This enum represents are all the types of items that can be put on the market. 
	// We can probably just use a list instead.
	Apple,
	Banana,
	Orange,
	Grape,
	Watermelon;
	
	static Random random = new Random();
	public static ItemType getRandomItemType() {
		return values()[random.nextInt(values().length)];
	}
}
