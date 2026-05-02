package ru.etu.hotel.model.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "product_parameter_value")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductParameterValue {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "product_id", nullable = false)
    private Integer productId;

    @Column(name = "characteristic_id", nullable = false)
    private Integer characteristicId;

    @Column(name = "value_number")
    private BigDecimal valueNumber;

    @Column(name = "value_string")
    private String valueString;

    @Column(name = "value_image")
    private String valueImage;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}