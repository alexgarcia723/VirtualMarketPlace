package com.example.demo;

//import java.util.Optional;
import java.util.UUID;

//import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.Repository;

public interface PendingTransactionRepository extends Repository<PendingTransaction, UUID> {

	PendingTransaction save(PendingTransaction transaction);

//	Optional<PendingTransaction> findById(UUID transactionId);
}