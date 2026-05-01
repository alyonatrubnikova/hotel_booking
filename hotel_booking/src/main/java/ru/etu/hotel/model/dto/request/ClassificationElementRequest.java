package ru.etu.hotel.model.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassificationElementRequest {
    //Код классификации (клиент присылает "STD_WIFI")
    private String classCode;
    private String name;
    private Boolean isTerminal;
    private Integer sortOrder;
    private String unitOfMeasure;
    private Integer parentId;
    
    //нет поля id
    //потому что при создании нового элемента ID ещё не известен
    //он генерируется базой данных
}
