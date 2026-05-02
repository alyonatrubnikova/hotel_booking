package ru.etu.hotel.model.dto.response;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class AggregateResponse {
    private Integer aggregateId;
    private String aggregateName;
    private String description;
    private List<AggregateCharacteristicDto> characteristics;
    
    @Data
    @Builder
    public static class AggregateCharacteristicDto {
        private Integer characteristicId;
        private String characteristicName;
        private Integer sortOrder;
    }
}