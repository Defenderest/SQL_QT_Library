-- name: CheckUserCommentExists
SELECT COUNT(*)
FROM comment
WHERE book_id = :bookId AND customer_id = :customerId;

-- name: AddComment
INSERT INTO comment (book_id, customer_id, comment_text, comment_date, rating)
VALUES (:book_id, :customer_id, :comment_text, CURRENT_TIMESTAMP, :rating);

-- name: GetBookCommentsByBookId
SELECT
    c.comment_text,
    c.comment_date,
    c.rating,
    cust.first_name || ' ' || cust.last_name AS author_name
FROM comment c
JOIN customer cust ON c.customer_id = cust.customer_id
WHERE c.book_id = :bookId
ORDER BY c.comment_date DESC;

-- name: GetAllCommentsForAdmin
SELECT
    c.comment_id,
    c.book_id,
    b.title AS book_title,
    c.customer_id,
    cust.first_name || ' ' || cust.last_name AS author_name,
    c.rating,
    c.comment_text,
    c.comment_date
FROM comment c
JOIN customer cust ON c.customer_id = cust.customer_id
JOIN book b ON c.book_id = b.book_id
ORDER BY c.comment_date DESC;

-- name: DeleteCommentByIdAdmin
DELETE FROM comment
WHERE comment_id = :comment_id;
