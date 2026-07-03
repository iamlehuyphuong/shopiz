
## E-Commerce Integration
- When creating or modifying an e-commerce platform integration, adhere strictly to the conventions in `.agents/PLATFORM_INTEGRATION_GUIDE.md`.
- All platforms must support `fetch_products(page = 1)` in their Proxy layer for batch syncing.
- All `/orders` controller endpoints must filter orders by the `contact_id` passed from the frontend.
