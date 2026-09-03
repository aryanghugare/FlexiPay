# FlexiPay EMI Product Catalog

A full-stack product catalog for comparing smartphone EMI plans backed by mutual funds. Product, variant, price, image, and financing data is stored in PostgreSQL and fetched by the React client from Express APIs—no catalog data is hard-coded in the interface.

## Tech stack

- **Frontend:** React 18, TypeScript, React Router, and custom responsive CSS.
- **Backend:** Node.js, Express, TypeScript, and `pg`.
- **Database:** PostgreSQL 16.
- **Deployment:** Render Blueprint (`render.yaml`) with one Node web service and managed Render Postgres.

## Features

- Three unique product URLs: `/products/iphone-17-pro`, `/products/samsung-s24-ultra`, and `/products/pixel-9-pro`.
- Two selectable storage capacities and three finish choices for every product, represented as database-backed color/storage variants.
- Selectable EMI plans with monthly payment, tenure, interest rate, and cashback.
- Direct plan checkout: the selected product, variant, and EMI plan are carried to a checkout form and confirmation state.
- Database-backed APIs, responsive catalog/detail pages, navbar, and footer.

## Local setup

### Prerequisites

- Node.js 22+
- Docker Desktop (for PostgreSQL)

### Run

```bash
npm install
docker compose up -d
npm run dev
```

Open `http://localhost:5173`. Vite serves the React application on port 5173 and proxies `/api` calls to the Express API on port 3001.

The Docker database automatically runs `db/init.sql` on its first startup. To apply the idempotent schema/seed script manually, run:

```bash
npm run db:migrate
```

Check the production build with:

```bash
npm run build
```

## API

### `GET /api/health`

Returns database health.

```json
{ "status": "ok" }
```

### `GET /api/products`

Returns summary data for the catalog.

```json
[
  {
    "id": 1,
    "slug": "iphone-17-pro",
    "name": "iPhone 17 Pro",
    "mrpPaise": 13490000,
    "pricePaise": 12740000,
    "imageUrl": "/assets/aurora-one-pro.png",
    "defaultStorage": "256GB"
  }
]
```

### `GET /api/products/:slug`

Returns one product, its variants, and its selectable EMI plans. Unknown slugs return `404`.

```json
{
  "slug": "iphone-17-pro",
  "name": "iPhone 17 Pro",
  "mrpPaise": 13490000,
  "pricePaise": 12740000,
  "variants": [
    { "id": 1, "label": "Cosmic Orange", "storage": "256GB", "colorHex": "#ff6f19" }
  ],
  "plans": [
    { "id": 1, "monthlyPaymentPaise": 4496700, "tenureMonths": 3, "interestRateBps": 0, "cashbackPaise": 750000 }
  ],
  "specifications": [
    { "id": 1, "label": "Display", "value": "6.3-inch Super Retina XDR" }
  ]
}
```

All currency is sent and stored as integer paise, avoiding floating-point currency errors. `interestRateBps` is basis points, so `1050` represents 10.5%.

## Database schema

The full PostgreSQL schema and seed data live in [db/init.sql](db/init.sql).

| Table | Purpose |
| --- | --- |
| `products` | Product name, stable URL slug, MRP, sale price, and main image. |
| `product_variants` | Color/storage choices belonging to a product. |
| `emi_plans` | Monthly payment, tenure, interest rate, cashback, and display order per product. |
| `product_specifications` | Ordered product facts such as display, cameras, battery, connectivity, and protection. |

Foreign keys enforce that variants and plans always belong to a valid product. Product slugs are unique; a variant is unique per `(product_id, finish, storage)` combination, and `(product_id, tenure_months)` is unique for plans.

## Deploy to Render

The repository includes [render.yaml](render.yaml), which provisions the web service and a Render Postgres database together.

1. Create a GitHub repository and push this project to it.
2. In Render, select **New → Blueprint**, connect the repository, and approve the detected `render.yaml` services.
3. Render runs `npm ci && npm run build`, applies the idempotent schema/seed script via `npm run db:migrate`, then starts the application with `npm start`.
4. Open the generated `onrender.com` URL. The Express service serves both the built React application and the `/api` endpoints from the same origin.

`DATABASE_URL` is automatically wired from the managed `flexipay-emi-db` database to the web service through the Blueprint. The service health check is `/api/health`.

For the live submission URL, add the Render deployment URL here after connecting your GitHub repository.
