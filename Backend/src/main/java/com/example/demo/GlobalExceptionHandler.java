package com.example.demo;

import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

// https://www.javaguides.net/2023/07/spring-boot-exceptionhandler-multiple-exceptions.html
// https://www.javaguides.net/2023/08/httpmessagenotreadableexception-in-spring-boot.html

@ControllerAdvice
public class GlobalExceptionHandler {
	
	// handles exceptions that occur when we try to convert user's JSON into a Transaction object
	@ExceptionHandler(HttpMessageNotReadableException.class)
	public ResponseEntity<String> handleInvalidTransaction(HttpMessageNotReadableException ex) {
	    return ResponseEntity.badRequest().body("Invalid request payload: " + ex.getMessage());
	}
	
	// handles exceptions from illegal or missing arguments passed to the URL
	@ExceptionHandler({MissingServletRequestParameterException.class, IllegalArgumentException.class})
	public ResponseEntity<String> hanleInvalidPageAccess(Exception ex) {
		return ResponseEntity.badRequest().body("Invalid or missing parameters: " + ex.getMessage());
	}
	
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<String> handleOtherExceptions(IllegalStateException ex) {
    	return ResponseEntity.badRequest().body("IllegalStateException: " + ex.getMessage());
    }
	
	// handles any other uncaught exceptions from our Controller class
    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleOtherExceptions(Exception ex) {
    	return ResponseEntity.badRequest().body("Unknown exception occured: " + ex.getMessage());
    }
}
