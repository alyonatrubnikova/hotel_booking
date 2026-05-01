package ru.etu.hotel.model.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "enum_characteristic")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EnumCharacteristic {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @Column(name = "characteristic_name", length = 128, nullable = false)
    private String characteristicName;
    
    @Column(name = "class_id", nullable = false)
    private Integer classId;
    
    @Column(name = "value_number")
    private BigDecimal valueNumber;
    
    @Column(name = "value_string")
    private String valueString;
    
    @Column(name = "value_image", length = 512)
    private String valueImage;
    
    @Column(name = "unit_of_measure", length = 64)
    private String unitOfMeasure;
    
    @Column(name = "sort_order")
    private Integer sortOrder;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (sortOrder == null) {
            sortOrder = 0;
        }
    }
}