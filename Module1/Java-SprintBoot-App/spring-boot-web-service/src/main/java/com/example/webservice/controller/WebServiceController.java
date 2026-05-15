package com.example.webservice.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class WebServiceController {

    @GetMapping("/ContainerApp")
    public String sendGreetings() {
        return "Welcome to Azure Container App!";
    }
}
