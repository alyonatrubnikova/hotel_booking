-- 002_add_procedures.up.sql

-- ========== УПРАВЛЕНИЕ СТРУКТУРОЙ ==========

-- Добавить вершину
CREATE OR REPLACE FUNCTION insert_classification_element(
    p_class_code VARCHAR(64),
    p_name VARCHAR(256),
    p_is_terminal BOOLEAN DEFAULT FALSE,
    p_sort_order INTEGER DEFAULT 0,
    p_unit_of_measure VARCHAR(64) DEFAULT NULL,
    p_parent_id INTEGER DEFAULT NULL
)
RETURNS INTEGER AS
$$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO classification_element (class_code, name, is_terminal, sort_order, unit_of_measure, parent_id)
    VALUES (p_class_code, p_name, p_is_terminal, p_sort_order, p_unit_of_measure, p_parent_id)
    RETURNING id INTO new_id;

    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- Сменить родителя (переместить вершину)
CREATE OR REPLACE FUNCTION swap_parent(
    p_element_id INTEGER,
    p_new_parent_id INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS
$$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE classification_element SET parent_id = p_new_parent_id
    WHERE id = p_element_id;

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    IF updated_count > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Parent element % not found', p_new_parent_id;
END;
$$ LANGUAGE plpgsql;

-- Удалить вершину
CREATE OR REPLACE FUNCTION delete_classification_element(
    p_element_id INTEGER
)
RETURNS BOOLEAN AS
$$
DECLARE
    deleted INTEGER;
BEGIN
    DELETE FROM classification_element WHERE id = p_element_id;

    GET DIAGNOSTICS deleted = ROW_COUNT;

    IF deleted > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Изменить порядок сортировки
CREATE OR REPLACE FUNCTION change_sort_order(
    p_element_id INTEGER,
    p_new_sort_order INTEGER
)
RETURNS BOOLEAN AS
$$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE classification_element SET sort_order = p_new_sort_order
    WHERE id = p_element_id;

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    IF updated_count > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Изменить единицу измерения
CREATE OR REPLACE FUNCTION change_unit_of_measure(
    p_element_id INTEGER,
    p_new_unit VARCHAR(64)
)
RETURNS BOOLEAN AS
$$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE classification_element SET unit_of_measure = p_new_unit
    WHERE id = p_element_id;

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    IF updated_count > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ========== ПОИСК ==========

-- Найти всех потомков (рекурсивно)
CREATE OR REPLACE FUNCTION find_children(
    p_element_id INTEGER
)
RETURNS TABLE (
    id INTEGER,
    class_code VARCHAR(64),
    name VARCHAR(256),
    is_terminal BOOLEAN,
    sort_order INTEGER,
    unit_of_measure VARCHAR(64),
    parent_id INTEGER,
    level INTEGER
) AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE descendants AS (
        SELECT c.id, c.class_code, c.name, c.is_terminal, c.sort_order, c.unit_of_measure, c.parent_id, 1 AS level
        FROM classification_element c
        WHERE c.id = p_element_id

        UNION ALL

        SELECT c.id, c.class_code, c.name, c.is_terminal, c.sort_order, c.unit_of_measure, c.parent_id, d.level + 1
        FROM descendants d
        JOIN classification_element c ON c.parent_id = d.id
    )
    SELECT d.id, d.class_code, d.name, d.is_terminal, d.sort_order, d.unit_of_measure, d.parent_id, d.level
    FROM descendants d
    WHERE d.id != p_element_id
    ORDER BY d.level, d.sort_order;
END;
$$ LANGUAGE plpgsql;

-- Найти всех родителей (путь до корня)
CREATE OR REPLACE FUNCTION find_parents(
    p_element_id INTEGER
)
RETURNS TABLE (
    id INTEGER,
    class_code VARCHAR(64),
    name VARCHAR(256),
    is_terminal BOOLEAN,
    sort_order INTEGER,
    unit_of_measure VARCHAR(64),
    parent_id INTEGER,
    level INTEGER
) AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE ancestors AS (
        SELECT p.id, p.class_code, p.name, p.is_terminal, p.sort_order, p.unit_of_measure, p.parent_id, 1 AS level
        FROM classification_element p
        WHERE p.id = p_element_id

        UNION ALL

        SELECT p.id, p.class_code, p.name, p.is_terminal, p.sort_order, p.unit_of_measure, p.parent_id, a.level + 1
        FROM ancestors a
        JOIN classification_element p ON a.parent_id = p.id
    )
    SELECT a.id, a.class_code, a.name, a.is_terminal, a.sort_order, a.unit_of_measure, a.parent_id, a.level
    FROM ancestors a
    WHERE a.id != p_element_id
    ORDER BY a.level;
END;
$$ LANGUAGE plpgsql;

-- Найти терминальные (листовые) узлы
CREATE OR REPLACE FUNCTION find_terminal_nodes()
RETURNS TABLE (
    id INTEGER,
    class_code VARCHAR(64),
    name VARCHAR(256),
    is_terminal BOOLEAN,
    sort_order INTEGER,
    unit_of_measure VARCHAR(64),
    parent_id INTEGER
) AS
$$
BEGIN
    RETURN QUERY
    SELECT c.id, c.class_code, c.name, c.is_terminal, c.sort_order, c.unit_of_measure, c.parent_id
    FROM classification_element c
    WHERE c.is_terminal = TRUE
    ORDER BY c.sort_order;
END;
$$ LANGUAGE plpgsql;

-- Найти терминальные узлы в ветке элемента
CREATE OR REPLACE FUNCTION find_terminal_in_branch(
    p_element_id INTEGER
)
RETURNS TABLE (
    id INTEGER,
    class_code VARCHAR(64),
    name VARCHAR(256),
    is_terminal BOOLEAN,
    sort_order INTEGER,
    unit_of_measure VARCHAR(64),
    parent_id INTEGER,
    level INTEGER
) AS
$$
BEGIN
    RETURN QUERY
    WITH RECURSIVE descendants AS (
        SELECT c.id, c.class_code, c.name, c.is_terminal, c.sort_order, c.unit_of_measure, c.parent_id, 1 AS level
        FROM classification_element c
        WHERE c.id = p_element_id

        UNION ALL

        SELECT c.id, c.class_code, c.name, c.is_terminal, c.sort_order, c.unit_of_measure, c.parent_id, d.level + 1
        FROM descendants d
        JOIN classification_element c ON c.parent_id = d.id
    )
    SELECT d.id, d.class_code, d.name, d.is_terminal, d.sort_order, d.unit_of_measure, d.parent_id, d.level
    FROM descendants d
    WHERE d.is_terminal = TRUE AND d.id != p_element_id
    ORDER BY d.level, d.sort_order;
END;
$$ LANGUAGE plpgsql;

-- ========== ПРЕДОТВРАЩЕНИЕ ЦИКЛОВ ==========

CREATE OR REPLACE FUNCTION prevent_classification_cycle()
RETURNS TRIGGER AS
$$
DECLARE
    v_current_id INTEGER;
    v_parent_id INTEGER;
    v_cycle_detected BOOLEAN := FALSE;
BEGIN
    IF NEW.parent_id IS NOT NULL THEN
        v_current_id := NEW.id;
        v_parent_id := NEW.parent_id;

        WHILE v_parent_id IS NOT NULL LOOP
            IF v_parent_id = v_current_id THEN
                v_cycle_detected := TRUE;
                EXIT;
            END IF;

            SELECT parent_id INTO v_parent_id
            FROM classification_element
            WHERE id = v_parent_id;
        END LOOP;

        IF v_cycle_detected THEN
            RAISE EXCEPTION 'Cycle detected in classification hierarchy: element % would become its own ancestor', NEW.id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_classification_cycle_trigger
    BEFORE INSERT OR UPDATE OF parent_id ON classification_element
    FOR EACH ROW
    EXECUTE FUNCTION prevent_classification_cycle();
