-- name: DropOrderStatusTable
DROP TABLE IF EXISTS order_status CASCADE;

-- name: DropPaymentStatusHistoryTable
DROP TABLE IF EXISTS payment_status_history CASCADE;

-- name: DropPaymentTransactionTable
DROP TABLE IF EXISTS payment_transaction CASCADE;

-- name: DropBookReservationItemTable
DROP TABLE IF EXISTS book_reservation_item CASCADE;

-- name: DropBookReservationTable
DROP TABLE IF EXISTS book_reservation CASCADE;

-- name: DropOrderItemTable
DROP TABLE IF EXISTS order_item CASCADE;

-- name: DropCommentTable
DROP TABLE IF EXISTS comment CASCADE;

-- name: DropBookAuthorTable
DROP TABLE IF EXISTS book_author CASCADE;

-- name: DropOrderTable
DROP TABLE IF EXISTS "order" CASCADE;

-- name: DropBookTable
DROP TABLE IF EXISTS book CASCADE;

-- name: DropAuthorTable
DROP TABLE IF EXISTS author CASCADE;

-- name: DropPublisherTable
DROP TABLE IF EXISTS publisher CASCADE;

-- name: DropCartItemTable
DROP TABLE IF EXISTS cart_item CASCADE;

-- name: DropCustomerTable
DROP TABLE IF EXISTS customer CASCADE;

-- name: CreateCustomerTable
CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY, first_name VARCHAR(100) NOT NULL, last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL, phone VARCHAR(30), address TEXT,
    password_hash TEXT NOT NULL,
    loyalty_program BOOLEAN DEFAULT FALSE, join_date DATE NOT NULL DEFAULT CURRENT_DATE,
    loyalty_points INTEGER DEFAULT 0 CHECK (loyalty_points >= 0),
    is_admin BOOLEAN NOT NULL DEFAULT FALSE
);

-- name: CreatePublisherTable
CREATE TABLE publisher (
    publisher_id SERIAL PRIMARY KEY, name VARCHAR(255) NOT NULL UNIQUE, contact_info TEXT
);

-- name: CreateAuthorTable
CREATE TABLE author (
    author_id SERIAL PRIMARY KEY, first_name VARCHAR(100) NOT NULL, last_name VARCHAR(100) NOT NULL,
    birth_date DATE, nationality VARCHAR(100), image_path VARCHAR(512), biography TEXT
);

-- name: CreateBookTable
CREATE TABLE book (
    book_id SERIAL PRIMARY KEY, title VARCHAR(255) NOT NULL, isbn VARCHAR(20) UNIQUE,
    publication_date DATE, publisher_id INTEGER, price NUMERIC(10, 2) CHECK (price >= 0),
    stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0), description TEXT, language VARCHAR(50),
    page_count INTEGER CHECK (page_count > 0),
    cover_image_path VARCHAR(512),
    genre VARCHAR(100),
    CONSTRAINT fk_publisher FOREIGN KEY (publisher_id) REFERENCES publisher(publisher_id) ON DELETE SET NULL
);

-- name: CreateOrderTable
CREATE TABLE "order" (
    order_id SERIAL PRIMARY KEY, customer_id INTEGER,
    order_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, total_amount NUMERIC(12, 2) CHECK (total_amount >= 0),
    shipping_address TEXT NOT NULL, payment_method VARCHAR(50),
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE SET NULL
);

-- name: CreatePaymentTransactionTable
CREATE TABLE payment_transaction (
    payment_transaction_id SERIAL PRIMARY KEY,
    provider VARCHAR(32) NOT NULL,
    provider_order_id VARCHAR(128) NOT NULL UNIQUE,
    customer_id INTEGER NOT NULL,
    order_id INTEGER,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(10) NOT NULL,
    status VARCHAR(40) NOT NULL,
    checkout_url TEXT,
    request_data_base64 TEXT,
    request_signature VARCHAR(255),
    response_data_base64 TEXT,
    response_signature VARCHAR(255),
    provider_payment_id VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMPTZ,
    CONSTRAINT fk_payment_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id) REFERENCES "order"(order_id) ON DELETE SET NULL
);

-- name: CreateBookReservationTable
CREATE TABLE book_reservation (
    reservation_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    provider_order_id VARCHAR(128) NOT NULL UNIQUE,
    order_id INTEGER,
    status VARCHAR(32) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_book_reservation_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_book_reservation_order FOREIGN KEY (order_id) REFERENCES "order"(order_id) ON DELETE SET NULL
);

-- name: CreateBookReservationItemTable
CREATE TABLE book_reservation_item (
    reservation_item_id SERIAL PRIMARY KEY,
    reservation_id INTEGER NOT NULL,
    book_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    CONSTRAINT fk_book_reservation_item_reservation FOREIGN KEY (reservation_id) REFERENCES book_reservation(reservation_id) ON DELETE CASCADE,
    CONSTRAINT fk_book_reservation_item_book FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE RESTRICT,
    CONSTRAINT uq_book_reservation_item UNIQUE (reservation_id, book_id)
);

-- name: CreateBookAuthorTable
CREATE TABLE book_author (
    book_id INTEGER NOT NULL, author_id INTEGER NOT NULL, role VARCHAR(100),
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_book FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_author FOREIGN KEY (author_id) REFERENCES author(author_id) ON DELETE CASCADE
);

-- name: CreateOrderItemTable
CREATE TABLE order_item (
    order_item_id SERIAL PRIMARY KEY, order_id INTEGER NOT NULL, book_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0), price_per_unit NUMERIC(10, 2) NOT NULL CHECK (price_per_unit >= 0),
    CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES "order"(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_book FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE RESTRICT
);

-- name: CreateOrderStatusTable
CREATE TABLE order_status (
    order_status_id SERIAL PRIMARY KEY, order_id INTEGER NOT NULL, status VARCHAR(50) NOT NULL,
    status_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP, tracking_number VARCHAR(100),
    CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES "order"(order_id) ON DELETE CASCADE
);

-- name: CreatePaymentStatusHistoryTable
CREATE TABLE payment_status_history (
    payment_status_history_id SERIAL PRIMARY KEY,
    payment_transaction_id INTEGER NOT NULL,
    status VARCHAR(40) NOT NULL,
    status_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details TEXT,
    CONSTRAINT fk_payment_transaction FOREIGN KEY (payment_transaction_id) REFERENCES payment_transaction(payment_transaction_id) ON DELETE CASCADE
);

-- name: CreateCommentTable
CREATE TABLE comment (
    comment_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    comment_text TEXT NOT NULL,
    comment_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rating INTEGER CHECK (rating >= 0 AND rating <= 5),
    CONSTRAINT fk_book_comment FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_customer_comment FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE
);

-- name: CreateCartItemTable
CREATE TABLE cart_item (
    customer_id INTEGER NOT NULL,
    book_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    added_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, book_id),
    CONSTRAINT fk_customer_cart FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_book_cart FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE CASCADE
);

-- name: CreateIndexOrderCustomerDate
CREATE INDEX idx_order_customer_date ON "order" (customer_id, order_date DESC);

-- name: CreateIndexOrderStatusOrderDate
CREATE INDEX idx_order_status_order_date ON order_status (order_id, status_date DESC);

-- name: CreateIndexOrderItemOrder
CREATE INDEX idx_order_item_order ON order_item (order_id);

-- name: CreateIndexCommentBookDate
CREATE INDEX idx_comment_book_date ON comment (book_id, comment_date DESC);

-- name: CreateIndexBookGenreLanguage
CREATE INDEX idx_book_genre_language ON book (genre, language);

-- name: CreateIndexBookTitleLower
CREATE INDEX idx_book_title_lower ON book (LOWER(title));

-- name: CreateIndexAuthorFullNameLower
CREATE INDEX idx_author_full_name_lower ON author (LOWER(first_name || ' ' || last_name));

-- name: CreateIndexPaymentTransactionProviderOrder
CREATE INDEX idx_payment_transaction_provider_order ON payment_transaction (provider_order_id);

-- name: CreateIndexPaymentStatusHistoryTransactionDate
CREATE INDEX idx_payment_status_history_tx_date ON payment_status_history (payment_transaction_id, status_date DESC);

-- name: CreateIndexBookReservationProviderOrder
CREATE INDEX idx_book_reservation_provider_order ON book_reservation (provider_order_id);

-- name: CreateIndexBookReservationStatusExpires
CREATE INDEX idx_book_reservation_status_expires ON book_reservation (status, expires_at);

-- name: CreateIndexBookReservationItemBook
CREATE INDEX idx_book_reservation_item_book ON book_reservation_item (book_id);
