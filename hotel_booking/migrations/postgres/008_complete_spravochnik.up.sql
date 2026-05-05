-- 008_complete_spravochnik.up.sql
-- Агрегаты, ограничения и переопределения параметров

-- =============================================
-- 1. ДОБАВЛЯЕМ КОЛОНКИ min/max В enum_characteristic
-- =============================================

ALTER TABLE enum_characteristic 
ADD COLUMN IF NOT EXISTS min_value NUMERIC,
ADD COLUMN IF NOT EXISTS max_value NUMERIC;

-- Устанавливаем ограничения для WiFi
UPDATE enum_characteristic SET min_value = 0, max_value = 1000 
WHERE characteristic_name = 'WiFi';

-- Устанавливаем ограничения для Square
UPDATE enum_characteristic SET min_value = 1, max_value = 200 
WHERE characteristic_name = 'Square';

-- =============================================
-- 2. ТАБЛИЦА АГРЕГАТОВ
-- =============================================

CREATE TABLE IF NOT EXISTS parameter_aggregate (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 3. ТАБЛИЦА СВЯЗИ АГРЕГАТОВ С ПАРАМЕТРАМИ
-- =============================================

CREATE TABLE IF NOT EXISTS aggregate_characteristic (
    aggregate_id INTEGER NOT NULL REFERENCES parameter_aggregate(id) ON DELETE CASCADE,
    characteristic_id INTEGER NOT NULL REFERENCES enum_characteristic(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (aggregate_id, characteristic_id)
);

CREATE INDEX IF NOT EXISTS idx_aggregate_char_agg ON aggregate_characteristic(aggregate_id);
CREATE INDEX IF NOT EXISTS idx_aggregate_char_char ON aggregate_characteristic(characteristic_id);

-- =============================================
-- 4. ТАБЛИЦА ПЕРЕОПРЕДЕЛЕНИЯ ПАРАМЕТРОВ
-- =============================================

CREATE TABLE IF NOT EXISTS class_parameter_override (
    id SERIAL PRIMARY KEY,
    class_id INTEGER NOT NULL REFERENCES classification_element(id) ON DELETE CASCADE,
    characteristic_id INTEGER NOT NULL REFERENCES enum_characteristic(id) ON DELETE CASCADE,
    is_inherited BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(class_id, characteristic_id)
);

CREATE INDEX IF NOT EXISTS idx_class_param_override_class ON class_parameter_override(class_id);

-- =============================================
-- 5. УДАЛЯЕМ СТАРЫЕ ДАННЫЕ
-- =============================================

DELETE FROM aggregate_characteristic;
DELETE FROM parameter_aggregate;
DELETE FROM class_parameter_override;

-- =============================================
-- 6. ТЕСТОВЫЕ ДАННЫЕ - АГРЕГАТЫ
-- =============================================

-- Агрегат 1: Основные параметры (WiFi + Square)
INSERT INTO parameter_aggregate (name, description) 
VALUES ('Основные параметры', 'Интернет и площадь номера');

-- Агрегат 2: Питание (Food + Bar)
INSERT INTO parameter_aggregate (name, description) 
VALUES ('Питание', 'Еда и напитки');

-- Агрегат 3: Услуги (Cleaning + Transfer)
INSERT INTO parameter_aggregate (name, description) 
VALUES ('Услуги', 'Горничная и трансфер');

-- =============================================
-- 7. ТЕСТОВЫЕ ДАННЫЕ - СВЯЗИ АГРЕГАТОВ
-- =============================================

-- Основные параметры: WiFi (id=10) и Square (id=15) для класса STD_FULL
INSERT INTO aggregate_characteristic (aggregate_id, characteristic_id, sort_order) VALUES
((SELECT id FROM parameter_aggregate WHERE name = 'Основные параметры'), 10, 1),
((SELECT id FROM parameter_aggregate WHERE name = 'Основные параметры'), 15, 2);

-- Питание: Food (id=11) и Bar (id=12)
INSERT INTO aggregate_characteristic (aggregate_id, characteristic_id, sort_order) VALUES
((SELECT id FROM parameter_aggregate WHERE name = 'Питание'), 11, 1),
((SELECT id FROM parameter_aggregate WHERE name = 'Питание'), 12, 2);

-- Услуги: Cleaning (id=13) и Transfer (id=14)
INSERT INTO aggregate_characteristic (aggregate_id, characteristic_id, sort_order) VALUES
((SELECT id FROM parameter_aggregate WHERE name = 'Услуги'), 13, 1),
((SELECT id FROM parameter_aggregate WHERE name = 'Услуги'), 14, 2);

-- =============================================
-- 8. ТЕСТОВЫЕ ДАННЫЕ - ПЕРЕОПРЕДЕЛЕНИЯ ДЛЯ ПОДКЛАССОВ
-- =============================================

-- STD_WIFI (id=8): не наследует Cleaning (id=13) и Food (id=11)
INSERT INTO class_parameter_override (class_id, characteristic_id, is_inherited, sort_order) VALUES
(8, 13, false, 1),
(8, 11, false, 2);

-- STD_HK (id=7): не наследует Food (id=11)
INSERT INTO class_parameter_override (class_id, characteristic_id, is_inherited, sort_order) VALUES
(7, 11, false, 3);

-- APT_NONE (id=14): не наследует Cleaning, Food, Bar, Transfer
INSERT INTO class_parameter_override (class_id, characteristic_id, is_inherited, sort_order) VALUES
(14, 13, false, 4),
(14, 11, false, 5),
(14, 12, false, 6),
(14, 14, false, 7);

-- =============================================
-- 9. ФУНКЦИИ ДЛЯ РАБОТЫ С АГРЕГАТАМИ
-- =============================================

CREATE OR REPLACE FUNCTION get_all_aggregates()
RETURNS TABLE (
    aggregate_id INTEGER,
    aggregate_name VARCHAR,
    description TEXT,
    characteristics JSON
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pa.id,
        pa.name,
        pa.description,
        COALESCE(
            (SELECT json_agg(json_build_object(
                'characteristic_id', ec.id,
                'characteristic_name', ec.characteristic_name,
                'sort_order', ac.sort_order
            ) ORDER BY ac.sort_order)
             FROM aggregate_characteristic ac
             JOIN enum_characteristic ec ON ec.id = ac.characteristic_id
             WHERE ac.aggregate_id = pa.id),
            '[]'::json
        ) as characteristics
    FROM parameter_aggregate pa
    ORDER BY pa.id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_aggregate_by_id(p_aggregate_id INTEGER)
RETURNS TABLE (
    aggregate_id INTEGER,
    aggregate_name VARCHAR,
    description TEXT,
    characteristics JSON
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pa.id,
        pa.name,
        pa.description,
        COALESCE(
            (SELECT json_agg(json_build_object(
                'characteristic_id', ec.id,
                'characteristic_name', ec.characteristic_name,
                'sort_order', ac.sort_order
            ) ORDER BY ac.sort_order)
             FROM aggregate_characteristic ac
             JOIN enum_characteristic ec ON ec.id = ac.characteristic_id
             WHERE ac.aggregate_id = pa.id),
            '[]'::json
        ) as characteristics
    FROM parameter_aggregate pa
    WHERE pa.id = p_aggregate_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_characteristic_to_aggregate(
    p_aggregate_id INTEGER,
    p_characteristic_id INTEGER,
    p_sort_order INTEGER DEFAULT 0
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO aggregate_characteristic (aggregate_id, characteristic_id, sort_order)
    VALUES (p_aggregate_id, p_characteristic_id, p_sort_order)
    ON CONFLICT (aggregate_id, characteristic_id) DO NOTHING;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION override_class_parameter(
    p_class_id INTEGER,
    p_characteristic_id INTEGER,
    p_is_inherited BOOLEAN DEFAULT FALSE,
    p_sort_order INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO class_parameter_override (class_id, characteristic_id, is_inherited, sort_order)
    VALUES (p_class_id, p_characteristic_id, p_is_inherited, p_sort_order)
    ON CONFLICT (class_id, characteristic_id) 
    DO UPDATE SET 
        is_inherited = EXCLUDED.is_inherited,
        sort_order = COALESCE(EXCLUDED.sort_order, class_parameter_override.sort_order);
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 10. ПРОВЕРКА
-- =============================================

SELECT 'Все таблицы созданы и заполнены!' AS status;