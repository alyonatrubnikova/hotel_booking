-- 005_cascade_delete_trigger.up.sql

-- Функция: перед удалением перемещает детей к родителю удаляемого элемента
CREATE OR REPLACE FUNCTION promote_children_on_delete()
RETURNS TRIGGER AS
$$
BEGIN
    -- Перемещаем всех детей удаляемого элемента к его родителю
    UPDATE classification_element
    SET parent_id = OLD.parent_id
    WHERE parent_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Триггер срабатывает ПЕРЕД удалением
DROP TRIGGER IF EXISTS promote_children_trigger ON classification_element;

CREATE TRIGGER promote_children_trigger
    BEFORE DELETE ON classification_element
    FOR EACH ROW
    EXECUTE FUNCTION promote_children_on_delete();
