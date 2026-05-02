package ru.etu.hotel.model.dto.request;

import lombok.Data;

@Data
public class CreateAggregateRequest {
    private String name;
    private String description;
}