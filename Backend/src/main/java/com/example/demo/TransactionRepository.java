package com.example.demo;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.ListPagingAndSortingRepository;

/*
 * Useful info:
 * 	https://github.com/mrahhal/blog/blob/main/posts/2023-05-14-offset-vs-keyset-pagination/post.md
 * 	https://www.geeksforgeeks.org/sql-injection/
 */
// TODO: Try to implement keyset pagination? Probably not necessary...
public interface TransactionRepository extends ListPagingAndSortingRepository<Transaction, UUID> {
	OrderTransaction save(OrderTransaction transaction);
	FulfillmentTransaction save(FulfillmentTransaction transaction);
	
	@Query("select t from #{#entityName} t where t.transactionId = ?1")
	Optional<OrderTransaction> findOrderByTransactionId(UUID transactionId);
	
	@Query("select t from #{#entityName} t where t.transactionId = ?1 and t.remainingQuantity != 0")
	Optional<OrderTransaction> findOrderActiveByTransactionId(UUID transactionId);
	
	@Query("select t from #{#entityName} t where t.itemType = ?1 and t.transactionType = ?2 and t.remainingQuantity != 0")
	List<OrderTransaction> findOrderByItemTypeAndTransactionType(ItemType itemType, TransactionType transactionType, Pageable pageable);
	
	@Query("select t from #{#entityName} t where t.ownerId = ?1")
	List<OrderTransaction> findOrderByOwnerId(String ownerId);
	
	// unused queries
	@Query("select t from #{#entityName} t where t.itemType = ?1")
	List<OrderTransaction> findOrderByItemType(ItemType itemType,  Pageable pageable);
	
	@Query("select t from #{#entityName} t where t.itemType = ?1")
	List<FulfillmentTransaction> findFulfillmentByItemType(ItemType itemType, Pageable pageable);
	
	@Query("select t from #{#entityName} t where t.ownerId = ?1")
	List<FulfillmentTransaction> findFulfillmentByItemMerchantId(String sellerId);

//	Optional<PendingTransaction> findById(UUID transactionId);
}
