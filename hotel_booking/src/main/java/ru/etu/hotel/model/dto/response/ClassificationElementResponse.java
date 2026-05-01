//ответ с данными элемента
package ru.etu.hotel.model.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassificationElementResponse {
    //ID созданного элемента (клиент должен его знать)
    private Integer id;
    private String classCode;
    private String name;
    private Boolean isTerminal;
    private Integer sortOrder;
    private String unitOfMeasure;
    private Integer parentId;
    //Уровень вложенности в дереве (вычисляется при чтении)
    private Integer level;
}
