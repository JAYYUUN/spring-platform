package com.example.demo.controller;

import org.springframework.web.bind.annotation.GetMapping; /*이 클래스에서 Spring 기능을 쓰겠다”는 선언*/
import org.springframework.web.bind.annotation.RestController; /*이 클래스가 HTTP API를 처리하는 컨트롤러라는 뜻*/

@RestController
public class HealthController {

    @GetMapping("/health")
    public String health() {
        return "ok";
    }
}
