package ru.etu.hotel.model.dto.response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class ProductParameterResponse {
    private Integer characteristicId;
    private String characteristicName;
    private Integer classId;
    private String classCode;
    private BigDecimal valueNumber;
    private String valueString;
    private String valueImage;
    private String unitOfMeasure;
    private Boolean isInherited;
    private Integer sortOrder;
}
