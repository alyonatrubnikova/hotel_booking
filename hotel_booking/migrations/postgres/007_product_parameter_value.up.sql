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

-- =============================================
-- ПОИСК ПО НЕСКОЛЬКИМ ПАРАМЕТРАМ (С УЧЁТОМ НАСЛЕДОВАНИЯ)
-- =============================================
-- =============================================
-- ПОИСК ПО НЕСКОЛЬКИМ ПАРАМЕТРАМ (ТОЛЬКО СВОИ ЗНАЧЕНИЯ)
-- =============================================

DROP FUNCTION IF EXISTS find_products_by_filters(JSONB);

CREATE OR REPLACE FUNCTION find_products_by_filters(
    p_filters JSONB
)
RETURNS TABLE (
    product_id INTEGER,
    product_name VARCHAR,
    product_short_name VARCHAR,
    class_code VARCHAR,
    parameters JSONB,
    price NUMERIC
) AS $$
DECLARE
    filter_condition TEXT := '';
    filter_item RECORD;
    i INTEGER := 0;
BEGIN
    -- Проходим по всем фильтрам
    FOR filter_item IN 
        SELECT * FROM jsonb_to_recordset(p_filters) AS x(
            characteristic_name VARCHAR,
            operator VARCHAR, 
            value_from NUMERIC, 
            value_to NUMERIC, 
            string_value TEXT
        )
    LOOP
        i := i + 1;
        
        IF filter_item.operator = 'BETWEEN' THEN
            filter_condition := filter_condition || format('
                AND EXISTS (
                    SELECT 1 FROM product_parameter_value ppv
                    WHERE ppv.product_id = p.id 
                      AND ppv.characteristic_id IN (
                          SELECT id FROM enum_characteristic 
                          WHERE characteristic_name = %L AND class_id IN (
                              SELECT class_id FROM product WHERE id = p.id
                          )
                      )
                      AND ppv.value_number BETWEEN %s AND %s
                )',
                filter_item.characteristic_name,
                filter_item.value_from, filter_item.value_to
            );
        ELSIF filter_item.operator = 'LIKE' THEN
            filter_condition := filter_condition || format('
                AND EXISTS (
                    SELECT 1 FROM product_parameter_value ppv
                    WHERE ppv.product_id = p.id 
                      AND ppv.characteristic_id IN (
                          SELECT id FROM enum_characteristic 
                          WHERE characteristic_name = %L AND class_id IN (
                              SELECT class_id FROM product WHERE id = p.id
                          )
                      )
                      AND ppv.value_string ILIKE %L
                )',
                filter_item.characteristic_name,
                '%' || filter_item.string_value || '%'
            );
        ELSE
            filter_condition := filter_condition || format('
                AND EXISTS (
                    SELECT 1 FROM product_parameter_value ppv
                    WHERE ppv.product_id = p.id 
                      AND ppv.characteristic_id IN (
                          SELECT id FROM enum_characteristic 
                          WHERE characteristic_name = %L AND class_id IN (
                              SELECT class_id FROM product WHERE id = p.id
                          )
                      )
                      AND ppv.value_number %s %s
                )',
                filter_item.characteristic_name,
                filter_item.operator, filter_item.value_from
            );
        END IF;
    END LOOP;

    RETURN QUERY EXECUTE format('
        SELECT DISTINCT
            p.id,
            p.name,
            p.short_name,
            ce.class_code,
            COALESCE(
                (SELECT jsonb_object_agg(
                    ec.characteristic_name, 
                    COALESCE(ppv.value_number::TEXT, ppv.value_string)
                 )
                 FROM product_parameter_value ppv
                 JOIN enum_characteristic ec ON ec.id = ppv.characteristic_id
                 WHERE ppv.product_id = p.id),
                ''{}''::jsonb
            ) as parameters,
            COALESCE(
                (SELECT value_number FROM product_parameter_value 
                 WHERE product_id = p.id AND characteristic_id IN (SELECT id FROM enum_characteristic WHERE characteristic_name = ''Price'') LIMIT 1),
                NULL
            ) as price
        FROM product p
        JOIN classification_element ce ON ce.id = p.class_id
        WHERE 1=1 %s
        ORDER BY p.id
    ', filter_condition);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- ЗАЩИТА ОТ НЕКОРРЕКТНОГО ВВОДА
-- =============================================

DROP TRIGGER IF EXISTS validate_numeric_trigger ON product_parameter_value;
DROP TRIGGER IF EXISTS validate_string_trigger ON product_parameter_value;
DROP FUNCTION IF EXISTS validate_numeric_parameter();
DROP FUNCTION IF EXISTS validate_string_parameter();

CREATE OR REPLACE FUNCTION validate_numeric_parameter()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.value_number IS NOT NULL AND NEW.value_number < 0 THEN
        RAISE EXCEPTION 'Значение параметра не может быть отрицательным: %', NEW.value_number;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_numeric_trigger
    BEFORE INSERT OR UPDATE ON product_parameter_value
    FOR EACH ROW
    EXECUTE FUNCTION validate_numeric_parameter();

CREATE OR REPLACE FUNCTION validate_string_parameter()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.value_string IS NOT NULL AND NEW.value_string ~ '^[0-9]+$' THEN
        RAISE EXCEPTION 'Строковый параметр не может содержать только цифры: %', NEW.value_string;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_string_trigger
    BEFORE INSERT OR UPDATE ON product_parameter_value
    FOR EACH ROW
    EXECUTE FUNCTION validate_string_parameter();

-- =============================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- =============================================

DELETE FROM product_parameter_value;

-- Комната 101: WiFi = 150
INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 1, id, 150 FROM enum_characteristic WHERE characteristic_name = 'WiFi' AND class_id = 5
ON CONFLICT DO NOTHING;

-- Комната 101: Food = Breakfast
INSERT INTO product_parameter_value (product_id, characteristic_id, value_string)
SELECT 1, id, 'Breakfast' FROM enum_characteristic WHERE characteristic_name = 'Food' AND class_id = 5
ON CONFLICT DO NOTHING;

-- Комната 102: WiFi = 50
INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 2, id, 50 FROM enum_characteristic WHERE characteristic_name = 'WiFi' AND class_id = 6
ON CONFLICT DO NOTHING;

-- Комната 201: WiFi = 200
INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 3, id, 200 FROM enum_characteristic WHERE characteristic_name = 'WiFi' AND class_id = 8
ON CONFLICT DO NOTHING;

-- Комната 201: Food = Breakfast
INSERT INTO product_parameter_value (product_id, characteristic_id, value_string)
SELECT 3, id, 'Breakfast' FROM enum_characteristic WHERE characteristic_name = 'Food' AND class_id = 8
ON CONFLICT DO NOTHING;

-- Комната 301: Square = 65
INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 4, id, 65 FROM enum_characteristic WHERE characteristic_name = 'Square' AND class_id = 11
ON CONFLICT DO NOTHING;

-- Комната 302: Food = Vegetarian
INSERT INTO product_parameter_value (product_id, characteristic_id, value_string)
SELECT 5, id, 'Vegetarian' FROM enum_characteristic WHERE characteristic_name = 'Food' AND class_id = 12
ON CONFLICT DO NOTHING;

-- =============================================
-- ДОБАВЛЯЕМ ЦЕНЫ ДЛЯ КОМНАТ
-- =============================================

INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 1, id, 5500 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 5
ON CONFLICT DO NOTHING;

INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 2, id, 4800 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 6
ON CONFLICT DO NOTHING;

INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 3, id, 3800 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 8
ON CONFLICT DO NOTHING;

INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 4, id, 6500 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 11
ON CONFLICT DO NOTHING;

INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 5, id, 7000 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 12
ON CONFLICT DO NOTHING;