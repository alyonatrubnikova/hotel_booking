package ru.etu.hotel.service;

import ru.etu.hotel.model.dto.request.CharacteristicRequest;
import ru.etu.hotel.model.dto.request.UpdateCharacteristicRequest;
import ru.etu.hotel.model.dto.response.CharacteristicResponse;
import ru.etu.hotel.model.dto.response.CharacteristicValueResponse;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public interface EnumCharacteristicService {
    
    // ========== Старые методы ==========
    
    Integer addCharacteristic(CharacteristicRequest request);
    List<CharacteristicResponse> getCharacteristicsByClass(Integer classId);
    List<CharacteristicResponse> getAllCharacteristics();
    CharacteristicValueResponse getCharacteristicValue(Integer classId, String name);
    void reorderCharacteristic(Integer valueId, Integer newOrder);
    void updateCharacteristic(Integer id, UpdateCharacteristicRequest request);
    void deleteCharacteristic(Integer id);
    
    // ========== НОВЫЕ МЕТОДЫ ДЛЯ ТРЕБОВАНИЙ 1.3 ==========
    
    /**
     * Получить параметры класса с учётом переопределений (для подклассов)
     */
    List<Map<String, Object>> getClassParametersWithOverrides(Integer classId);
    
    /**
     * Переопределить параметр для подкласса
     */
    void overrideClassParameter(Integer classId, Integer characteristicId, Boolean isInherited, Integer sortOrder);
    
    /**
     * Установить ограничения min/max для численного параметра
     */
    void setNumericConstraints(Integer characteristicId, BigDecimal min, BigDecimal max);
}