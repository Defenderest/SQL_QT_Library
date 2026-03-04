-- name: InsertPaymentTransaction
INSERT INTO payment_transaction (
    provider,
    provider_order_id,
    customer_id,
    amount,
    currency,
    status,
    checkout_url,
    request_data_base64,
    request_signature
)
VALUES (
    :provider,
    :provider_order_id,
    :customer_id,
    :amount,
    :currency,
    :status,
    :checkout_url,
    :request_data_base64,
    :request_signature
)
RETURNING payment_transaction_id;

-- name: InsertPaymentStatusHistoryByTransactionId
INSERT INTO payment_status_history (payment_transaction_id, status, details)
VALUES (:payment_transaction_id, :status, :details);

-- name: GetPaymentTransactionByProviderOrderId
SELECT
    payment_transaction_id,
    customer_id,
    order_id,
    provider,
    provider_order_id,
    amount,
    currency,
    status
FROM payment_transaction
WHERE provider_order_id = :provider_order_id
LIMIT 1;

-- name: UpdatePaymentTransactionStatusByProviderOrderId
UPDATE payment_transaction
SET status = :status,
    response_data_base64 = COALESCE(:response_data_base64, response_data_base64),
    response_signature = COALESCE(:response_signature, response_signature),
    provider_payment_id = COALESCE(:provider_payment_id, provider_payment_id),
    verified_at = CASE WHEN :mark_verified THEN CURRENT_TIMESTAMP ELSE verified_at END,
    updated_at = CURRENT_TIMESTAMP
WHERE provider_order_id = :provider_order_id;

-- name: InsertPaymentStatusHistoryByProviderOrderId
INSERT INTO payment_status_history (payment_transaction_id, status, details)
SELECT payment_transaction_id, :status, :details
FROM payment_transaction
WHERE provider_order_id = :provider_order_id;

-- name: UpdatePaymentTransactionOrderLink
UPDATE payment_transaction
SET order_id = :order_id,
    updated_at = CURRENT_TIMESTAMP
WHERE provider_order_id = :provider_order_id;
