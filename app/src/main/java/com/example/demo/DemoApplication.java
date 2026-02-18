package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/*위 세 개는 gradle에서 받아온 라이브러리이며, java 코드에 import 해서 사용한다.*/

@SpringBootApplication
public class DemoApplication {

	public static void main(String[] args) { //java 프로그램의 시작점 : java는 무조건 main부터 실행
		SpringApplication.run(DemoApplication.class, args); 
		/*Spring 시작버튼 : Spring 켜고, 설정 읽고, Tomcat 띄우고, Controller 찾고, 서버 대기상태로 만듦.*/
	}

}
