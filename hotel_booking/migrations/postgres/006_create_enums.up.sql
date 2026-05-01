-- 006_create_enums.up.sql


-- Основная таблица характеристик
CREATE TABLE IF NOT EXISTS enum_characteristic (
    id SERIAL PRIMARY KEY,
    characteristic_name VARCHAR(128) NOT NULL,
    class_id INTEGER NOT NULL,
    value_number NUMERIC,
    value_string TEXT,
    value_image VARCHAR(512),
    unit_of_measure VARCHAR(64),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Индексы для быстрого поиска
CREATE INDEX idx_enum_char_class ON enum_characteristic(class_id);
CREATE INDEX idx_enum_char_name ON enum_characteristic(characteristic_name);
CREATE INDEX idx_enum_char_class_name ON enum_characteristic(class_id, characteristic_name);

-- =====================================================
-- ОГРАНИЧЕНИЯ НА ДОПУСТИМЫЕ ЗНАЧЕНИЯ (только yes/no)
-- =====================================================

-- Для Bar: только 'yes', 'no' или NULL
ALTER TABLE enum_characteristic 
ADD CONSTRAINT check_bar_values CHECK (
    characteristic_name != 'Bar' OR 
    value_string IN ('yes', 'no', NULL)
);

-- Для Transfer: только 'yes', 'no' или NULL
ALTER TABLE enum_characteristic 
ADD CONSTRAINT check_transfer_values CHECK (
    characteristic_name != 'Transfer' OR 
    value_string IN ('yes', 'no', NULL)
);

-- =====================================================
-- ХРАНИМЫЕ ПРОЦЕДУРЫ
-- =====================================================

-- 1. Добавить характеристику с числовым значением
CREATE OR REPLACE FUNCTION add_number_characteristic(
    p_name VARCHAR(128),
    p_class_id INTEGER,
    p_value NUMERIC,
    p_unit VARCHAR(64) DEFAULT NULL,
    p_sort_order INTEGER DEFAULT 0
) RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order)
    VALUES (p_name, p_class_id, p_value, p_unit, p_sort_order)
    RETURNING id INTO new_id;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- 2. Добавить характеристику со строковым значением
CREATE OR REPLACE FUNCTION add_string_characteristic(
    p_name VARCHAR(128),
    p_class_id INTEGER,
    p_value TEXT,
    p_unit VARCHAR(64) DEFAULT NULL,
    p_sort_order INTEGER DEFAULT 0
) RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO enum_characteristic (characteristic_name, class_id, value_string, unit_of_measure, sort_order)
    VALUES (p_name, p_class_id, p_value, p_unit, p_sort_order)
    RETURNING id INTO new_id;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Добавить характеристику с изображением
CREATE OR REPLACE FUNCTION add_image_characteristic(
    p_name VARCHAR(128),
    p_class_id INTEGER,
    p_value VARCHAR(512),
    p_unit VARCHAR(64) DEFAULT NULL,
    p_sort_order INTEGER DEFAULT 0
) RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO enum_characteristic (characteristic_name, class_id, value_image, unit_of_measure, sort_order)
    VALUES (p_name, p_class_id, p_value, p_unit, p_sort_order)
    RETURNING id INTO new_id;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- 4. Получить все характеристики для класса
CREATE OR REPLACE FUNCTION get_class_characteristics(p_class_id INTEGER)
RETURNS TABLE(
    id INTEGER,
    characteristic_name VARCHAR,
    value_number NUMERIC,
    value_string TEXT,
    value_image VARCHAR,
    unit_of_measure VARCHAR,
    sort_order INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT ec.id, ec.characteristic_name, 
           ec.value_number, ec.value_string, ec.value_image, 
           ec.unit_of_measure, ec.sort_order
    FROM enum_characteristic ec
    WHERE ec.class_id = p_class_id
    ORDER BY ec.sort_order, ec.id;
END;
$$ LANGUAGE plpgsql;

-- 5. Получить конкретную характеристику по имени и классу
CREATE OR REPLACE FUNCTION get_characteristic_value(
    p_class_id INTEGER,
    p_name VARCHAR
) RETURNS TABLE(
    value_number NUMERIC,
    value_string TEXT,
    value_image VARCHAR,
    unit_of_measure VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT ec.value_number, ec.value_string, ec.value_image, ec.unit_of_measure
    FROM enum_characteristic ec
    WHERE ec.class_id = p_class_id AND ec.characteristic_name = p_name;
END;
$$ LANGUAGE plpgsql;

-- 6. Изменить порядок значений (переместить)
CREATE OR REPLACE FUNCTION reorder_enum_value(
    p_value_id INTEGER,
    p_new_order INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_class_id INTEGER;
    v_old_order INTEGER;
BEGIN
    SELECT class_id, sort_order INTO v_class_id, v_old_order
    FROM enum_characteristic WHERE id = p_value_id;
    
    IF v_class_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    IF v_old_order < p_new_order THEN
        UPDATE enum_characteristic 
        SET sort_order = sort_order - 1
        WHERE class_id = v_class_id 
          AND sort_order > v_old_order 
          AND sort_order <= p_new_order;
    ELSIF v_old_order > p_new_order THEN
        UPDATE enum_characteristic 
        SET sort_order = sort_order + 1
        WHERE class_id = v_class_id 
          AND sort_order >= p_new_order 
          AND sort_order < v_old_order;
    END IF;
    
    UPDATE enum_characteristic SET sort_order = p_new_order WHERE id = p_value_id;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 7. Изменить значение характеристики
CREATE OR REPLACE FUNCTION update_characteristic_value(
    p_characteristic_id INTEGER,
    p_characteristic_name VARCHAR DEFAULT NULL,
    p_value_number NUMERIC DEFAULT NULL,
    p_value_string TEXT DEFAULT NULL,
    p_value_image VARCHAR DEFAULT NULL,
    p_unit VARCHAR DEFAULT NULL,
    p_sort_order INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE enum_characteristic 
    SET characteristic_name = COALESCE(p_characteristic_name, characteristic_name),
        value_number = COALESCE(p_value_number, value_number),
        value_string = COALESCE(p_value_string, value_string),
        value_image = COALESCE(p_value_image, value_image),
        unit_of_measure = COALESCE(p_unit, unit_of_measure),
        sort_order = COALESCE(p_sort_order, sort_order)
    WHERE id = p_characteristic_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count > 0;
END;
$$ LANGUAGE plpgsql;

-- 8. Удалить характеристику
CREATE OR REPLACE FUNCTION delete_characteristic(p_characteristic_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM enum_characteristic WHERE id = p_characteristic_id;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count > 0;
END;
$$ LANGUAGE plpgsql;

-- 9. Получить все характеристики для всех классов
CREATE OR REPLACE FUNCTION get_all_characteristics()
RETURNS TABLE(
    id INTEGER,
    characteristic_name VARCHAR,
    class_id INTEGER,
    value_number NUMERIC,
    value_string TEXT,
    value_image VARCHAR,
    unit_of_measure VARCHAR,
    sort_order INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT ec.id, ec.characteristic_name, ec.class_id,
           ec.value_number, ec.value_string, ec.value_image,
           ec.unit_of_measure, ec.sort_order
    FROM enum_characteristic ec
    ORDER BY ec.class_id, ec.sort_order, ec.id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ЗАПОЛНЕНИЕ ДАННЫМИ
-- =====================================================

-- Классы (id из classification_element):
-- 2=STANDARD, 3=LUXE, 4=APARTMENTS, 5=STD_FULL, 6=STD_BF, 7=STD_HK, 8=STD_WIFI,
-- 9=LUXE_FULL, 10=LUXE_ALL, 11=APT_CLEAN, 12=APT_KITCHEN, 13=APT_TRANSFER, 14=APT_NONE

-- ========== STANDARD (id=2) ==========
SELECT add_number_characteristic('WiFi', 2, 0, 'Мбит/сек', 1);
SELECT add_string_characteristic('Bar', 2, 'no', NULL, 2);
SELECT add_number_characteristic('Square', 2, NULL, 'м²', 3);

-- ========== LUXE (id=3) ==========
SELECT add_number_characteristic('WiFi', 3, 0, 'Мбит/сек', 1);
SELECT add_string_characteristic('Bar', 3, 'yes', NULL, 2);
SELECT add_string_characteristic('Cleaning', 3, '1 р/день', NULL, 3);
SELECT add_number_characteristic('Square', 3, NULL, 'м²', 4);

-- ========== APARTMENTS (id=4) ==========
SELECT add_number_characteristic('WiFi', 4, 0, 'Мбит/сек', 1);
SELECT add_number_characteristic('Square', 4, NULL, 'м²', 2);

-- ========== STD_FULL (id=5) ==========
SELECT add_number_characteristic('WiFi', 5, 100, 'Мбит/сек', 1);
SELECT add_string_characteristic('Food', 5, 'Breakfast', NULL, 2);
SELECT add_string_characteristic('Bar', 5, 'no', NULL, 3);
SELECT add_string_characteristic('Cleaning', 5, '1 р/день', NULL, 4);
SELECT add_string_characteristic('Transfer', 5, 'no', NULL, 5);
SELECT add_number_characteristic('Square', 5, 25, 'м²', 6);

-- ========== STD_BF (id=6) ==========
SELECT add_number_characteristic('WiFi', 6, 100, 'Мбит/сек', 1);
SELECT add_string_characteristic('Food', 6, 'Breakfast', NULL, 2);
SELECT add_string_characteristic('Bar', 6, 'no', NULL, 3);
SELECT add_string_characteristic('Cleaning', 6, 'no', NULL, 4);
SELECT add_string_characteristic('Transfer', 6, 'no', NULL, 5);
SELECT add_number_characteristic('Square', 6, 30, 'м²', 6);

-- ========== STD_HK (id=7) ==========
SELECT add_number_characteristic('WiFi', 7, 100, 'Мбит/сек', 1);
SELECT add_string_characteristic('Food', 7, 'no', NULL, 2);
SELECT add_string_characteristic('Bar', 7, 'no', NULL, 3);
SELECT add_string_characteristic('Cleaning', 7, '1 р/день', NULL, 4);
SELECT add_string_characteristic('Transfer', 7, 'no', NULL, 5);
SELECT add_number_characteristic('Square', 7, 30, 'м²', 6);

-- ========== STD_WIFI (id=8) ==========
SELECT add_number_characteristic('WiFi', 8, 100, 'Мбит/сек', 1);
SELECT add_string_characteristic('Food', 8, 'no', NULL, 2);
SELECT add_string_characteristic('Bar', 8, 'no', NULL, 3);
SELECT add_string_characteristic('Cleaning', 8, 'no', NULL, 4);
SELECT add_string_characteristic('Transfer', 8, 'no', NULL, 5);
SELECT add_number_characteristic('Square', 8, 25, 'м²', 6);

-- ========== LUXE_FULL (id=9) ==========
SELECT add_number_characteristic('WiFi', 9, 150, 'Мбит/сек', 1);
SELECT add_string_characteristic('Food', 9, 'Breakfast', NULL, 2);
SELECT add_string_characteristic('Bar', 9, 'yes', NULL, 3);
SELECT add_string_characteristic('Cleaning', 9, '1 р/день', NULL, 4);
SELECT add_string_characteristic('Transfer', 9, 'no', NULL, 5);
SELECT add_number_characteristic('Square', 9, 40, 'м²', 6);

-- ========== LUXE_ALL (id=10) ==========
SELECT add_number_characteristic('WiFi', 10, 150, 'Мбит/сек', 1);
SELECT add_string_characteristic('Food', 10, 'All inclusive', NULL, 2);
SELECT add_string_characteristic('Bar', 10, 'yes', NULL, 3);
SELECT add_string_characteristic('Cleaning', 10, '2 р/день', NULL, 4);
SELECT add_string_characteristic('Transfer', 10, 'no', NULL, 5);
SELECT add_number_characteristic('Square', 10, 40, 'м²', 6);

-- ========== APT_CLEAN (id=11) ==========
SELECT add_number_characteristic('WiFi', 11, 150, 'Мбит/сек', 1);
SELECT add_string_characteristic('Food', 11, 'Breakfast', NULL, 2);
SELECT add_string_characteristic('Bar', 11, 'no', NULL, 3);
SELECT add_string_characteristic('Cleaning', 11, '1 р/день', NULL, 4);
SELECT add_string_characteristic('Transfer', 11, 'no', NULL, 5);
SELECT add_number_characteristic('Square', 11, 50, 'м²', 6);

-- ========== APT_KITCHEN (id=12) ==========
SELECT add_number_characteristic('WiFi', 12, 150, 'Мбит/сек', 1);
SELECT add_string_characteristic('Food', 12, 'Kitchen', NULL, 2);
SELECT add_string_characteristic('Bar', 12, 'no', NULL, 3);
SELECT add_string_characteristic('Cleaning', 12, '2 р/нед', NULL, 4);
SELECT add_string_characteristic('Transfer', 12, 'no', NULL, 5);
SELECT add_number_characteristic('Square', 12, 50, 'м²', 6);

-- ========== APT_TRANSFER (id=13) ==========
SELECT add_number_characteristic('WiFi', 13, 150, 'Мбит/сек', 1);
SELECT add_string_characteristic('Food', 13, 'Breakfast', NULL, 2);
SELECT add_string_characteristic('Bar', 13, 'no', NULL, 3);
SELECT add_string_characteristic('Cleaning', 13, 'no', NULL, 4);
SELECT add_string_characteristic('Transfer', 13, 'yes', NULL, 5);
SELECT add_number_characteristic('Square', 13, 50, 'м²', 6);

-- ========== APT_NONE (id=14) ==========
SELECT add_number_characteristic('WiFi', 14, 0, 'Мбит/сек', 1);
SELECT add_string_characteristic('Food', 14, 'no', NULL, 2);
SELECT add_string_characteristic('Bar', 14, 'no', NULL, 3);
SELECT add_string_characteristic('Cleaning', 14, 'no', NULL, 4);
SELECT add_string_characteristic('Transfer', 14, 'no', NULL, 5);
SELECT add_number_characteristic('Square', 14, 50, 'м²', 6);