package ru.etu.hotel;

//Запускает Spring-приложение
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
//@ComponentScan -Ищет все @Service, @Controller, @Repository в пакете ru.etu.hotel
//@EnableAutoConfiguration -Spring автоматически настраивает всё (БД, MVC, JPA)

@SpringBootApplication
public class HotelApplication {

	public static void main(String[] args) {
		SpringApplication.run(HotelApplication.class, args);
	}

}
