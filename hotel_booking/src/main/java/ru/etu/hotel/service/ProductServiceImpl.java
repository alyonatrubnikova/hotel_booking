package ru.etu.hotel.service;

import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.etu.hotel.model.dto.request.ProductRequest;
import ru.etu.hotel.model.dto.response.ProductListResponse;
import ru.etu.hotel.model.dto.response.ProductResponse;
import ru.etu.hotel.repository.ProductRepository;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;

    @Override
    public Integer addProduct(ProductRequest request) {
        Integer id = productRepository.insertProduct(
                request.getName(),
                request.getShortName(),
                request.getClassId()
        );
        log.info("Created product: id={}, name={}", id, request.getName());
        return id;
    }

    @Override
    public void deleteProduct(Integer id) {
        Boolean result = productRepository.deleteProduct(id);
        if (!result) {
            throw new EntityNotFoundException("Product with id " + id + " not found");
        }
        log.info("Deleted product: id={}", id);
    }

    @Override
    public void updateClassId(Integer id, Integer newClassId) {
        Boolean result = productRepository.swapProductClass(id, newClassId);
        if (!result) {
            throw new EntityNotFoundException("Product with id " + id + " not found");
        }
        log.info("Updated product class: id={}, newClassId={}", id, newClassId);
    }

    @Override
    public void updateProduct(Integer id, ProductRequest request) {
        Boolean result = productRepository.updateProduct(id, request.getName(), request.getShortName());
        if (!result) {
            throw new EntityNotFoundException("Product with id " + id + " not found");
        }
        log.info("Updated product: id={}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public ProductListResponse getProducts(Integer classId, Integer limit, Integer offset) {
        if (limit == null) limit = 10;//Если клиент не передал
        if (offset == null) offset = 0;

        List<Object[]> results = productRepository.findProducts(classId, limit, offset);

        List<ProductResponse> items = new ArrayList<>();
        Long total = 0L;

        //Преобразование результатов
        for (Object[] row : results) {
            total = row[4] != null ? ((Number) row[4]).longValue() : 0L;
            ProductResponse response = ProductResponse.builder()
                    .id(toInt(row[0]))
                    .name((String) row[1])
                    .shortName((String) row[2])
                    .classId(toInt(row[3]))
                    .build();
            items.add(response);
        }

        return ProductListResponse.builder()
                .total(total)
                .limit(limit)
                .offset(offset)
                .items(items)
                .build();//Создаём и возвращаем DTO с пагинацией
    }

    private Integer toInt(Object obj) {
        return obj != null ? ((Number) obj).intValue() : null;
    }
}
