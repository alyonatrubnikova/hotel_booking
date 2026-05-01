package ru.etu.hotel.repository;

//импортирует JpaRepository - базовый интерфейс Spring Data JPA 
//с готовыми CRUD методами.
import org.springframework.data.jpa.repository.JpaRepository;
//для операций INSERT/UPDATE/DELETE(тут нету)
import org.springframework.data.jpa.repository.Modifying;
//для написания SQL-запросов вручную
import org.springframework.data.jpa.repository.Query;
//для именованных параметров в запросах
import org.springframework.data.repository.query.Param;
//делает этот интерфейс Spring-бином
import org.springframework.stereotype.Repository;
//иморт нашей сущности
import ru.etu.hotel.model.entity.ClassificationElement;

import java.util.List;

@Repository
public interface ClassificationElementRepository extends JpaRepository<ClassificationElement, Integer> {

//Spring сам создаёт SQL(т е запрос не надо описывать)
    boolean existsByClassCode(String classCode);

//вызываем в запросе процедуру хранимую из бд,
//которая принимает параметры:
    //описываем SQL запрос = что выполнить
    @Query(value = "SELECT insert_classification_element(" +
            ":classCode, :name, :isTerminal, :sortOrder, :unitOfMeasure, :parentId)",
            nativeQuery = true)
    //создаём Java метод и связываем параметры метода с параметрами SQL
    // = как вызвать из Java-кода
    Integer insertElement(@Param("classCode") String classCode,
                          @Param("name") String name,
                          @Param("isTerminal") Boolean isTerminal,
                          @Param("sortOrder") Integer sortOrder,
                          @Param("unitOfMeasure") String unitOfMeasure,
                          @Param("parentId") Integer parentId);

    @Query(value = "SELECT swap_parent(:elementId, :newParentId)", nativeQuery = true)
    Boolean swapParent(@Param("elementId") Integer elementId,
                       @Param("newParentId") Integer newParentId);

    @Query(value = "SELECT delete_classification_element(:elementId)", nativeQuery = true)
    Boolean deleteElement(@Param("elementId") Integer elementId);

    @Query(value = "SELECT change_sort_order(:elementId, :newSortOrder)", nativeQuery = true)
    Boolean changeSortOrder(@Param("elementId") Integer elementId,
                            @Param("newSortOrder") Integer newSortOrder);

    @Query(value = "SELECT change_unit_of_measure(:elementId, :newUnit)", nativeQuery = true)
    Boolean changeUnitOfMeasure(@Param("elementId") Integer elementId,
                                @Param("newUnit") String newUnit);

    //find_children-хранимая процедура, возвращает таблицу
    @Query(value = "SELECT * FROM find_children(:elementId)", nativeQuery = true)
    //каждая строка это массив значений (id, class_code, name, etc.)
    List<Object[]> findChildren(@Param("elementId") Integer elementId);

    @Query(value = "SELECT * FROM find_parents(:elementId)", nativeQuery = true)
    List<Object[]> findParents(@Param("elementId") Integer elementId);

    @Query(value = "SELECT * FROM find_terminal_nodes()", nativeQuery = true)
    List<Object[]> findTerminalNodes();

    @Query(value = "SELECT * FROM find_terminal_in_branch(:elementId)", nativeQuery = true)
    List<Object[]> findTerminalInBranch(@Param("elementId") Integer elementId);

    //JPQL а не SQL, потому что обычный SELECT без хранимых процедур, 
    //сразу получаем ClassificationElement, а не массивы
    @Query("SELECT c FROM ClassificationElement c WHERE c.parentId = :parentId ORDER BY c.sortOrder")
    List<ClassificationElement> findByParentIdOrderBySortOrder(@Param("parentId") Integer parentId);

    List<ClassificationElement> findByIsTerminalTrueOrderBySortOrder();
}
