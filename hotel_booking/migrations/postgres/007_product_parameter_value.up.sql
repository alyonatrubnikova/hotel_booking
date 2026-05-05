-- 007_product_parameter_value.up.sql
-- Таблица для значений параметров конкретных изделий

CREATE TABLE IF NOT EXISTS product_parameter_value (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES product(id) ON DELETE CASCADE,
    characteristic_id INTEGER NOT NULL REFERENCES enum_characteristic(id) ON DELETE CASCADE,
    value_number NUMERIC(10, 2),
    value_string TEXT,
    value_image VARCHAR(512),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, characteristic_id)
);

CREATE INDEX IF NOT EXISTS idx_product_param_product ON product_parameter_value(product_id);
CREATE INDEX IF NOT EXISTS idx_product_param_characteristic ON product_parameter_value(characteristic_id);

-- Триггер для обновления updated_at
CREATE OR REPLACE FUNCTION update_product_param_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_product_param_timestamp ON product_parameter_value;
CREATE TRIGGER update_product_param_timestamp
    BEFORE UPDATE ON product_parameter_value
    FOR EACH ROW
    EXECUTE FUNCTION update_product_param_updated_at();

-- Функция: установить параметр изделия
CREATE OR REPLACE FUNCTION set_product_parameter(
    p_product_id INTEGER,
    p_characteristic_id INTEGER,
    p_value_number NUMERIC DEFAULT NULL,
    p_value_string TEXT DEFAULT NULL,
    p_value_image VARCHAR DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO product_parameter_value (product_id, characteristic_id, value_number, value_string, value_image)
    VALUES (p_product_id, p_characteristic_id, p_value_number, p_value_string, p_value_image)
    ON CONFLICT (product_id, characteristic_id) 
    DO UPDATE SET 
        value_number = EXCLUDED.value_number,
        value_string = EXCLUDED.value_string,
        value_image = EXCLUDED.value_image,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Функция: получить все параметры изделия (с наследованием)
CREATE OR REPLACE FUNCTION get_product_parameters(p_product_id INTEGER)
RETURNS TABLE (
    characteristic_id INTEGER,
    characteristic_name VARCHAR(128),
    class_id INTEGER,
    class_code VARCHAR(64),
    value_number NUMERIC,
    value_string TEXT,
    value_image VARCHAR(512),
    unit_of_measure VARCHAR(64),
    is_inherited BOOLEAN,
    sort_order INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE class_hierarchy AS (
        SELECT p.class_id, 0 AS level
        FROM product p
        WHERE p.id = p_product_id
        
        UNION ALL
        
        SELECT ce.parent_id, ch.level + 1
        FROM class_hierarchy ch
        JOIN classification_element ce ON ce.id = ch.class_id
        WHERE ce.parent_id IS NOT NULL
    ),
    all_characteristics AS (
        SELECT DISTINCT ON (ec.id)
            ec.id AS characteristic_id,
            ec.characteristic_name,
            ec.class_id,
            ce.class_code,
            ec.unit_of_measure,
            ec.sort_order,
            ch.level AS inheritance_level
        FROM class_hierarchy ch
        JOIN enum_characteristic ec ON ec.class_id = ch.class_id
        JOIN classification_element ce ON ce.id = ec.class_id
        ORDER BY ec.id, ch.level ASC
    )
    SELECT 
        ac.characteristic_id,
        ac.characteristic_name,
        ac.class_id,
        ac.class_code,
        COALESCE(ppv.value_number, ec.value_number) AS value_number,
        COALESCE(ppv.value_string, ec.value_string) AS value_string,
        COALESCE(ppv.value_image, ec.value_image) AS value_image,
        ac.unit_of_measure,
        (ppv.id IS NULL) AS is_inherited,
        ac.sort_order
    FROM all_characteristics ac
    LEFT JOIN enum_characteristic ec ON ec.id = ac.characteristic_id
    LEFT JOIN product_parameter_value ppv ON ppv.product_id = p_product_id AND ppv.characteristic_id = ac.characteristic_id
    ORDER BY ac.inheritance_level, ac.sort_order;
END;
$$ LANGUAGE plpgsql;

-- Функция: найти изделия по значению параметра
CREATE OR REPLACE FUNCTION find_products_by_parameter(
    p_characteristic_id INTEGER,
    p_operator VARCHAR(2),
    p_value NUMERIC DEFAULT NULL,
    p_string TEXT DEFAULT NULL
)
RETURNS TABLE (
    product_id INTEGER,
    product_name VARCHAR(256),
    product_short_name VARCHAR(128),
    class_code VARCHAR(64),
    parameter_value_numeric NUMERIC,
    parameter_value_string TEXT
) AS $$
BEGIN
    IF p_operator = 'LIKE' THEN
        RETURN QUERY
        SELECT DISTINCT
            p.id,
            p.name,
            p.short_name,
            ce.class_code,
            NULL::NUMERIC,
            ppv.value_string
        FROM product p
        JOIN classification_element ce ON ce.id = p.class_id
        JOIN product_parameter_value ppv ON ppv.product_id = p.id
        WHERE ppv.characteristic_id = p_characteristic_id
          AND ppv.value_string LIKE p_string;
    ELSE
        RETURN QUERY
        SELECT DISTINCT
            p.id,
            p.name,
            p.short_name,
            ce.class_code,
            ppv.value_number,
            NULL::TEXT
        FROM product p
        JOIN classification_element ce ON ce.id = p.class_id
        JOIN product_parameter_value ppv ON ppv.product_id = p.id
        WHERE ppv.characteristic_id = p_characteristic_id
          AND (
              (p_operator = '=' AND ppv.value_number = p_value) OR
              (p_operator = '>' AND ppv.value_number > p_value) OR
              (p_operator = '<' AND ppv.value_number < p_value) OR
              (p_operator = '>=' AND ppv.value_number >= p_value) OR
              (p_operator = '<=' AND ppv.value_number <= p_value)
          );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- =============================================

DELETE FROM product_parameter_value;

-- Комната 101: WiFi = 150
INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
VALUES (1, 10, 150)
ON CONFLICT (product_id, characteristic_id) DO UPDATE 
SET value_number = EXCLUDED.value_number;

-- Комната 102: WiFi = 50
INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
VALUES (2, 16, 50)
ON CONFLICT (product_id, characteristic_id) DO UPDATE 
SET value_number = EXCLUDED.value_number;

-- Комната 201: WiFi = 200
INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
VALUES (3, 28, 200)
ON CONFLICT (product_id, characteristic_id) DO UPDATE 
SET value_number = EXCLUDED.value_number;

-- Комната 301: площадь = 65
INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
VALUES (4, 49, 65)
ON CONFLICT (product_id, characteristic_id) DO UPDATE 
SET value_number = EXCLUDED.value_number;

-- Комната 302: питание Vegetarian
INSERT INTO product_parameter_value (product_id, characteristic_id, value_string)
VALUES (5, 53, 'Vegetarian')
ON CONFLICT (product_id, characteristic_id) DO UPDATE 
SET value_string = EXCLUDED.value_string;