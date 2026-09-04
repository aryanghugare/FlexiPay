import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import { Pool } from 'pg';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

const app = express();
const port = Number(process.env.PORT ?? 3001);
const pool = new Pool({
  connectionString: process.env.DATABASE_URL ?? 'postgres://emi_user:emi_password@localhost:5432/emi_catalog'
});

app.use(cors());
app.use(express.json());

app.get('/api/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok' });
  } catch {
    res.status(503).json({ error: 'Database is unavailable' });
  }
});

app.get('/api/products', async (_req, res, next) => {
  try {
    const { rows } = await pool.query(`
      SELECT p.id, p.slug, p.name, p.short_description, p.mrp_paise AS "mrpPaise",
             p.price_paise AS "pricePaise", p.image_url AS "imageUrl", p.image_scale AS "imageScale",
             (SELECT storage FROM product_variants WHERE product_id = p.id ORDER BY display_order LIMIT 1) AS "defaultStorage"
      FROM products p ORDER BY p.id
    `);
    res.json(rows);
  } catch (error) { next(error); }
});

app.get('/api/categories', async (_req, res, next) => {
  try {
    const { rows } = await pool.query(`
      SELECT id, slug, name, description, image_url AS "imageUrl", image_scale AS "imageScale"
      FROM categories
      WHERE is_active = TRUE
      ORDER BY display_order
    `);
    res.json(rows);
  } catch (error) { next(error); }
});

app.get('/api/categories/:slug/products', async (req, res, next) => {
  try {
    const categoryResult = await pool.query(`
      SELECT id, slug, name, description, image_url AS "imageUrl", image_scale AS "imageScale"
      FROM categories WHERE slug = $1 AND is_active = TRUE
    `, [req.params.slug]);
    const category = categoryResult.rows[0];
    if (!category) return res.status(404).json({ error: 'Category not found' });
    const { rows: products } = await pool.query(`
      SELECT p.id, p.slug, p.name, p.short_description, p.mrp_paise AS "mrpPaise",
             p.price_paise AS "pricePaise", p.image_url AS "imageUrl", p.image_scale AS "imageScale",
             (SELECT storage FROM product_variants WHERE product_id = p.id ORDER BY display_order LIMIT 1) AS "defaultStorage"
      FROM products p WHERE p.category_id = $1 ORDER BY p.id
    `, [category.id]);
    res.json({ category, products });
  } catch (error) { next(error); }
});

app.get('/api/products/:slug', async (req, res, next) => {
  try {
    const productResult = await pool.query(`
      SELECT id, slug, name, short_description AS "shortDescription", mrp_paise AS "mrpPaise",
             price_paise AS "pricePaise", image_url AS "imageUrl", image_scale AS "imageScale"
      FROM products WHERE slug = $1
    `, [req.params.slug]);
    const product = productResult.rows[0];
    if (!product) return res.status(404).json({ error: 'Product not found' });

    const [variants, plans, specifications] = await Promise.all([
      pool.query(`SELECT id, label, ram, storage, configuration_label AS "configurationLabel", mrp_paise AS "mrpPaise", price_paise AS "pricePaise", color_hex AS "colorHex", image_url AS "imageUrl"
        FROM product_variants WHERE product_id = $1 ORDER BY display_order`, [product.id]),
      pool.query(`SELECT id, variant_id AS "variantId", monthly_payment_paise AS "monthlyPaymentPaise", tenure_months AS "tenureMonths",
        interest_rate_bps AS "interestRateBps", cashback_paise AS "cashbackPaise"
        FROM emi_plans WHERE product_id = $1 ORDER BY display_order`, [product.id]),
      pool.query(`SELECT id, label, value FROM product_specifications
        WHERE product_id = $1 ORDER BY display_order`, [product.id])
    ]);
    res.json({ ...product, variants: variants.rows, plans: plans.rows, specifications: specifications.rows });
  } catch (error) { next(error); }
});

const clientBuildPath = resolve(process.cwd(), 'dist');
if (existsSync(clientBuildPath)) {
  app.use(express.static(clientBuildPath));
  app.get('*', (_req, res) => res.sendFile(resolve(clientBuildPath, 'index.html')));
}

app.use((error: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(error);
  res.status(500).json({ error: 'Something went wrong while loading catalog data' });
});

app.listen(port, () => console.log(`API listening on http://localhost:${port}`));
