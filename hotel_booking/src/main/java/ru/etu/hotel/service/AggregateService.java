package ru.etu.hotel.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.etu.hotel.model.dto.response.AggregateResponse;
import ru.etu.hotel.repository.AggregateRepository;
import jakarta.persistence.EntityNotFoundException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AggregateService {

    private final AggregateRepository aggregateRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Transactional(readOnly = true)
    public List<AggregateResponse> getAllAggregates() {
        List<Object[]> results = aggregateRepository.getAllAggregates();
        List<AggregateResponse> responseList = new ArrayList<>();
        
        for (Object[] row : results) {
            AggregateResponse response = mapToResponse(row);
            responseList.add(response);
        }
        return responseList;
    }

    @Transactional(readOnly = true)
    public AggregateResponse getAggregateById(Integer aggregateId) {
        List<Object[]> results = aggregateRepository.getAggregateById(aggregateId);
        if (results.isEmpty()) {
            throw new EntityNotFoundException("Aggregate not found with id: " + aggregateId);
        }
        return mapToResponse(results.get(0));
    }

    @SuppressWarnings("unchecked")
    private AggregateResponse mapToResponse(Object[] row) {
        Integer aggregateId = toInt(row[0]);
        String aggregateName = (String) row[1];
        String description = (String) row[2];
        
        // Парсим JSON из колонки characteristics
        List<AggregateResponse.AggregateCharacteristicDto> characteristics = new ArrayList<>();
        
        if (row[3] != null) {
            try {
                // row[3] может быть String или уже разобранным объектом
                String jsonStr = row[3].toString();
                // Парсим JSON-массив в список Map'ов
                List<Map<String, Object>> charList = objectMapper.readValue(jsonStr, List.class);
                for (Map<String, Object> ch : charList) {
                    characteristics.add(AggregateResponse.AggregateCharacteristicDto.builder()
                            .characteristicId(toInt(ch.get("characteristic_id")))
                            .characteristicName((String) ch.get("characteristic_name"))
                            .sortOrder(toInt(ch.get("sort_order")))
                            .build());
                }
            } catch (Exception e) {
                System.err.println("Error parsing characteristics JSON: " + e.getMessage());
            }
        }
        
        return AggregateResponse.builder()
                .aggregateId(aggregateId)
                .aggregateName(aggregateName)
                .description(description)
                .characteristics(characteristics)
                .build();
    }

    private Integer toInt(Object obj) {
        if (obj == null) return null;
        if (obj instanceof Number) return ((Number) obj).intValue();
        if (obj instanceof String) {
            try {
                return Integer.parseInt((String) obj);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    @Transactional
    public Integer createAggregate(String name, String description) {
        return aggregateRepository.createAggregate(name, description);
    }

    @Transactional
    public void addCharacteristicToAggregate(Integer aggregateId, Integer characteristicId, Integer sortOrder) {
        aggregateRepository.addCharacteristicToAggregate(aggregateId, characteristicId, sortOrder);
    }

    @Transactional
    public void deleteAggregate(Integer aggregateId) {
        aggregateRepository.deleteById(aggregateId);
    }
}