package ru.etu.hotel.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.etu.hotel.model.dto.response.AggregateResponse;
import ru.etu.hotel.repository.AggregateRepository;
import jakarta.persistence.EntityNotFoundException;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AggregateService {

    private final AggregateRepository aggregateRepository;

    @Transactional(readOnly = true)
    public List<AggregateResponse> getAllAggregates() {
        List<Object[]> results = aggregateRepository.getAllAggregates();
        List<AggregateResponse> responseList = new ArrayList<>();
        
        for (Object[] row : results) {
            AggregateResponse response = AggregateResponse.builder()
                    .aggregateId(toInt(row[0]))
                    .aggregateName((String) row[1])
                    .description((String) row[2])
                    .characteristics(parseCharacteristics(row[3]))
                    .build();
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
        Object[] row = results.get(0);
        return AggregateResponse.builder()
                .aggregateId(toInt(row[0]))
                .aggregateName((String) row[1])
                .description((String) row[2])
                .characteristics(parseCharacteristics(row[3]))
                .build();
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

    @SuppressWarnings("unchecked")
    private List<AggregateResponse.AggregateCharacteristicDto> parseCharacteristics(Object characteristicsObj) {
        List<AggregateResponse.AggregateCharacteristicDto> list = new ArrayList<>();
        if (characteristicsObj != null && characteristicsObj instanceof List) {
            List<Map<String, Object>> chars = (List<Map<String, Object>>) characteristicsObj;
            for (Map<String, Object> ch : chars) {
                list.add(AggregateResponse.AggregateCharacteristicDto.builder()
                        .characteristicId(toInt(ch.get("characteristic_id")))
                        .characteristicName((String) ch.get("characteristic_name"))
                        .sortOrder(toInt(ch.get("sort_order")))
                        .build());
            }
        }
        return list;
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
}