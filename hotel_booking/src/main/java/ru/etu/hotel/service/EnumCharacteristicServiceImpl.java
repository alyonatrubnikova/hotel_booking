package ru.etu.hotel.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.etu.hotel.model.dto.request.CharacteristicRequest;
import ru.etu.hotel.model.dto.request.UpdateCharacteristicRequest;
import ru.etu.hotel.model.dto.response.CharacteristicResponse;
import ru.etu.hotel.model.dto.response.CharacteristicValueResponse;
import ru.etu.hotel.model.entity.EnumCharacteristic;
import ru.etu.hotel.repository.EnumCharacteristicRepository;
import jakarta.persistence.EntityNotFoundException;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EnumCharacteristicServiceImpl implements EnumCharacteristicService {
    
    private final EnumCharacteristicRepository repository;
    
    // ========== Старые методы ==========
    
    @Override
    @Transactional
    public Integer addCharacteristic(CharacteristicRequest request) {
        Integer maxSortOrder = repository.findMaxSortOrderByClassId(request.getClassId());
        int nextSortOrder = (maxSortOrder == null ? 0 : maxSortOrder) + 1;
        
        EnumCharacteristic characteristic = EnumCharacteristic.builder()
                .characteristicName(request.getCharacteristicName())
                .classId(request.getClassId())
                .valueNumber(request.getValueNumber())
                .valueString(request.getValueString())
                .valueImage(request.getValueImage())
                .unitOfMeasure(request.getUnitOfMeasure())
                .sortOrder(nextSortOrder)
                .build();
        
        EnumCharacteristic saved = repository.save(characteristic);
        return saved.getId();
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<CharacteristicResponse> getCharacteristicsByClass(Integer classId) {
        return repository.findCharacteristicsByClass(classId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<CharacteristicResponse> getAllCharacteristics() {
        return repository.findAllCharacteristics().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public CharacteristicValueResponse getCharacteristicValue(Integer classId, String name) {
        EnumCharacteristic characteristic = repository.findCharacteristicByClassAndName(classId, name)
                .orElseThrow(() -> new EntityNotFoundException("Characteristic not found: " + name + " for class " + classId));
        
        return CharacteristicValueResponse.builder()
                .valueNumber(characteristic.getValueNumber())
                .valueString(characteristic.getValueString())
                .valueImage(characteristic.getValueImage())
                .unitOfMeasure(characteristic.getUnitOfMeasure())
                .build();
    }
    
    @Override
    @Transactional
    public void reorderCharacteristic(Integer id, Integer newOrder) {
        if (!repository.existsById(id)) {
            throw new EntityNotFoundException("Characteristic not found with id: " + id);
        }
        repository.reorderEnumValue(id, newOrder);
    }
    
    @Override
    @Transactional
    public void updateCharacteristic(Integer id, UpdateCharacteristicRequest request) {
        int updated = repository.updateCharacteristicValue(
                id,
                request.getCharacteristicName(),
                request.getValueNumber(),
                request.getValueString(),
                request.getValueImage(),
                request.getUnitOfMeasure(),
                request.getSortOrder()
        );
        if (updated == 0) {
            throw new EntityNotFoundException("Characteristic not found with id: " + id);
        }
    }
    
    @Override
    @Transactional
    public void deleteCharacteristic(Integer id) {
        int deleted = repository.deleteCharacteristicById(id);
        if (deleted == 0) {
            throw new EntityNotFoundException("Characteristic not found with id: " + id);
        }
    }
    
    // ========== НОВЫЕ МЕТОДЫ ДЛЯ ТРЕБОВАНИЙ 1.3 ==========
    
    @Override
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getClassParametersWithOverrides(Integer classId) {
        List<Object[]> results = repository.getClassParametersWithOverrides(classId);
        List<Map<String, Object>> response = new ArrayList<>();
        
        for (Object[] row : results) {
            Map<String, Object> map = new HashMap<>();
            map.put("characteristicId", row[0]);
            map.put("characteristicName", row[1]);
            map.put("valueNumber", row[2]);
            map.put("valueString", row[3]);
            map.put("unitOfMeasure", row[4]);
            map.put("minValue", row[5]);
            map.put("maxValue", row[6]);
            map.put("isInheritedFromParent", row[7]);
            map.put("isOverridden", row[8]);
            map.put("sortOrder", row[9]);
            response.add(map);
        }
        return response;
    }
    
    @Override
    @Transactional
    public void overrideClassParameter(Integer classId, Integer characteristicId, Boolean isInherited, Integer sortOrder) {
        Boolean result = repository.overrideClassParameter(classId, characteristicId, isInherited, sortOrder);
        if (result == null || !result) {
            throw new EntityNotFoundException("Failed to override parameter. Check if class and characteristic exist.");
        }
    }
    
    @Override
    @Transactional
    public void setNumericConstraints(Integer characteristicId, BigDecimal min, BigDecimal max) {
        EnumCharacteristic characteristic = repository.findById(characteristicId)
                .orElseThrow(() -> new EntityNotFoundException("Characteristic not found with id: " + characteristicId));
        
        // Проверяем, что это числовой параметр (есть value_number)
        if (characteristic.getValueNumber() == null && min != null) {
            throw new IllegalArgumentException("Cannot set numeric constraints on a non-numeric parameter");
        }
        
        repository.setNumericConstraints(characteristicId, min, max);
    }
    
    // ========== Вспомогательные методы ==========
    
    private CharacteristicResponse toResponse(EnumCharacteristic entity) {
        return CharacteristicResponse.builder()
                .id(entity.getId())
                .characteristicName(entity.getCharacteristicName())
                .classId(entity.getClassId())
                .valueNumber(entity.getValueNumber())
                .valueString(entity.getValueString())
                .valueImage(entity.getValueImage())
                .unitOfMeasure(entity.getUnitOfMeasure())
                .sortOrder(entity.getSortOrder())
                .build();
    }
}