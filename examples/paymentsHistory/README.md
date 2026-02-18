# TRI Payment Service (Virtual / Stateful)

Stateful payment virtual service for **TRI** (Tricentis), following the SharedState pattern. It exposes three endpoints and persists payments in CSV.

---

## Files

| File | Description |
|------|-------------|
| `TRI-PaymentService.yml` | Simulation definition: POST payments, GET transaction report |
| `payments.csv` | Table of individual payments (paymentId, amount) |
| `account.csv` | Single-row table holding running total for account TRI |

---

## Endpoints

### 1. `POST /PaymentService` (active)

- **Purpose:** Record a payment (dollar amount) and add it to the account.
- **Request body (JSON):** `{ "amount": 5 }` (or any number).
- **Behavior:**
  - Inserts a new row in `payments.csv` with a generated `paymentId` and the given `amount`.
  - Updates the TRI row in `account.csv` so the running total includes this payment.
- **Response example:**
  ```json
  {
    "message": "Payment recorded",
    "paymentId": "123456",
    "amount": "5"
  }
  ```

### 2. `GET /PaymentService/TransactionReport` (report only, not active)

- **Purpose:** Return a JSON report of all payments posted and their total (read-only).
- **Behavior:** Reads all rows from `payments.csv` and the total from `account.csv`; no state change.
- **Response example:**
  ```json
  {
    "reportType": "TransactionReport",
    "payments": [
      {"paymentId": "p1", "amount": 5},
      {"paymentId": "p2", "amount": 10},
      {"paymentId": "p3", "amount": 5}
    ],
    "total": 20
  }
  ```

### 3. `DELETE /PaymentService/purge` (clear data)

- **Purpose:** Remove all payment data and reset the account total to 0, while preserving CSV headers and the account row.
- **Behavior:**
  - Deletes all rows from `payments` (header row is preserved).
  - Updates the TRI row in `account` to set `total` to `0` (does not remove the account row).
- **Response example:**
  ```json
  {
    "message": "Purge complete",
    "paymentsCleared": true,
    "accountReset": true
  }
  ```

---

## Example flow

| Step | Request | Result |
|------|---------|--------|
| Req#1 | `POST /PaymentService` body `{"amount": 5}` | Payment $5 recorded |
| Req#2 | `POST /PaymentService` body `{"amount": 10}` | Payment $10 recorded |
| Req#3 | `POST /PaymentService` body `{"amount": 5}` | Payment $5 recorded |
| Req#4 | `GET /PaymentService/TransactionReport` | Report: all payments listed, total $20 |
| (optional) | `DELETE /PaymentService/purge` | All data cleared; headers preserved; account reset to 0 |

---

## How to use

1. Start the API Simulator and load `TRI-PaymentService.yml`.
2. Ensure `payments.csv` and `account.csv` are in the same folder (or adjust `file:` paths in the YAML).
3. Send `POST /PaymentService` with JSON `{"amount": <number>}` to record payments.
4. Send `GET /PaymentService/TransactionReport` to get the list of payments and total.
5. Send `DELETE /PaymentService/purge` to clear all data (headers preserved) and reset the account.

**Connection:** Listens on port **17080** by default (configurable under `connections` in the YAML).

---

## Resource tables

- **payments:** `paymentId` (string), `amount` (number).
- **account:** `accountId` (string), `total` (number). One row with `accountId = TRI` holds the running total.

