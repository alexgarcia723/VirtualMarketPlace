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
	
	@ExceptionHandler(HttpMessageNotReadableException.class)
	public ResponseEntity<String> handleInvalidTransaction(HttpMessageNotReadableException ex) {
    	System.out.println(ex.getMessage());
	    return ResponseEntity.badRequest().body(ex.getMessage());
	}
	
	@ExceptionHandler({MissingServletRequestParameterException.class, IllegalArgumentException.class})
	public ResponseEntity<String> hanleInvalidPageAccess(Exception ex) {
    	System.out.println(ex.getMessage());
		return ResponseEntity.badRequest().body(ex.getMessage());
	}
	
    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<String> handleOtherExceptions(IllegalStateException ex) {
    	System.out.println(ex.getMessage());
    	return ResponseEntity.badRequest().body(ex.getMessage());
    }
	
	// handles any other uncaught exceptions from our Controller class
    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleOtherExceptions(Exception ex) {
    	System.out.println(ex.getMessage());
    	return ResponseEntity.badRequest().body(ex.getMessage());
    }
}
