package ru.etu.hotel.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.etu.hotel.model.dto.request.SetProductParameterRequest;
import ru.etu.hotel.model.dto.response.ProductParameterResponse;
import ru.etu.hotel.service.ProductParameterService;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/product")
@RequiredArgsConstructor
@Slf4j
public class ProductParameterController {

    private final ProductParameterService productParameterService;

    // Установить параметр для изделия
    @PostMapping("/{productId}/parameter")
    public ResponseEntity<Map<String, String>> setProductParameter(
            @PathVariable Integer productId,
            @RequestBody SetProductParameterRequest request) {
        productParameterService.setProductParameter(productId, request);
        return ResponseEntity.ok(Map.of("message", "Parameter set successfully"));
    }

    // Получить все параметры изделия (с наследованием)
    @GetMapping("/{productId}/parameters")
    public ResponseEntity<List<ProductParameterResponse>> getProductParameters(
            @PathVariable Integer productId) {
        List<ProductParameterResponse> parameters = productParameterService.getProductParameters(productId);
        return ResponseEntity.ok(parameters);
    }

    // Найти изделия по параметру
    @GetMapping("/search")
    public ResponseEntity<List<Object[]>> searchByParameter(
            @RequestParam Integer characteristicId,
            @RequestParam String operator,
            @RequestParam(required = false) BigDecimal value,
            @RequestParam(required = false) String stringValue) {
        List<Object[]> results = productParameterService.findProductsByParameter(
            characteristicId, operator, value, stringValue);
        return ResponseEntity.ok(results);
    }
}