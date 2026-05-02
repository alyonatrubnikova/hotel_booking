package ru.etu.hotel.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import ru.etu.hotel.model.entity.EnumCharacteristic;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public interface EnumCharacteristicRepository extends JpaRepository<EnumCharacteristic, Integer> {
    
    // ========== GET методы через JPQL ==========
    
    @Query("SELECT e FROM EnumCharacteristic e ORDER BY e.classId, e.sortOrder")
    List<EnumCharacteristic> findAllCharacteristics();
    
    @Query("SELECT e FROM EnumCharacteristic e WHERE e.classId = :classId ORDER BY e.sortOrder")
    List<EnumCharacteristic> findCharacteristicsByClass(@Param("classId") Integer classId);
    
    @Query("SELECT e FROM EnumCharacteristic e WHERE e.classId = :classId AND e.characteristicName = :name")
    Optional<EnumCharacteristic> findCharacteristicByClassAndName(@Param("classId") Integer classId, @Param("name") String name);
    
    @Query("SELECT MAX(e.sortOrder) FROM EnumCharacteristic e WHERE e.classId = :classId")
    Integer findMaxSortOrderByClassId(@Param("classId") Integer classId);
    
    // ========== Старые методы через нативные запросы (для совместимости) ==========
    
    @Query(value = "SELECT * FROM get_class_characteristics(:classId)", nativeQuery = true)
    List<Object[]> getClassCharacteristicsNative(@Param("classId") Integer classId);
    
    @Query(value = "SELECT * FROM get_all_characteristics()", nativeQuery = true)
    List<Object[]> getAllCharacteristicsNative();
    
    @Query(value = "SELECT * FROM get_characteristic_value(:classId, :name)", nativeQuery = true)
    List<Object[]> getCharacteristicValueNative(@Param("classId") Integer classId, @Param("name") String name);
    
    // ========== PUT, DELETE, REORDER через JPQL ==========
    
    @Modifying
    @Transactional
    @Query("UPDATE EnumCharacteristic e SET e.sortOrder = :newOrder WHERE e.id = :id")
    void reorderEnumValue(@Param("id") Integer id, @Param("newOrder") Integer newOrder);
    
    @Modifying
    @Transactional
    @Query("UPDATE EnumCharacteristic e SET " +
           "e.characteristicName = COALESCE(:name, e.characteristicName), " +
           "e.valueNumber = COALESCE(:valueNumber, e.valueNumber), " +
           "e.valueString = COALESCE(:valueString, e.valueString), " +
           "e.valueImage = COALESCE(:valueImage, e.valueImage), " +
           "e.unitOfMeasure = COALESCE(:unit, e.unitOfMeasure), " +
           "e.sortOrder = COALESCE(:sortOrder, e.sortOrder) " +
           "WHERE e.id = :id")
    int updateCharacteristicValue(@Param("id") Integer id,
                                  @Param("name") String name,
                                  @Param("valueNumber") BigDecimal valueNumber,
                                  @Param("valueString") String valueString,
                                  @Param("valueImage") String valueImage,
                                  @Param("unit") String unit,
                                  @Param("sortOrder") Integer sortOrder);
    
    @Modifying
    @Transactional
    @Query("DELETE FROM EnumCharacteristic e WHERE e.id = :id")
    int deleteCharacteristicById(@Param("id") Integer id);
    
    // ========== НОВЫЕ МЕТОДЫ ДЛЯ ТРЕБОВАНИЙ 1.3 ==========
    
    /**
     * Получить параметры класса с учётом переопределений (из таблицы class_parameter_override)
     */
    @Query(value = "SELECT * FROM get_class_parameters_with_overrides(:classId)", nativeQuery = true)
    List<Object[]> getClassParametersWithOverrides(@Param("classId") Integer classId);
    
    /**
     * Переопределить параметр для подкласса
     */
    @Query(value = "SELECT override_class_parameter(:classId, :characteristicId, :isInherited, :sortOrder)", nativeQuery = true)
    Boolean overrideClassParameter(@Param("classId") Integer classId,
                                   @Param("characteristicId") Integer characteristicId,
                                   @Param("isInherited") Boolean isInherited,
                                   @Param("sortOrder") Integer sortOrder);
    
    /**
     * Установить ограничения min/max для численного параметра
     */
    @Modifying
    @Transactional
    @Query(value = "UPDATE enum_characteristic SET min_value = :min, max_value = :max WHERE id = :id", nativeQuery = true)
    void setNumericConstraints(@Param("id") Integer id,
                               @Param("min") BigDecimal min,
                               @Param("max") BigDecimal max);
}