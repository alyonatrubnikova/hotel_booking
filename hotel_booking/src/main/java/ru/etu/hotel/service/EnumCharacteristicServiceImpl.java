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

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EnumCharacteristicServiceImpl implements EnumCharacteristicService {
    
    private final EnumCharacteristicRepository repository;
    
    @Override
@Transactional
public Integer addCharacteristic(CharacteristicRequest request) {
    // Вычисляем следующий порядковый номер для данного класса
    Integer maxSortOrder = repository.findMaxSortOrderByClassId(request.getClassId());
    int nextSortOrder = (maxSortOrder == null ? 0 : maxSortOrder) + 1;
    
    EnumCharacteristic characteristic = EnumCharacteristic.builder()
            .characteristicName(request.getCharacteristicName())
            .classId(request.getClassId())
            .valueNumber(request.getValueNumber())
            .valueString(request.getValueString())
            .valueImage(request.getValueImage())
            .unitOfMeasure(request.getUnitOfMeasure())
            .sortOrder(nextSortOrder)  // ← автоматически
            .build();
    
    EnumCharacteristic saved = repository.save(characteristic);
    System.out.println("Added characteristic: id=" + saved.getId() + ", sortOrder=" + saved.getSortOrder());
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
        System.out.println("Reordered characteristic: id=" + id + ", newOrder=" + newOrder);
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
        System.out.println("Updated characteristic: id=" + id);
    }
    
    @Override
    @Transactional
    public void deleteCharacteristic(Integer id) {
        int deleted = repository.deleteCharacteristicById(id);
        if (deleted == 0) {
            throw new EntityNotFoundException("Characteristic not found with id: " + id);
        }
        System.out.println("Deleted characteristic: id=" + id);
    }
    
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