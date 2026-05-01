-- 004_seed_data.up.sql

-- Корень: Номера отеля
INSERT INTO classification_element (class_code, name, is_terminal, sort_order, parent_id) VALUES
('ROOMS', 'Номера отеля', false, 0, NULL);

-- Категории
INSERT INTO classification_element (class_code, name, is_terminal, sort_order, parent_id) VALUES
('STANDARD', 'Стандарт (до 2 человек)', false, 1, 1),
('LUXE', 'Люкс (до 2 человек)', false, 2, 1),
('APARTMENTS', 'Апартаменты (до 6 человек)', false, 3, 1);

-- Терминальные узлы — Стандарт
INSERT INTO classification_element (class_code, name, is_terminal, sort_order, unit_of_measure, parent_id) VALUES
('STD_FULL', 'WiFi + Завтрак + Горничная', true, 1, 'ночь', 2),
('STD_BF', 'WiFi + Завтрак', true, 2, 'ночь', 2),
('STD_HK', 'WiFi + Горничная', true, 3, 'ночь', 2),
('STD_WIFI', 'Только WiFi', true, 4, 'ночь', 2);

-- Терминальные узлы — Люкс
INSERT INTO classification_element (class_code, name, is_terminal, sort_order, unit_of_measure, parent_id) VALUES
('LUXE_FULL', 'Минибар + WiFi + Завтрак + Горничная', true, 1, 'ночь', 3),
('LUXE_ALL', 'Минибар + WiFi + Всё включено + Горничная', true, 2, 'ночь', 3);

-- Терминальные узлы — Апартаменты
INSERT INTO classification_element (class_code, name, is_terminal, sort_order, unit_of_measure, parent_id) VALUES
('APT_CLEAN', 'WiFi + Завтрак + Полная уборка', true, 1, 'ночь', 4),
('APT_KITCHEN', 'WiFi + Кухня + Горничная 2р/нед', true, 2, 'ночь', 4),
('APT_TRANSFER', 'WiFi + Трансфер + Завтрак', true, 3, 'ночь', 4),
('APT_NONE', 'Без услуг', true, 4, 'ночь', 4);

-- Продукты — конкретные номера
INSERT INTO product (name, short_name, class_id) VALUES
('Комната 101', '101', 5),
('Комната 102', '102', 6),
('Комната 201', '201', 8),
('Комната 301', '301', 11),
('Комната 302', '302', 12);
