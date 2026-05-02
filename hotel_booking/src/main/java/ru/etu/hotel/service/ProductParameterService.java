package ru.etu.hotel.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.etu.hotel.model.dto.request.SetProductParameterRequest;
import ru.etu.hotel.model.dto.response.ProductParameterResponse;
import ru.etu.hotel.repository.ProductParameterRepository;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ProductParameterService {

    private final ProductParameterRepository repository;

    public void setProductParameter(Integer productId, SetProductParameterRequest request) {
        Boolean result = repository.setProductParameter(
            productId,
            request.getCharacteristicId(),
            request.getValueNumber(),
            request.getValueString(),
            request.getValueImage()
        );
        log.info("Set parameter {} for product {}", request.getCharacteristicId(), productId);
    }

    @Transactional(readOnly = true)
    public List<ProductParameterResponse> getProductParameters(Integer productId) {
        List<Object[]> results = repository.getProductParameters(productId);
        List<ProductParameterResponse> responseList = new ArrayList<>();
        
        for (Object[] row : results) {
            ProductParameterResponse response = ProductParameterResponse.builder()
                .characteristicId(toInt(row[0]))
                .characteristicName((String) row[1])
                .classId(toInt(row[2]))
                .classCode((String) row[3])
                .valueNumber(row[4] != null ? new BigDecimal(row[4].toString()) : null)
                .valueString((String) row[5])
                .valueImage((String) row[6])
                .unitOfMeasure((String) row[7])
                .isInherited((Boolean) row[8])
                .sortOrder(toInt(row[9]))
                .build();
            responseList.add(response);
        }
        return responseList;
    }

    @Transactional(readOnly = true)
    public List<Object[]> findProductsByParameter(Integer characteristicId, String operator, BigDecimal value, String stringValue) {
        return repository.findProductsByParameter(characteristicId, operator, value, stringValue);
    }

    private Integer toInt(Object obj) {
        if (obj == null) return null;
        if (obj instanceof Number n) return n.intValue();
        return null;
    }
}