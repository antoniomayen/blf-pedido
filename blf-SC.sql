-- Script de creación de base de datos BLF Master
DROP DATABASE IF EXISTS blfmaster;

CREATE DATABASE blfmaster CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE blfmaster;

-- Tabla MASTER (sin cambios)
CREATE TABLE master_products (
    master_code VARCHAR(50) PRIMARY KEY,
    product_no VARCHAR(50) NOT NULL,
    color VARCHAR(50) NOT NULL,
    group_code VARCHAR(50),
    product_name VARCHAR(100),
    blf_code VARCHAR(50),
    product_sort_number INTEGER,
    color_sort_number INTEGER,
    total_sort_number INTEGER,
    pos_code INTEGER,
    smartregister_code INTEGER,
    product_name_jp VARCHAR(100),
    price_without_tax DECIMAL(10),
    price_with_tax DECIMAL(10),
    cost_price DECIMAL(10),
    cost_price_alt DECIMAL(10),
    old_special_code VARCHAR(50),
    new_special_code VARCHAR(50),
    special_product_name VARCHAR(100),
    rakuten_code VARCHAR(50),
    amazon_child_asin VARCHAR(50),
    shipping_cost DECIMAL(10),
    total_cost DECIMAL(10),
    inventory_amount DECIMAL(10),
    has_order BOOLEAN,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT unique_product_color UNIQUE (product_no, color)
);

-- Índices (sin cambios)
CREATE INDEX idx_product_no ON master_products(product_no);
CREATE INDEX idx_rakuten_code ON master_products(rakuten_code);
CREATE INDEX idx_amazon_asin ON master_products(amazon_child_asin);
CREATE INDEX idx_group_code ON master_products(group_code);
CREATE INDEX idx_product_color ON master_products(product_no, color);

-- Tabla SC (con timestamps)
CREATE TABLE sales_contracts (
    sc_id VARCHAR(50) PRIMARY KEY,
    creation_date DATE NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    estimate_arrival_date DATE,
    status VARCHAR(50),
    order_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla SC_DETAILS (con cambios a DECIMAL)
CREATE TABLE sales_contract_details (
    id SERIAL,
    sc_id VARCHAR(50),
    master_code VARCHAR(50),
    initial_stock INTEGER,
    expected_sales DECIMAL(10, 2),
    expected_loss DECIMAL(10, 2),          -- Cambiado de VARCHAR a DECIMAL
    additional_order DECIMAL(10, 2),
    minimum_dp_quantity DECIMAL(10, 2),
    bs_3month DECIMAL(10, 2),              -- Cambiado de VARCHAR a DECIMAL
    minimum_quantity DECIMAL(10, 2),        -- Cambiado de VARCHAR a DECIMAL
    average_per_month DECIMAL(10, 2),
    stock_minus_minimum DECIMAL(10, 2),
    order_quantity DECIMAL(10, 2),
    initial_plus_order DECIMAL(10, 2),      -- Cambiado de VARCHAR a DECIMAL
    initial_minus_minimum DECIMAL(10, 2),
    ordered_amount DECIMAL(10, 2),
    received_amount DECIMAL(10, 2),
    difference DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (sc_id) REFERENCES sales_contracts(sc_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (master_code) REFERENCES master_products(master_code) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Índices (sin cambios)
CREATE INDEX idx_sc_id ON sales_contract_details(sc_id);
CREATE INDEX idx_scd_master_code ON sales_contract_details(master_code);

-- Tabla STOCK (con timestamps)
CREATE TABLE stock (
    stock_id VARCHAR(50) PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla STOCK_DETAILS (con timestamps)
CREATE TABLE stock_details (
    id SERIAL,
    stock_id VARCHAR(50),
    location_id INTEGER,
    master_code VARCHAR(50),
    quantity INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (stock_id) REFERENCES stock(stock_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (master_code) REFERENCES master_products(master_code) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Índices (sin cambios)
CREATE INDEX idx_stock_id ON stock_details(stock_id);
CREATE INDEX idx_sd_master_code ON stock_details(master_code);
CREATE INDEX idx_location ON stock_details(location_id);

-- Tabla LOCATIONS (con timestamps)
CREATE TABLE locations (
    location_id INTEGER PRIMARY KEY,
    smaregi_store_id INTEGER,
    store_name VARCHAR(100),
    category VARCHAR(50),
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE(smaregi_store_id)
);

-- Tabla DISPLAY (con timestamps)
CREATE TABLE display (
    id SERIAL,
    master_code VARCHAR(50),
    location_id INTEGER,
    quantity INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (master_code) REFERENCES master_products(master_code) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (location_id) REFERENCES locations(location_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE (master_code, location_id)
);

-- Índices (sin cambios)
CREATE INDEX idx_display_master ON display(master_code);
CREATE INDEX idx_display_location ON display(location_id);

-- Tabla MONTHLY_SALES (con timestamps)
CREATE TABLE monthly_sales (
    monthly_sales_id VARCHAR(50) PRIMARY KEY,
    sale_date DATE NOT NULL,
    location_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (location_id) REFERENCES locations(location_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla MONTHLY_SALES_DETAILS (con timestamps)
CREATE TABLE monthly_sales_details (
    id SERIAL,
    monthly_sales_id VARCHAR(50),
    master_code VARCHAR(50),
    quantity INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (monthly_sales_id) REFERENCES monthly_sales(monthly_sales_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (master_code) REFERENCES master_products(master_code) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Índices (sin cambios)
CREATE INDEX idx_monthly_sales_date ON monthly_sales(sale_date);
CREATE INDEX idx_monthly_sales_location ON monthly_sales(location_id);
CREATE INDEX idx_monthly_sales_details_master ON monthly_sales_details(master_code);
CREATE INDEX idx_monthly_sales_details_header ON monthly_sales_details(monthly_sales_id);