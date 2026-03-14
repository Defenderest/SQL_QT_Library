-- name: InsertBookReservation
INSERT INTO book_reservation (
    customer_id,
    provider_order_id,
    status,
    expires_at
)
VALUES (
    :customer_id,
    :provider_order_id,
    :status,
    :expires_at
)
RETURNING reservation_id;

-- name: InsertBookReservationItem
INSERT INTO book_reservation_item (
    reservation_id,
    book_id,
    quantity
)
VALUES (
    :reservation_id,
    :book_id,
    :quantity
);

-- name: GetBookReservationByProviderOrderIdForUpdate
SELECT
    reservation_id,
    customer_id,
    order_id,
    status,
    expires_at
FROM book_reservation
WHERE provider_order_id = :provider_order_id
LIMIT 1
FOR UPDATE;

-- name: GetBookReservationItemsByReservationId
SELECT book_id, quantity
FROM book_reservation_item
WHERE reservation_id = :reservation_id
ORDER BY reservation_item_id ASC;

-- name: UpdateBookReservationStatusById
UPDATE book_reservation
SET status = :status,
    updated_at = CURRENT_TIMESTAMP
WHERE reservation_id = :reservation_id;

-- name: CompleteBookReservationById
UPDATE book_reservation
SET status = :status,
    order_id = :order_id,
    updated_at = CURRENT_TIMESTAMP
WHERE reservation_id = :reservation_id;

-- name: GetExpiredActiveBookReservationsForUpdate
SELECT reservation_id
FROM book_reservation
WHERE status = 'active'
  AND expires_at <= CURRENT_TIMESTAMP
ORDER BY reservation_id
FOR UPDATE;

-- name: IncreaseBookStock
UPDATE book
SET stock_quantity = stock_quantity + :quantity
WHERE book_id = :book_id;
