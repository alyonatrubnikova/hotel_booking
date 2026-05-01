-- 003_create_product_table.up.sql

CREATE TABLE IF NOT EXISTS product (
    id SERIAL PRIMARY KEY,
    name VARCHAR(256) NOT NULL,
    short_name VARCHAR(128) NOT NULL,
    class_id INTEGER REFERENCES classification_element(id) ON DELETE SET NULL
);

CREATE INDEX idx_product_class_id ON product(class_id);

-- Функция вставки продукта
CREATE OR REPLACE FUNCTION insert_product(
    p_name VARCHAR(256),
    p_short_name VARCHAR(128),
    p_class_id INTEGER DEFAULT NULL
)
RETURNS INTEGER AS
$$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO product (name, short_name, class_id)
    VALUES (p_name, p_short_name, p_class_id)
    RETURNING id INTO new_id;

    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- Удаление продукта
CREATE OR REPLACE FUNCTION delete_product(
    p_product_id INTEGER
)
RETURNS BOOLEAN AS
$$
DECLARE
    deleted INTEGER;
BEGIN
    DELETE FROM product WHERE id = p_product_id;

    GET DIAGNOSTICS deleted = ROW_COUNT;

    IF deleted > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Смена класса продукта
CREATE OR REPLACE FUNCTION swap_product_class(
    p_product_id INTEGER,
    p_new_class_id INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS
$$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE product SET class_id = p_new_class_id
    WHERE id = p_product_id;

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    IF updated_count > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Class % not found', p_new_class_id;
END;
$$ LANGUAGE plpgsql;

-- Обновление имени продукта
CREATE OR REPLACE FUNCTION update_product(
    p_product_id INTEGER,
    p_name VARCHAR(256),
    p_short_name VARCHAR(128)
)
RETURNS BOOLEAN AS
$$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE product SET name = p_name, short_name = p_short_name
    WHERE id = p_product_id;

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    IF updated_count > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Список продуктов с пагинацией и фильтрацией по классу
CREATE OR REPLACE FUNCTION find_products(
    p_class_id INTEGER DEFAULT NULL,
    p_limit INTEGER DEFAULT 10,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    name VARCHAR(256),
    short_name VARCHAR(128),
    class_id INTEGER,
    total_count BIGINT
) AS
$$
BEGIN
    RETURN QUERY
    SELECT p.id, p.name, p.short_name, p.class_id,
           (SELECT COUNT(*) FROM product pr WHERE (p_class_id IS NULL OR pr.class_id = p_class_id)) AS total_count
    FROM product p
    WHERE (p_class_id IS NULL OR p.class_id = p_class_id)
    ORDER BY p.id
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;
