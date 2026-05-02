package ru.etu.hotel.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import ru.etu.hotel.model.entity.ParameterAggregate;

import java.util.List;

@Repository
public interface AggregateRepository extends JpaRepository<ParameterAggregate, Integer> {
    
    @Query(value = "SELECT * FROM get_all_aggregates()", nativeQuery = true)
    List<Object[]> getAllAggregates();
    
    @Query(value = "SELECT * FROM get_aggregate_by_id(:aggregateId)", nativeQuery = true)
    List<Object[]> getAggregateById(@Param("aggregateId") Integer aggregateId);
    
    @Modifying
    @Transactional
    @Query(value = "INSERT INTO parameter_aggregate (name, description) VALUES (:name, :description) RETURNING id", nativeQuery = true)
    Integer createAggregate(@Param("name") String name, @Param("description") String description);
    
    @Modifying
    @Transactional
    @Query(value = "SELECT add_characteristic_to_aggregate(:aggregateId, :characteristicId, :sortOrder)", nativeQuery = true)
    Boolean addCharacteristicToAggregate(@Param("aggregateId") Integer aggregateId,
                                          @Param("characteristicId") Integer characteristicId,
                                          @Param("sortOrder") Integer sortOrder);
}