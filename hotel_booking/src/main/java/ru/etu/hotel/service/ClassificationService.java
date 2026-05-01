//интерфейс
package ru.etu.hotel.service;

import ru.etu.hotel.model.dto.request.ClassificationElementRequest;
import ru.etu.hotel.model.dto.response.ClassificationElementResponse;

import java.util.List;

public interface ClassificationService {

    Integer addElement(ClassificationElementRequest request);

    void deleteElement(Integer id);

    void moveElement(Integer id, Integer newParentId);

    void changeOrder(Integer id, Integer newSortOrder);

    void changeUnit(Integer id, String newUnit);

    List<ClassificationElementResponse> getChildren(Integer id);

    List<ClassificationElementResponse> getParents(Integer id);

    List<ClassificationElementResponse> getTerminalNodes();

    List<ClassificationElementResponse> getTerminalInBranch(Integer id);

    List<ClassificationElementResponse> getSiblings(Integer parentId);
}
