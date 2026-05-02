package ru.etu.hotel.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.etu.hotel.model.dto.request.CreateAggregateRequest;
import ru.etu.hotel.model.dto.response.AggregateResponse;
import ru.etu.hotel.model.dto.response.IdResponse;
import ru.etu.hotel.service.AggregateService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/aggregates")
@RequiredArgsConstructor
public class AggregateController {

    private final AggregateService aggregateService;

    @GetMapping
    public ResponseEntity<List<AggregateResponse>> getAllAggregates() {
        return ResponseEntity.ok(aggregateService.getAllAggregates());
    }

    @GetMapping("/{id}")
    public ResponseEntity<AggregateResponse> getAggregateById(@PathVariable Integer id) {
        return ResponseEntity.ok(aggregateService.getAggregateById(id));
    }

    @PostMapping
    public ResponseEntity<IdResponse> createAggregate(@RequestBody CreateAggregateRequest request) {
        Integer id = aggregateService.createAggregate(request.getName(), request.getDescription());
        return ResponseEntity.status(HttpStatus.CREATED).body(new IdResponse(id));
    }

    @PostMapping("/{aggregateId}/characteristics/{characteristicId}")
    public ResponseEntity<Map<String, String>> addCharacteristic(
            @PathVariable Integer aggregateId,
            @PathVariable Integer characteristicId,
            @RequestParam(required = false, defaultValue = "0") Integer sortOrder) {
        aggregateService.addCharacteristicToAggregate(aggregateId, characteristicId, sortOrder);
        return ResponseEntity.ok(Map.of("message", "Characteristic added to aggregate"));
    }

    @DeleteMapping("/{aggregateId}")
    public ResponseEntity<Map<String, String>> deleteAggregate(@PathVariable Integer aggregateId) {
        aggregateService.deleteAggregate(aggregateId);
        return ResponseEntity.ok(Map.of("message", "Aggregate deleted"));
    }
}