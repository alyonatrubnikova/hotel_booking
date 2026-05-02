-- 008_complete_spravochnik.up.sql
-- Добавление ограничений, агрегатов и переопределения параметров

-- =============================================
-- 1. ОГРАНИЧЕНИЯ ДЛЯ ЧИСЛЕННЫХ ПАРАМЕТРОВ (min/max)
-- =============================================

ALTER TABLE enum_characteristic 
ADD COLUMN IF NOT EXISTS min_value NUMERIC,
ADD COLUMN IF NOT EXISTS max_value NUMERIC;

-- Функция проверки ограничений
CREATE OR REPLACE FUNCTION check_numeric_range()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем только если значение числовое
    IF NEW.value_number IS NOT NULL THEN
        -- Проверка минимума
        IF NEW.min_value IS NOT NULL AND NEW.value_number < NEW.min_value THEN
            RAISE EXCEPTION 'Value % is less than minimum allowed %', NEW.value_number, NEW.min_value;
        END IF;
        -- Проверка максимума
        IF NEW.max_value IS NOT NULL AND NEW.value_number > NEW.max_value THEN
            RAISE EXCEPTION 'Value % is greater than maximum allowed %', NEW.value_number, NEW.max_value;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер проверки
DROP TRIGGER IF EXISTS check_numeric_range_trigger ON enum_characteristic;
CREATE TRIGGER check_numeric_range_trigger
    BEFORE INSERT OR UPDATE OF value_number ON enum_characteristic
    FOR EACH ROW
    EXECUTE FUNCTION check_numeric_range();

-- =============================================
-- 2. АГРЕГАТЫ ПАРАМЕТРОВ (группировка)
-- =============================================

-- Таблица агрегатов
CREATE TABLE IF NOT EXISTS parameter_aggregate (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Связь агрегата с параметрами (многие ко многим)
CREATE TABLE IF NOT EXISTS aggregate_characteristic (
    aggregate_id INTEGER NOT NULL REFERENCES parameter_aggregate(id) ON DELETE CASCADE,
    characteristic_id INTEGER NOT NULL REFERENCES enum_characteristic(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (aggregate_id, characteristic_id)
);

CREATE INDEX IF NOT EXISTS idx_aggregate_char_agg ON aggregate_characteristic(aggregate_id);
CREATE INDEX IF NOT EXISTS idx_aggregate_char_char ON aggregate_characteristic(characteristic_id);

-- Функция: получить все агрегаты
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

-- Функция: получить агрегат по ID
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

-- Функция: добавить параметр в агрегат
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

-- Функция: удалить параметр из агрегата
CREATE OR REPLACE FUNCTION remove_characteristic_from_aggregate(
    p_aggregate_id INTEGER,
    p_characteristic_id INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM aggregate_characteristic 
    WHERE aggregate_id = p_aggregate_id AND characteristic_id = p_characteristic_id;
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 3. ПЕРЕОПРЕДЕЛЕНИЕ ПАРАМЕТРОВ ДЛЯ ПОДКЛАССА
-- =============================================

-- Таблица для переопределения параметров на уровне подкласса
-- (позволяет подклассу иметь свой набор параметров, отличный от родителя)
CREATE TABLE IF NOT EXISTS class_parameter_override (
    id SERIAL PRIMARY KEY,
    class_id INTEGER NOT NULL REFERENCES classification_element(id) ON DELETE CASCADE,
    characteristic_id INTEGER NOT NULL REFERENCES enum_characteristic(id) ON DELETE CASCADE,
    is_inherited BOOLEAN DEFAULT TRUE,      -- TRUE = наследуется от родителя, FALSE = переопределён
    sort_order INTEGER DEFAULT 0,            -- Порядок сортировки для этого подкласса
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(class_id, characteristic_id)
);

CREATE INDEX IF NOT EXISTS idx_class_param_override_class ON class_parameter_override(class_id);

-- Функция: получить все параметры для класса (с учётом переопределений)
CREATE OR REPLACE FUNCTION get_class_parameters_with_overrides(p_class_id INTEGER)
RETURNS TABLE (
    characteristic_id INTEGER,
    characteristic_name VARCHAR,
    value_number NUMERIC,
    value_string TEXT,
    unit_of_measure VARCHAR,
    min_value NUMERIC,
    max_value NUMERIC,
    is_inherited_from_parent BOOLEAN,
    is_overridden BOOLEAN,
    sort_order INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE class_parents AS (
        SELECT id, parent_id, 0 AS level
        FROM classification_element
        WHERE id = p_class_id
        
        UNION ALL
        
        SELECT ce.id, ce.parent_id, cp.level + 1
        FROM classification_element ce
        JOIN class_parents cp ON cp.parent_id = ce.id
    )
    SELECT DISTINCT ON (ec.id)
        ec.id,
        ec.characteristic_name,
        ec.value_number,
        ec.value_string,
        ec.unit_of_measure,
        ec.min_value,
        ec.max_value,
        (cp.level > 0) AS is_inherited_from_parent,
        (cpo.id IS NOT NULL) AS is_overridden,
        COALESCE(cpo.sort_order, ec.sort_order, cp.level * 100) AS sort_order
    FROM class_parents cp
    JOIN enum_characteristic ec ON ec.class_id = cp.id
    LEFT JOIN class_parameter_override cpo ON cpo.class_id = p_class_id AND cpo.characteristic_id = ec.id
    WHERE cpo.is_inherited = TRUE OR cpo.id IS NULL
    ORDER BY ec.id, cp.level ASC;
END;
$$ LANGUAGE plpgsql;

-- Функция: переопределить параметр для подкласса
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
-- 4. ТЕСТОВЫЕ ДАННЫЕ (для демонстрации)
-- =============================================

-- Добавляем ограничения для существующих параметров
UPDATE enum_characteristic SET min_value = 0, max_value = 1000 WHERE characteristic_name = 'WiFi' AND value_number IS NOT NULL;
UPDATE enum_characteristic SET min_value = 1, max_value = 200 WHERE characteristic_name = 'Square';

-- Создаём пример агрегата "Основные параметры номера"
INSERT INTO parameter_aggregate (name, description) 
VALUES ('Основные параметры', 'Базовые характеристики номера')
ON CONFLICT (name) DO NOTHING;

-- Добавляем параметры в агрегат (если их ID существуют)
DO $$
DECLARE
    agg_id INTEGER;
    wifi_id INTEGER;
    square_id INTEGER;
    cleaning_id INTEGER;
BEGIN
    SELECT id INTO agg_id FROM parameter_aggregate WHERE name = 'Основные параметры';
    SELECT id INTO wifi_id FROM enum_characteristic WHERE characteristic_name = 'WiFi' LIMIT 1;
    SELECT id INTO square_id FROM enum_characteristic WHERE characteristic_name = 'Square' LIMIT 1;
    SELECT id INTO cleaning_id FROM enum_characteristic WHERE characteristic_name = 'Cleaning' LIMIT 1;
    
    IF agg_id IS NOT NULL AND wifi_id IS NOT NULL THEN
        PERFORM add_characteristic_to_aggregate(agg_id, wifi_id, 1);
    END IF;
    
    IF agg_id IS NOT NULL AND square_id IS NOT NULL THEN
        PERFORM add_characteristic_to_aggregate(agg_id, square_id, 2);
    END IF;
    
    IF agg_id IS NOT NULL AND cleaning_id IS NOT NULL THEN
        PERFORM add_characteristic_to_aggregate(agg_id, cleaning_id, 3);
    END IF;
END $$;