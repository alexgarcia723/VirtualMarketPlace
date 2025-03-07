package com.example.demo;

import java.util.List;
//import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.ListPagingAndSortingRepository;
//import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.Repository;

// https://github.com/mrahhal/blog/blob/main/posts/2023-05-14-offset-vs-keyset-pagination/post.md
public interface TransactionRepository extends ListPagingAndSortingRepository<Transaction, UUID> {
	PendingTransaction save(PendingTransaction transaction);
	CompletedTransaction save(CompletedTransaction transaction);

//	Page<T> findAll(Pageable pageable);
//	Page<T> findAll(int itemId, float price);
//	List<PendingTransactions> findAll(Sort sort);

//	List<PendingTransaction> findAllByPrice(int price, Pageable pageable);
	
//	@Query("select t from #{#entityName} t where t.itemId = ?1 order by t.price limit ?3")
//	List<PendingTransaction> findByItemId(String itemId, int pageNum, int itemsPerPage);

	@Query("select t from #{#entityName} t where t.itemId = ?1 and t.transactionType = ?2")
	List<PendingTransaction> findPendingByItemIdAndTransactionType(String itemId, TransactionType transactionType, Pageable pageable);
	
	@Query("select t from #{#entityName} t where t.itemId = ?1")
	List<PendingTransaction> findPendingByItemId(String itemId,  Pageable pageable);
//	List<PendingTransaction> findPendingByItemId(String itemId, Sort sort);
	
	@Query("select t from #{#entityName} t where t.itemId = ?1")
	List<CompletedTransaction> findCompletedByItemId(String itemId, Pageable pageable);
	
	@Query("select t from #{#entityName} t where t.ownerId = ?1")
	List<PendingTransaction> findPendingByItemMerchantId(String sellerId);
	
	@Query("select t from #{#entityName} t where t.ownerId = ?1")
	List<CompletedTransaction> finCompletedByItemMerchantId(String sellerId);

//	Optional<PendingTransaction> findById(UUID transactionId);
}
