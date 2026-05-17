-- 008_complete_spravochnik.up.sql

-- =============================================
-- 1. ДОБАВЛЯЕМ КОЛОНКИ min/max
-- =============================================

ALTER TABLE enum_characteristic 
ADD COLUMN IF NOT EXISTS min_value NUMERIC,
ADD COLUMN IF NOT EXISTS max_value NUMERIC;

-- =============================================
-- 2. УСТАНАВЛИВАЕМ ОГРАНИЧЕНИЯ
-- =============================================

UPDATE enum_characteristic SET min_value = 0, max_value = 1000 WHERE characteristic_name = 'WiFi';
UPDATE enum_characteristic SET min_value = 1, max_value = 200 WHERE characteristic_name = 'Square';

-- =============================================
-- 3. ДОБАВЛЯЕМ ЦЕНУ (только если её ещё нет)
-- =============================================

INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order, min_value, max_value)
SELECT 'Price', 5, 5000, 'руб/ночь', 10, 1000, 50000
WHERE NOT EXISTS (SELECT 1 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 5);

INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order, min_value, max_value)
SELECT 'Price', 6, 4500, 'руб/ночь', 10, 1000, 50000
WHERE NOT EXISTS (SELECT 1 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 6);

INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order, min_value, max_value)
SELECT 'Price', 7, 4000, 'руб/ночь', 10, 1000, 50000
WHERE NOT EXISTS (SELECT 1 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 7);

INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order, min_value, max_value)
SELECT 'Price', 8, 3500, 'руб/ночь', 10, 1000, 50000
WHERE NOT EXISTS (SELECT 1 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 8);

INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order, min_value, max_value)
SELECT 'Price', 9, 8000, 'руб/ночь', 10, 1000, 50000
WHERE NOT EXISTS (SELECT 1 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 9);

INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order, min_value, max_value)
SELECT 'Price', 10, 10000, 'руб/ночь', 10, 1000, 50000
WHERE NOT EXISTS (SELECT 1 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 10);

INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order, min_value, max_value)
SELECT 'Price', 11, 6000, 'руб/ночь', 10, 1000, 50000
WHERE NOT EXISTS (SELECT 1 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 11);

INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order, min_value, max_value)
SELECT 'Price', 12, 6500, 'руб/ночь', 10, 1000, 50000
WHERE NOT EXISTS (SELECT 1 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 12);

INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order, min_value, max_value)
SELECT 'Price', 13, 7000, 'руб/ночь', 10, 1000, 50000
WHERE NOT EXISTS (SELECT 1 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 13);

INSERT INTO enum_characteristic (characteristic_name, class_id, value_number, unit_of_measure, sort_order, min_value, max_value)
SELECT 'Price', 14, 3000, 'руб/ночь', 10, 1000, 50000
WHERE NOT EXISTS (SELECT 1 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 14);

-- =============================================
-- 4. ТРИГГЕРЫ ЗАЩИТЫ
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
INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 1, id, 5500 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 5
ON CONFLICT (product_id, characteristic_id) DO UPDATE SET value_number = EXCLUDED.value_number;

INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 2, id, 4800 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 6
ON CONFLICT (product_id, characteristic_id) DO UPDATE SET value_number = EXCLUDED.value_number;

INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 3, id, 3800 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 8
ON CONFLICT (product_id, characteristic_id) DO UPDATE SET value_number = EXCLUDED.value_number;

INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 4, id, 6500 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 11
ON CONFLICT (product_id, characteristic_id) DO UPDATE SET value_number = EXCLUDED.value_number;

INSERT INTO product_parameter_value (product_id, characteristic_id, value_number)
SELECT 5, id, 7000 FROM enum_characteristic WHERE characteristic_name = 'Price' AND class_id = 12
ON CONFLICT (product_id, characteristic_id) DO UPDATE SET value_number = EXCLUDED.value_number;