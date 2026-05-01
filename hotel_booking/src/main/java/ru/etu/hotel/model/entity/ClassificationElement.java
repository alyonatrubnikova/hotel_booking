package ru.etu.hotel.model.entity;

//импорт всех аннотаций для работы с jpa
import jakarta.persistence.*;

//аннотации ломбока для атвоматич генерации кода
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

//говорит jpa, что этот класс-сущность, которую нужно сохранять в базе данных
//каждая строка объекта будет строкой в таблице
@Entity
//без указания названия таблицы jpa использоал бы имя класса
@Table(name = "classification_element")
//ломбок аннотация генерирующая геттеры сеттеры, toString, equals
@Data
//генерит конструктор без параметров
@NoArgsConstructor
//со всеми параметрами
@AllArgsConstructor
//чтобы не создавать конмтуркторы на все комбинации параметров а конструировать объект как хотим
@Builder
public class ClassificationElement {

//первичный ключ таблицы, уникальный идентификатор каждой строки
    @Id
    //ID генерируется автоматически базой данных
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;//чтобы мог быть null до сохранения

//код элемента классификации ("STD_WIFI", "LUXE_FULL")
    @Column(name = "class_code", length = 64, nullable = false, unique = true)
    private String classCode;

    @Column(name = "name", length = 256, nullable = false)
    private String name;

    @Column(name = "is_terminal", nullable = false)
    private Boolean isTerminal;

//порядок сортировки внутри родителя
    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    @Column(name = "unit_of_measure", length = 64)
    private String unitOfMeasure;

    @Column(name = "parent_id")
    private Integer parentId;

//чтобы не сохранять это поле в бд, оно только в памыти приложения для например вычисления уровня вложенности
    @Transient
    private Integer level;
}
