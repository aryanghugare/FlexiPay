# FlexiPay EMI Electronics Catalog

A full-stack electronics storefront for comparing EMI plans backed by mutual funds. The React client receives products, categories, variants, pricing, specifications and EMI plans from Express APIs backed by PostgreSQL. No product catalog data is hard-coded in the frontend.

The catalog includes smartphones, audio devices and wearables. Each product has a stable, shareable URL such as `/products/iphone-17-pro`, and the checkout flow carries the selected product, configuration and EMI plan forward.

## Submission deliverables

- **Database schema and seed data:** [db/init.sql](db/init.sql)
- **Backend API:** [server/index.ts](server/index.ts)
- **Database migration command:** [server/migrate.ts](server/migrate.ts)
- **Render deployment blueprint:** [render.yaml](render.yaml)
- **Frontend application:** [src](src)

## Tech stack

| Layer | Technology |
| --- | --- |
| Frontend | React 18, TypeScript, React Router, Vite, responsive CSS |
| Backend | Node.js, Express, TypeScript |
| Database | PostgreSQL 16, `pg` |
| Local database | Docker Compose |
| Deployment | Render Blueprint with Render Postgres |

## Features

- Dynamic products, categories, variants, prices, images, specifications and EMI plans loaded through APIs.
- Unique product and category URLs.
- Smartphone configurations such as `12GB RAM + 256GB`; changing configuration changes the displayed price and EMI plans.
- Finish selection with product imagery stored per variant.
- Selectable EMI plans with monthly payment, tenure, interest rate and cashback.
- Checkout form with client-side validation for name, email, Indian mobile number and delivery city.
- Audio and Wearables category collections with five database-backed products each.
- Responsive storefront, functional navigation, footer links and route scroll restoration.

## Setup and run instructions

### Prerequisites

- Node.js 22 or later
- npm 10 or later
- Docker Desktop (for local PostgreSQL)

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment variables

The checked-in `.env.example` matches the local Docker database. Copy it for local use:

```bash
cp .env.example .env
```

```env
DATABASE_URL=postgres://emi_user:emi_password@localhost:5432/emi_catalog
PORT=3001
```

### 3. Start PostgreSQL

```bash
docker compose up -d
```

On the first start, Docker runs `db/init.sql`. The script is idempotent, so it is also safe to apply after subsequent schema or seed changes:

```bash
npm run db:migrate
```

### 4. Start the application

```bash
npm run dev
```

- Frontend: `http://localhost:5173`
- API: `http://localhost:3001`

Vite proxies `/api` requests to the Express server while developing.

### Useful commands

```bash
npm run build       # Type-check and create a production frontend build
npm run start       # Apply the idempotent migration, then serve Express and the built frontend
npm run db:migrate  # Apply schema and seed data
```

## API endpoints

All currency values are integers in **paise** to prevent floating-point currency errors. Interest is in basis points; for example, `1050` means 10.5%.

### `GET /api/health`

Checks database availability.

```json
{ "status": "ok" }
```

### `GET /api/products`

Returns product cards for the storefront. `imageScale` is database-driven presentation metadata used to keep mixed-aspect product visuals consistent.

```json
[
  {
    "id": 1,
    "slug": "iphone-17-pro",
    "name": "iPhone 17 Pro",
    "short_description": "A premium pro-grade smartphone.",
    "mrpPaise": 13490000,
    "pricePaise": 12740000,
    "imageUrl": "/assets/aurora-one-pro.png",
    "imageScale": "0.98",
    "defaultStorage": "256GB"
  }
]
```

### `GET /api/products/:slug`

Returns one product with its purchasable variants, EMI plans and specifications. Unknown slugs return `404`.

```json
{
  "slug": "iphone-17-pro",
  "name": "iPhone 17 Pro",
  "mrpPaise": 13490000,
  "pricePaise": 12740000,
  "imageUrl": "/assets/aurora-one-pro.png",
  "variants": [
    {
      "id": 1,
      "label": "Cosmic Orange",
      "ram": "12GB",
      "storage": "256GB",
      "configurationLabel": "12GB RAM + 256GB",
      "pricePaise": 12740000,
      "colorHex": "#ff6f19",
      "imageUrl": "/assets/aurora-one-pro.png"
    }
  ],
  "plans": [
    {
      "id": 1,
      "variantId": 1,
      "monthlyPaymentPaise": 4496700,
      "tenureMonths": 3,
      "interestRateBps": 0,
      "cashbackPaise": 750000
    }
  ],
  "specifications": [
    { "id": 1, "label": "Display", "value": "6.3-inch Super Retina XDR" }
  ]
}
```

### `GET /api/categories`

Returns active homepage categories.

```json
[
  {
    "id": 2,
    "slug": "audio",
    "name": "Audio",
    "description": "Headphones, speakers and personal sound.",
    "imageUrl": "/assets/audio-headphones-transparent.png",
    "imageScale": "0.90"
  }
]
```

### `GET /api/categories/:slug/products`

Returns an active category plus all its products.

```json
{
  "category": { "slug": "wearables", "name": "Wearables" },
  "products": [
    {
      "slug": "orbit-fit-watch",
      "name": "Orbit Fit Watch",
      "pricePaise": 2899900,
      "imageUrl": "/assets/wearable-watch-transparent.png",
      "imageScale": "0.92",
      "defaultStorage": "42mm"
    }
  ]
}
```

## Database schema and seed data

The complete executable schema and seed script is [db/init.sql](db/init.sql). It creates the following tables and is safe to run repeatedly through `npm run db:migrate`.

| Table | Key columns | Purpose |
| --- | --- | --- |
| `categories` | `slug`, `name`, `image_url`, `image_scale`, `display_order` | Homepage category cards and category routes. |
| `products` | `slug`, `name`, `category_id`, `mrp_paise`, `price_paise`, `image_url`, `image_scale` | Core product catalog and stable product URL. |
| `product_variants` | `product_id`, `label`, `ram`, `storage`, `configuration_label`, `price_paise`, `image_url` | Purchasable colour/finish and configuration choices. |
| `emi_plans` | `product_id`, `variant_id`, `monthly_payment_paise`, `tenure_months`, `interest_rate_bps`, `cashback_paise` | EMI offers for a specific product variant. |
| `product_specifications` | `product_id`, `label`, `value`, `display_order` | Ordered facts displayed on product pages. |

Relationship overview:

```text
categories 1 ──── * products 1 ──── * product_variants 1 ──── * emi_plans
                         │
                         └────────────────────────────── * product_specifications
```

Important constraints and indexes include:

- Unique product and category slugs.
- Foreign keys from products to categories, and from variants/plans/specifications to products.
- A unique variant finish + storage combination per product.
- A unique EMI tenure per variant.
- Positive prices, monthly payments and tenures enforced with database checks.

The seed includes smartphones, five Audio products, five Wearables products, their variants, item-specific specifications and EMI offers.

## Deploy to Render

The repository includes [render.yaml](render.yaml), which creates a Node web service and Render Postgres database.

1. Push the initialized repository to GitHub.
2. In Render, select **New → Blueprint** and select this repository.
3. Render runs `npm ci && npm run build`, applies `npm run db:migrate`, and starts the service with `npm start`.
4. The resulting service serves the React application and `/api` from the same origin. Its health check is `/api/health`.

`DATABASE_URL` is wired automatically from the Blueprint-managed `flexipay-emi-db` database.

### Deploying the frontend separately on Vercel

Add the following **Config** environment variable in Vercel (it is intentionally public because Vite bundles `VITE_` values into the browser):

```env
VITE_API_BASE_URL=https://your-render-service.onrender.com
```

Use the full Render service URL without a trailing slash, then redeploy Vercel after saving it. Do not use the Secret type for this variable; it is a public API address, not a credential.
