//ответ с ID созданного ресурса
package ru.etu.hotel.model.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class IdResponse {
    //Когда клиент создаёт ресурс, 
    //сервер возвращает только ID нового объекта
    private Integer id;
}
