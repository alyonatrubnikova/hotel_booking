//запрос на создание/изменение продукта
package ru.etu.hotel.model.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductRequest {
    private String name;
    private String shortName;
    //ID классификации (к какому типу услуг относится)
    private Integer classId;
}
