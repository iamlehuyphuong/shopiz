# Shopiz Platform Integration Guide

This guide outlines the conventions and patterns for developing e-commerce integrations within Shopiz.

## 1. Controller Layer (`app/controllers/api/v1/accounts/integrations/`)

Every platform integration must provide the following standard endpoints:
- `POST /auth`: Handles authentication and connection logic. Must use `find_or_initialize_by` to upsert the `Integrations::Hook` safely (supporting reconnects).
- `GET /orders`: Returns orders. **Must filter by `contact_id`** (email or phone lookup). Do not return all orders indiscriminately.
- `GET /products`: Returns products from the platform.
- `GET /customers`: Returns a list of customers or searches based on contact details.
- `DELETE /destroy`: Disconnects the integration.

*Note: Features like `all_orders` and `stock_status` enrichment at the controller level are specific to Shopify and not required for all platforms.*

## 2. Proxy Layer (`app/services/conversation_orders/`)

Every platform proxy must inherit from `ConversationOrders::PlatformProxy` and implement:
- `create_order(payload)`
- `fetch_order(order_id)`
- `fetch_products(page = 1)`: **CRITICAL** for `Sales::ProductsSyncService`. Must return an array of standardized product hashes and a `has_more` boolean. Standard format: `external_id, name, price, currency, sku, status, variants`.
- `map_status(raw_status)`: Maps platform-specific statuses to Shopiz internal ones (`:draft, :confirmed, :processing, :shipped, :delivered, :cancelled`).

## 3. Webhook Layer (`app/controllers/webhooks/`)

Platform webhooks should map updates to `WebhookSyncJob.perform_later(platform: '...', external_order_id: '...')`.
- Handle verification via HMAC-SHA256 or specific webhook secrets.
- GDPR handlers (`shop/redact`) are mandatory for Shopify but optional for other platforms based on their respective app store policies.

## 4. Captain AI Tools Layer (`enterprise/lib/captain/tools/`)

Every platform needs a suite of Captain tools.
- **Client Concerns**: Shared logic should reside in `Captain::Tools::Concerns::{Platform}Client`.
- **Currency Formatting**: Always use the standardized `format_currency(amount, currency = 'VND')` method.
- **Routable Tools**: Ensure the platform is registered in the generic tools using `Captain::Tools::Concerns::EcomRoutable`.

## 5. Token Management
If a platform (e.g., KiotViet) issues expiring access tokens (OAuth `client_credentials`), the client concern must implement an `ensure_valid_token` check to refresh the token before every API call.

For platforms using permanent API keys (Haravan, Sapo) or Basic Auth (WooCommerce), store the credentials securely in the `Hook` model and pass them in headers per request.
