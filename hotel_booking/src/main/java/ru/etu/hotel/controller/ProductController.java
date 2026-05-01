package ru.etu.hotel.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.etu.hotel.model.dto.request.ProductRequest;
import ru.etu.hotel.model.dto.response.IdResponse;
import ru.etu.hotel.model.dto.response.ProductListResponse;
import ru.etu.hotel.service.ProductService;

import java.util.Map;

@RestController
@RequestMapping("/product")
@RequiredArgsConstructor
@Slf4j
public class ProductController {

    private final ProductService productService;

    @PostMapping
    public ResponseEntity<IdResponse> addProduct(@RequestBody ProductRequest request) {
        Integer id = productService.addProduct(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(new IdResponse(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteProduct(@PathVariable("id") Integer id) {
        productService.deleteProduct(id);
        return ResponseEntity.ok(Map.of("message", "deleted"));
    }

    @GetMapping
    public ResponseEntity<ProductListResponse> listProducts(
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) Integer offset,
            @RequestParam(required = false) Integer classId) {
        ProductListResponse response = productService.getProducts(classId, limit, offset);
        log.info("Products list provided");
        return ResponseEntity.ok(response);
    }///product?limit=10&offset=0

    //Смена классификации
    @PutMapping("/{id}/swap")
    public ResponseEntity<Map<String, String>> updateProductClass(
            @PathVariable("id") Integer id,
            @RequestParam("new") Integer newClassId) {
        productService.updateClassId(id, newClassId);
        return ResponseEntity.ok(Map.of("message", "class updated"));
    }// /product/5/swap?new=8

    @PutMapping("/{id}")
    public ResponseEntity<Map<String, String>> updateProduct(
            @PathVariable("id") Integer id,
            @RequestBody ProductRequest request) {
        productService.updateProduct(id, request);
        return ResponseEntity.ok(Map.of("message", "updated"));
    }
}
