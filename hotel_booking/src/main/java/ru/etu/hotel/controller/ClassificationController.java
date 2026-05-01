package ru.etu.hotel.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
//HTTP-статусы (200, 201, 404,)
import org.springframework.http.HttpStatus;
//Обёртка для HTTP-ответа (статус + тело + заголовки)
import org.springframework.http.ResponseEntity;
//Аннотации для маршрутизации (@GetMapping, @PostMapping, )
import org.springframework.web.bind.annotation.*;
//DTO для входящих запросов
import ru.etu.hotel.model.dto.request.ClassificationElementRequest;
//DTO для исходящих ответов
import ru.etu.hotel.model.dto.response.ClassificationElementResponse;
//DTO для возврата ID
import ru.etu.hotel.model.dto.response.IdResponse;
//Сервис с бизнес-логикой
import ru.etu.hotel.service.ClassificationService;

import java.util.List;
import java.util.Map;

//Spring знает что это REST-контроллер, 
//ответы автоматически сериализуются в JSON
@RestController
@RequestMapping("/classification")
@RequiredArgsConstructor
@Slf4j
public class ClassificationController {

    //внедряется один раз через конструктор
    //Spring автоматически создаёт контроллер и передаёт сервис
    private final ClassificationService classificationService;

    // Управление структурой

    @PostMapping
    //Spring парсит JSON из тела запроса в Java-объект
    //Тип возвращаемого значения (статус + тело типа IdResponse)
    public ResponseEntity<IdResponse> addElement(@RequestBody ClassificationElementRequest request) {
        //Вызывает сервис для создания
        Integer id = classificationService.addElement(request);
        log.info("Created element with id={}", id);
        //Устанавливает HTTP-статус 201 Created
        return ResponseEntity.status(HttpStatus.CREATED).body(new IdResponse(id));
    }

    @DeleteMapping("/{id}")
    //Берёт id из URL и передаёт в метод
    public ResponseEntity<Map<String, String>> deleteElement(@PathVariable("id") Integer id) {
        //Вызывает сервис для удаления
        classificationService.deleteElement(id);
        //Статус 200 OK
        return ResponseEntity.ok(Map.of("message", "deleted"));
    }

    //Перемещение к другому родителю
    @PutMapping("/{id}/move")
    public ResponseEntity<Map<String, String>> moveElement(
            @PathVariable("id") Integer id,
            @RequestParam("newParent") Integer newParentId) {//Параметр из query-строки (?newParent=3)
        classificationService.moveElement(id, newParentId);
        return ResponseEntity.ok(Map.of("message", "moved successfully"));
    }//localhost:8080/classification/5/move?newParent=3

    //Изменение порядка сортировки
    @PutMapping("/{id}/order")
    public ResponseEntity<Map<String, String>> changeOrder(
            @PathVariable("id") Integer id,
            @RequestParam("newOrder") Integer newSortOrder) {
        classificationService.changeOrder(id, newSortOrder);
        return ResponseEntity.ok(Map.of("message", "order updated"));
    }//localhost:8080/classification/5/order?newOrder=10

    //Изменение единицы измерения
    @PutMapping("/{id}/unit")
    public ResponseEntity<Map<String, String>> changeUnit(
            @PathVariable("id") Integer id,
            @RequestParam("unit") String newUnit) {
        classificationService.changeUnit(id, newUnit);
        return ResponseEntity.ok(Map.of("message", "unit of measure updated"));
    }//localhost:8080/classification/5/unit?unit=час

    // Информационный поиск

    @GetMapping("/{id}/children")
    public ResponseEntity<List<ClassificationElementResponse>> getChildren(@PathVariable("id") Integer id) {
        //Возвращаем список DTO, получает потомков из БД
        List<ClassificationElementResponse> children = classificationService.getChildren(id);
        return ResponseEntity.ok(children);
    }

    @GetMapping("/{id}/parents")
    public ResponseEntity<List<ClassificationElementResponse>> getParents(@PathVariable("id") Integer id) {
        List<ClassificationElementResponse> parents = classificationService.getParents(id);
        return ResponseEntity.ok(parents);
    }

    @GetMapping("/terminal")
    public ResponseEntity<List<ClassificationElementResponse>> getTerminalNodes() {
        List<ClassificationElementResponse> terminal = classificationService.getTerminalNodes();
        return ResponseEntity.ok(terminal);
    }

    @GetMapping("/{id}/terminal")
    public ResponseEntity<List<ClassificationElementResponse>> getTerminalInBranch(@PathVariable("id") Integer id) {
        List<ClassificationElementResponse> terminal = classificationService.getTerminalInBranch(id);
        return ResponseEntity.ok(terminal);
    }

    @GetMapping("/siblings")
    public ResponseEntity<List<ClassificationElementResponse>> getSiblings(
            @RequestParam(required = false) Integer parentId) {//Если null - вернёт корневые элементы
        List<ClassificationElementResponse> siblings = classificationService.getSiblings(parentId);
        return ResponseEntity.ok(siblings);
    }//localhost:8080/classification/siblings?parentId=1 
}
