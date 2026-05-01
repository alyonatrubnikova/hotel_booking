//ответ со списком продуктов (пагинация)
package ru.etu.hotel.model.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductListResponse {
    //Общее количество продуктов
    private Long total;
    //сколько записей взять после пропуска
    private Integer limit;
    //сколько записей пропустить от начала
    private Integer offset;
    //Список продуктов
    private List<ProductResponse> items;
}
