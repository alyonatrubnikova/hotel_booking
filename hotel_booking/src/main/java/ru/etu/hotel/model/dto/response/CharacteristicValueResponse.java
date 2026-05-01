package ru.etu.hotel.model.dto.response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class CharacteristicValueResponse {
    private BigDecimal valueNumber;
    private String valueString;
    private String valueImage;
    private String unitOfMeasure;
}