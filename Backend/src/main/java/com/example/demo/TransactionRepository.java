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
	
	@Query("select t from #{#entityName} t where t.transactionId = ?1 and t.remainingQuantity != 0")
	Optional<OrderTransaction> findPendingByTransactionId(UUID transactionId);
	
	@Query("select t from #{#entityName} t where t.itemType = ?1 and t.transactionType = ?2 and t.remainingQuantity != 0")
	List<OrderTransaction> findPendingByItemTypeAndTransactionType(ItemType itemType, TransactionType transactionType, Pageable pageable);
	
	// unused queries
	@Query("select t from #{#entityName} t where t.itemType = ?1")
	List<OrderTransaction> findPendingByItemType(ItemType itemType,  Pageable pageable);
	
	@Query("select t from #{#entityName} t where t.itemType = ?1")
	List<FulfillmentTransaction> findCompletedByItemType(ItemType itemType, Pageable pageable);
	
	@Query("select t from #{#entityName} t where t.ownerId = ?1")
	List<OrderTransaction> findPendingByItemMerchantId(String sellerId);
	
	@Query("select t from #{#entityName} t where t.ownerId = ?1")
	List<FulfillmentTransaction> finCompletedByItemMerchantId(String sellerId);

//	Optional<PendingTransaction> findById(UUID transactionId);
}
