package ru.etu.hotel.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import ru.etu.hotel.model.entity.ProductParameterValue;
import java.util.List;

@Repository
public interface ProductParameterRepository extends JpaRepository<ProductParameterValue, Integer> {

    @Query(value = "SELECT * FROM set_product_parameter(:productId, :characteristicId, :valueNumber, :valueString, :valueImage)", nativeQuery = true)
    Boolean setProductParameter(@Param("productId") Integer productId,
                                @Param("characteristicId") Integer characteristicId,
                                @Param("valueNumber") java.math.BigDecimal valueNumber,
                                @Param("valueString") String valueString,
                                @Param("valueImage") String valueImage);

    @Query(value = "SELECT * FROM get_product_parameters(:productId)", nativeQuery = true)
    List<Object[]> getProductParameters(@Param("productId") Integer productId);

    @Query(value = "SELECT * FROM find_products_by_parameter(:characteristicId, :operator, :value, :stringValue)", nativeQuery = true)
    List<Object[]> findProductsByParameter(@Param("characteristicId") Integer characteristicId,
                                           @Param("operator") String operator,
                                           @Param("value") java.math.BigDecimal value,
                                           @Param("stringValue") String stringValue);
}