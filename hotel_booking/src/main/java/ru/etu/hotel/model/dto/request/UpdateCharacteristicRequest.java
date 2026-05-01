package ru.etu.hotel.model.dto.request;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class UpdateCharacteristicRequest {
    private String characteristicName;
    private BigDecimal valueNumber;
    private String valueString;
    private String valueImage;
    private String unitOfMeasure;
    private Integer sortOrder;
}