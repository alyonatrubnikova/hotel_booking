package ru.etu.hotel.model.dto.request;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class CharacteristicRequest {
    private String characteristicName;
    private Integer classId;
    private BigDecimal valueNumber;
    private String valueString;
    private String valueImage;
    private String unitOfMeasure;
    private Integer sortOrder;
}