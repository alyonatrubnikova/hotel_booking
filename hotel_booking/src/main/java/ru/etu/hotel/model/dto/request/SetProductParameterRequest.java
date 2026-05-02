package ru.etu.hotel.model.dto.request;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class SetProductParameterRequest {
    private Integer characteristicId;
    private BigDecimal valueNumber;
    private String valueString;
    private String valueImage;
}