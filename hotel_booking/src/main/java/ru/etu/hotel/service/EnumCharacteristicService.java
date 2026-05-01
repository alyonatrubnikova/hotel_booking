package ru.etu.hotel.service;

import ru.etu.hotel.model.dto.request.CharacteristicRequest;
import ru.etu.hotel.model.dto.request.UpdateCharacteristicRequest;
import ru.etu.hotel.model.dto.response.CharacteristicResponse;
import ru.etu.hotel.model.dto.response.CharacteristicValueResponse;
import java.util.List;

public interface EnumCharacteristicService {
    Integer addCharacteristic(CharacteristicRequest request);
    List<CharacteristicResponse> getCharacteristicsByClass(Integer classId);
    List<CharacteristicResponse> getAllCharacteristics();
    CharacteristicValueResponse getCharacteristicValue(Integer classId, String name);
    void reorderCharacteristic(Integer valueId, Integer newOrder);
    void updateCharacteristic(Integer id, UpdateCharacteristicRequest request);
    void deleteCharacteristic(Integer id);
}