-- 001_create_tables.up.sql

CREATE TABLE IF NOT EXISTS classification_element (
    id SERIAL PRIMARY KEY,
    class_code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(256) NOT NULL,
    is_terminal BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    unit_of_measure VARCHAR(64),
    parent_id INTEGER REFERENCES classification_element(id) ON DELETE SET NULL
);

CREATE INDEX idx_parent_id ON classification_element(parent_id);
CREATE INDEX idx_class_code ON classification_element(class_code);
CREATE INDEX idx_is_terminal ON classification_element(is_terminal);
