package ru.etu.hotel.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.etu.hotel.model.dto.request.CharacteristicRequest;
import ru.etu.hotel.model.dto.request.UpdateCharacteristicRequest;
import ru.etu.hotel.model.dto.response.CharacteristicResponse;
import ru.etu.hotel.model.dto.response.CharacteristicValueResponse;
import ru.etu.hotel.model.dto.response.IdResponse;
import ru.etu.hotel.service.EnumCharacteristicService;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/characteristics")
@RequiredArgsConstructor
public class EnumCharacteristicController {
    
    private final EnumCharacteristicService characteristicService;
    
    // ========== Старые методы ==========
    
    @PostMapping
    public ResponseEntity<IdResponse> addCharacteristic(@RequestBody CharacteristicRequest request) {
        Integer id = characteristicService.addCharacteristic(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(new IdResponse(id));
    }
    
    @GetMapping("/class/{classId}")
    public ResponseEntity<List<CharacteristicResponse>> getByClass(@PathVariable Integer classId) {
        return ResponseEntity.ok(characteristicService.getCharacteristicsByClass(classId));
    }
    
    @GetMapping
    public ResponseEntity<List<CharacteristicResponse>> getAll() {
        return ResponseEntity.ok(characteristicService.getAllCharacteristics());
    }
    
    @GetMapping("/value")
    public ResponseEntity<CharacteristicValueResponse> getValue(
            @RequestParam Integer classId,
            @RequestParam String name) {
        return ResponseEntity.ok(characteristicService.getCharacteristicValue(classId, name));
    }
    
    @PutMapping("/{valueId}/reorder")
    public ResponseEntity<Map<String, String>> reorderCharacteristic(
            @PathVariable Integer valueId,
            @RequestParam Integer newOrder) {
        characteristicService.reorderCharacteristic(valueId, newOrder);
        return ResponseEntity.ok(Map.of("message", "order updated"));
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<Map<String, String>> updateCharacteristic(
            @PathVariable Integer id,
            @RequestBody UpdateCharacteristicRequest request) {
        characteristicService.updateCharacteristic(id, request);
        return ResponseEntity.ok(Map.of("message", "updated"));
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteCharacteristic(@PathVariable Integer id) {
        characteristicService.deleteCharacteristic(id);
        return ResponseEntity.ok(Map.of("message", "deleted"));
    }
    
    // ========== НОВЫЕ МЕТОДЫ ДЛЯ ТРЕБОВАНИЙ 1.3 ==========
    
    /**
     * Получить параметры класса с учётом переопределений (для подклассов)
     * GET /api/characteristics/class/{classId}/with-overrides
     */
    @GetMapping("/class/{classId}/with-overrides")
    public ResponseEntity<List<Map<String, Object>>> getClassParametersWithOverrides(
            @PathVariable Integer classId) {
        List<Map<String, Object>> result = characteristicService.getClassParametersWithOverrides(classId);
        return ResponseEntity.ok(result);
    }
    
    /**
     * Переопределить параметр для подкласса
     * POST /api/characteristics/class/{classId}/override?characteristicId=1&isInherited=false&sortOrder=10
     */
    @PostMapping("/class/{classId}/override")
    public ResponseEntity<Map<String, String>> overrideClassParameter(
            @PathVariable Integer classId,
            @RequestParam Integer characteristicId,
            @RequestParam(required = false, defaultValue = "false") Boolean isInherited,
            @RequestParam(required = false) Integer sortOrder) {
        characteristicService.overrideClassParameter(classId, characteristicId, isInherited, sortOrder);
        return ResponseEntity.ok(Map.of("message", "Parameter overridden successfully"));
    }
    
    /**
     * Установить ограничения min/max для численного параметра
     * PUT /api/characteristics/{characteristicId}/constraints?min=0&max=100
     */
    @PutMapping("/{characteristicId}/constraints")
    public ResponseEntity<Map<String, String>> setNumericConstraints(
            @PathVariable Integer characteristicId,
            @RequestParam(required = false) BigDecimal min,
            @RequestParam(required = false) BigDecimal max) {
        characteristicService.setNumericConstraints(characteristicId, min, max);
        return ResponseEntity.ok(Map.of("message", "Constraints updated successfully"));
    }
}