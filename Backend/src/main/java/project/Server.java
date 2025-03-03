package project;

import java.io.*;
import java.util.*;
import java.sql.*;
import java.lang.Thread;
// import org.postgresql;

// json
import org.json.simple.*;
import org.json.simple.parser.*;
import com.google.gson.Gson;

// http
import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.Headers;

import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

class GsonConvertTest {
	private int value1;
	private String value2;
	private ArrayList<String> value3;
	
	public GsonConvertTest() {
		this.value1 = 111;
		this.value2 = "some text";
		
		ArrayList<String> tempList = new ArrayList<>();
		tempList.add("First");
		tempList.add("Second");
		tempList.add("Final");
		
		this.value3 = tempList;
	}
}

public class Server {
	public static void main(String[] args) {
		System.out.println("START SUCCESS\n");

		// connecting to database
		try {
			Class.forName("org.postgresql.Driver");
			Connection con = DriverManager.getConnection("jdbc:postgresql://localhost:5432/projectdb", "postgres",
					"seproject");
			if (con != null)
				System.out.println("Connected to DB\n");
			else
				System.out.println("Could not connect to DB\n");
			con.close();
		} catch (Exception e) {
			System.out.println(e);
//			e.printStackTrace();
		}

		// reading json file
		JSONParser parser = new JSONParser();
		try {
			Object obj = parser.parse(new FileReader("marketplaceConfig.json"));
			JSONObject jsonObject = (JSONObject) obj;
			double taxPercent = (double) jsonObject.get("taxPercent");
			long taxFee = (long) jsonObject.get("taxFee");
			JSONArray subjects = (JSONArray) jsonObject.get("itemWhitelist");
			System.out.println("taxPercent: " + taxPercent);
			System.out.println("taxFee: " + taxFee);
			System.out.println("itemWhitelist: ");
			Iterator iterator = subjects.iterator();
			while (iterator.hasNext()) {
				System.out.println("\t" + iterator.next());
			}
		} catch (Exception e) {
			System.out.println(e);
			e.printStackTrace();
		}
		
		try {
	        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
	        server.createContext("/", new MyHandler());
	        server.setExecutor(null); // Use the default executor
	        server.start();
	        System.out.println("Server is running on port 8080");
	        Thread.sleep(10000); // shut down server after waiting 10 seconds
	        server.stop(0);
		} catch (Exception e) {
			System.out.println(e);
//			e.printStackTrace();
		}		

		System.out.println("\nEXIT SUCCESS");
	}

	static class MyHandler implements HttpHandler {
		@Override
		public void handle(HttpExchange exchange) throws IOException {

			String requestMethodType = exchange.getRequestMethod();
			if (requestMethodType.equals("GET")) {
				
			} else if (requestMethodType.equals("POST")) {
				
			}
			
			// handle the request
			final Headers headers = exchange.getResponseHeaders();

			Gson gson = new Gson();
			GsonConvertTest convertObj = new GsonConvertTest();
			String jsonString = gson.toJson(convertObj);
			
//			String response = "['hello world!']";
			String response = jsonString;
            headers.set("Content-Type", String.format("application/json; charset=%s", StandardCharsets.UTF_8));
			exchange.sendResponseHeaders(200, response.length());
			OutputStream os = exchange.getResponseBody();
			os.write(response.getBytes());
			os.close();
		}
	}
}