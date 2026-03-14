-- name: GetAllBooksForDisplay
SELECT
    b.book_id,
    b.title,
    b.price,
    b.cover_image_path,
    b.stock_quantity,
    b.genre,
    COALESCE(p.name, 'Невідомий видавець') AS publisher_name,
    STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', ') AS authors
FROM book b
LEFT JOIN publisher p ON b.publisher_id = p.publisher_id
LEFT JOIN book_author ba ON b.book_id = ba.book_id
LEFT JOIN author a ON ba.author_id = a.author_id
GROUP BY b.book_id, b.title, b.price, b.cover_image_path, b.stock_quantity, b.genre, p.name
ORDER BY b.title
LIMIT :limit;

-- name: GetFilteredBooksForDisplayBase
SELECT
    b.book_id,
    b.title,
    b.price,
    b.cover_image_path,
    b.stock_quantity,
    b.genre,
    b.language,
    COALESCE(p.name, 'Невідомий видавець') AS publisher_name,
    STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', ') AS authors
FROM book b
LEFT JOIN publisher p ON b.publisher_id = p.publisher_id
LEFT JOIN book_author ba ON b.book_id = ba.book_id
LEFT JOIN author a ON ba.author_id = a.author_id

-- name: GetAllDistinctGenres
SELECT DISTINCT genre FROM book WHERE genre IS NOT NULL AND genre != '' ORDER BY genre;

-- name: SearchBooksForDisplay
SELECT
    b.book_id,
    b.title,
    b.price,
    b.cover_image_path,
    b.stock_quantity,
    b.genre,
    COALESCE(p.name, 'Unknown publisher') AS publisher_name,
    STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', ') AS authors
FROM book b
LEFT JOIN publisher p ON b.publisher_id = p.publisher_id
LEFT JOIN book_author ba ON b.book_id = ba.book_id
LEFT JOIN author a ON ba.author_id = a.author_id
GROUP BY b.book_id, b.title, b.price, b.cover_image_path, b.stock_quantity, b.genre, b.language, p.name
HAVING
    LOWER(b.title) LIKE '%' || LOWER(:query) || '%'
    OR LOWER(COALESCE(b.genre, '')) LIKE '%' || LOWER(:query) || '%'
    OR LOWER(COALESCE(b.language, '')) LIKE '%' || LOWER(:query) || '%'
    OR BOOL_OR(LOWER(COALESCE(a.first_name || ' ' || a.last_name, '')) LIKE '%' || LOWER(:query) || '%')
ORDER BY b.title
LIMIT :limit;

-- name: GetAllDistinctLanguages
SELECT DISTINCT language FROM book WHERE language IS NOT NULL AND language != '' ORDER BY language;

-- name: GetBookDetailsById
SELECT
    b.book_id, b.title, b.price, b.cover_image_path, b.stock_quantity,
    b.genre, b.description, b.publication_date, b.isbn, b.page_count, b.language,
    COALESCE(p.name, 'Невідомий видавець') AS publisher_name,
    STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', ') AS authors
FROM book b
LEFT JOIN publisher p ON b.publisher_id = p.publisher_id
LEFT JOIN book_author ba ON b.book_id = ba.book_id
LEFT JOIN author a ON ba.author_id = a.author_id
WHERE b.book_id = :bookId
GROUP BY b.book_id, p.name, b.title, b.price, b.cover_image_path, b.stock_quantity, b.genre, b.description, b.publication_date, b.isbn, b.page_count, b.language
LIMIT 1;

-- name: GetBookDisplayInfoById
SELECT
    b.book_id,
    b.title,
    b.price,
    b.cover_image_path,
    b.stock_quantity,
    b.genre,
    STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', ') AS authors
FROM book b
LEFT JOIN book_author ba ON b.book_id = ba.book_id
LEFT JOIN author a ON ba.author_id = a.author_id
WHERE b.book_id = :bookId
GROUP BY b.book_id, b.title, b.price, b.cover_image_path, b.stock_quantity, b.genre
LIMIT 1;

-- name: GetBooksByGenre
SELECT
    b.book_id,
    b.title,
    b.price,
    b.cover_image_path,
    b.stock_quantity,
    b.genre,
    COALESCE(p.name, 'Невідомий видавець') AS publisher_name,
    STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', ') AS authors
FROM book b
LEFT JOIN publisher p ON b.publisher_id = p.publisher_id
LEFT JOIN book_author ba ON b.book_id = ba.book_id
LEFT JOIN author a ON ba.author_id = a.author_id
WHERE b.genre = :genre
GROUP BY b.book_id, b.title, b.price, b.cover_image_path, b.stock_quantity, b.genre, p.name
ORDER BY b.publication_date DESC, b.title
LIMIT :limit;

-- name: GetSearchSuggestions
SELECT 'book' AS type, book_id AS id, title AS display_text, cover_image_path AS image_path, price
FROM book
WHERE LOWER(title) LIKE '%' || LOWER(:prefix) || '%'
UNION ALL
SELECT 'author' AS type, author_id AS id, first_name || ' ' || last_name AS display_text, image_path, 0.0 AS price
FROM author
WHERE LOWER(first_name || ' ' || last_name) LIKE '%' || LOWER(:prefix) || '%'
ORDER BY display_text
LIMIT :total_limit;

-- name: GetSimilarBooksByGenre
SELECT
    b.book_id,
    b.title,
    b.price,
    b.cover_image_path,
    b.stock_quantity,
    b.genre,
    STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', ') AS authors
FROM book b
LEFT JOIN book_author ba ON b.book_id = ba.book_id
LEFT JOIN author a ON ba.author_id = a.author_id
WHERE b.genre = :genre AND b.book_id != :currentBookId
GROUP BY b.book_id, b.title, b.price, b.cover_image_path, b.stock_quantity, b.genre
ORDER BY RANDOM()
LIMIT :limit;

-- name: GetAllBooksForAdmin
SELECT
    b.book_id,
    b.title,
    b.price,
    b.stock_quantity,
    b.genre,
    b.language,
    b.description,
    b.cover_image_path,
    b.publication_date,
    STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', ') AS authors
FROM book b
LEFT JOIN book_author ba ON b.book_id = ba.book_id
LEFT JOIN author a ON ba.author_id = a.author_id
GROUP BY b.book_id, b.title, b.price, b.stock_quantity, b.genre, b.language, b.description, b.cover_image_path, b.publication_date
ORDER BY b.book_id DESC;

-- name: InsertBookAdmin
INSERT INTO book (
    title,
    publication_date,
    price,
    stock_quantity,
    description,
    language,
    cover_image_path,
    genre
)
VALUES (
    :title,
    CURRENT_DATE,
    :price,
    :stock_quantity,
    :description,
    :language,
    :cover_image_path,
    :genre
)
RETURNING book_id;

-- name: UpdateBookPriceAdmin
UPDATE book
SET price = :price
WHERE book_id = :book_id;

-- name: IncreaseBookStockAdmin
UPDATE book
SET stock_quantity = stock_quantity + :quantity_to_add
WHERE book_id = :book_id;

-- name: UpdateBookAdmin
UPDATE book
SET
    title = :title,
    price = :price,
    stock_quantity = :stock_quantity,
    genre = :genre,
    language = :language,
    description = :description,
    cover_image_path = :cover_image_path
WHERE book_id = :book_id;

-- name: DeleteBookAdmin
DELETE FROM book
WHERE book_id = :book_id;
