package ru.etu.hotel.service;

import ru.etu.hotel.model.dto.request.ProductRequest;
import ru.etu.hotel.model.dto.response.ProductListResponse;
import ru.etu.hotel.model.dto.response.ProductResponse;

import java.util.List;

public interface ProductService {

    Integer addProduct(ProductRequest request);

    void deleteProduct(Integer id);

    void updateClassId(Integer id, Integer newClassId);

    void updateProduct(Integer id, ProductRequest request);

    ProductListResponse getProducts(Integer classId, Integer limit, Integer offset);
}
