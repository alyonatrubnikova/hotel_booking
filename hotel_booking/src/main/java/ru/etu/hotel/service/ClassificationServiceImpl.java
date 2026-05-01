//реализация интерфейса
package ru.etu.hotel.service;

//исключение, если entity не найден
import jakarta.persistence.EntityNotFoundException;
//генерирует конструктор для final полей
import lombok.RequiredArgsConstructor;
//даёт доступ к логгеру log
import lombok.extern.slf4j.Slf4j;
//Spring создаёт бин
import org.springframework.stereotype.Service;
//все методы в одной транзакции
import org.springframework.transaction.annotation.Transactional;
import ru.etu.hotel.model.dto.request.ClassificationElementRequest;
import ru.etu.hotel.model.dto.response.ClassificationElementResponse;
import ru.etu.hotel.model.entity.ClassificationElement;
import ru.etu.hotel.repository.ClassificationElementRepository;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ClassificationServiceImpl implements ClassificationService {

    //Spring автоматически внедряет Repository через конструктор
    //(благодаря @RequiredArgsConstructor)
    private final ClassificationElementRepository repository;

    //переопределяем метод из интерфейса
    @Override
    //Принимает DTO с данными от клиента
    //вызывает insertElement в бд
    //Возвращает Integer — ID созданного элемента
    public Integer addElement(ClassificationElementRequest request) {
        if (repository.existsByClassCode(request.getClassCode())) {
            throw new IllegalArgumentException(
                    "Element with class_code '" + request.getClassCode() + "' already exists");
        }

        Integer id = repository.insertElement(
                request.getClassCode(),
                request.getName(),
                //если клиент не передал, используем значение по умолчанию
                request.getIsTerminal() != null ? request.getIsTerminal() : false,
                request.getSortOrder() != null ? request.getSortOrder() : 0,
                request.getUnitOfMeasure(),
                request.getParentId()
        );

        log.info("Created classification element: id={}, code={}", id, request.getClassCode());
        return id;
    }

    @Override
    public void deleteElement(Integer id) {
        Boolean result = repository.deleteElement(id);
        if (!result) {
            throw new EntityNotFoundException("Classification element with id " + id + " not found");
        }
        log.info("Deleted classification element: id={}", id);
    }

    @Override
    public void moveElement(Integer id, Integer newParentId) {
        Boolean result = repository.swapParent(id, newParentId);
        if (!result) {
            throw new EntityNotFoundException("Classification element with id " + id + " not found");
        }
        log.info("Moved element: id={}, newParentId={}", id, newParentId);
    }

    @Override
    public void changeOrder(Integer id, Integer newSortOrder) {
        Boolean result = repository.changeSortOrder(id, newSortOrder);
        if (!result) {
            throw new EntityNotFoundException("Classification element with id " + id + " not found");
        }
        log.info("Changed sort order: id={}, newOrder={}", id, newSortOrder);
    }

    @Override
    public void changeUnit(Integer id, String newUnit) {
        Boolean result = repository.changeUnitOfMeasure(id, newUnit);
        if (!result) {
            throw new EntityNotFoundException("Classification element with id " + id + " not found");
        }
        log.info("Changed unit of measure: id={}, unit={}", id, newUnit);
    }

    @Override
    //Только чтение - нельзя случайно изменить данные
    @Transactional(readOnly = true)
    public List<ClassificationElementResponse> getChildren(Integer id) {
        //Каждый Object[] — 
        // это строка из результата хранимой процедуры
        List<Object[]> results = repository.findChildren(id);
        //Нужно преобразовать в ClassificationElementResponse
        return mapToObjectArray(results);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClassificationElementResponse> getParents(Integer id) {
        List<Object[]> results = repository.findParents(id);
        return mapToObjectArray(results);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClassificationElementResponse> getTerminalNodes() {
        List<Object[]> results = repository.findTerminalNodes();
        return mapToObjectArrayNoLevel(results);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClassificationElementResponse> getTerminalInBranch(Integer id) {
        List<Object[]> results = repository.findTerminalInBranch(id);
        return mapToObjectArray(results);
    }

    @Override
    @Transactional(readOnly = true)
    //Repository возвращает List<ClassificationElement> 
    // (готовые Entity), а не List<Object[]>
    //Используем JPQL запрос, а не хранимую процедуру
    public List<ClassificationElementResponse> getSiblings(Integer parentId) {
        List<ClassificationElement> siblings = repository.findByParentIdOrderBySortOrder(parentId);
        return siblings.stream()//превращаем список в поток
                .map(this::toResponse)//каждый Entity преобразуем в DTO
                .toList();
    }
    //преобразование Object[] в DTO
    private List<ClassificationElementResponse> mapToObjectArray(List<Object[]> results) {
        List<ClassificationElementResponse> responseList = new ArrayList<>();
        for (Object[] row : results) {
            ClassificationElementResponse response = ClassificationElementResponse.builder()
                    .id(toInt(row[0]))//Преобразуем колонку 0 в id
                    .classCode((String) row[1])
                    .name((String) row[2])
                    .isTerminal((Boolean) row[3])
                    .sortOrder(toInt(row[4]))
                    .unitOfMeasure((String) row[5])
                    .parentId(toInt(row[6]))
                    .level(toInt(row[7]))
                    .build();//Создаём DTO объект
            responseList.add(response);//Добавляем в список
        }
        return responseList;//Возвращаем список DTO
    }

    private List<ClassificationElementResponse> mapToObjectArrayNoLevel(List<Object[]> results) {
        List<ClassificationElementResponse> responseList = new ArrayList<>();
        for (Object[] row : results) {
            ClassificationElementResponse response = ClassificationElementResponse.builder()
                    .id(toInt(row[0]))
                    .classCode((String) row[1])
                    .name((String) row[2])
                    .isTerminal((Boolean) row[3])
                    .sortOrder(toInt(row[4]))
                    .unitOfMeasure((String) row[5])
                    .parentId(toInt(row[6]))
                    .level(null)
                    .build();
            responseList.add(response);
        }
        return responseList;
    }

    //безопасное преобразование
    private Integer toInt(Object obj) {
        if (obj == null) return null;
        if (obj instanceof Number n) return n.intValue();
        return null;
    }

    //Entity в Response DTO
    private ClassificationElementResponse toResponse(ClassificationElement entity) {
        return ClassificationElementResponse.builder()
                .id(entity.getId())
                .classCode(entity.getClassCode())
                .name(entity.getName())
                .isTerminal(entity.getIsTerminal())
                .sortOrder(entity.getSortOrder())
                .unitOfMeasure(entity.getUnitOfMeasure())
                .parentId(entity.getParentId())
                .level(null)
                .build();
    }
}
