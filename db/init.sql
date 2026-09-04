CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  short_description TEXT NOT NULL,
  mrp_paise INTEGER NOT NULL CHECK (mrp_paise > 0),
  price_paise INTEGER NOT NULL CHECK (price_paise > 0 AND price_paise <= mrp_paise),
  image_url TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url TEXT NOT NULL,
  image_scale NUMERIC(4,2) NOT NULL DEFAULT 1.00 CHECK (image_scale > 0),
  display_order SMALLINT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

ALTER TABLE products ADD COLUMN IF NOT EXISTS category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL;
ALTER TABLE products ADD COLUMN IF NOT EXISTS image_scale NUMERIC(4,2) NOT NULL DEFAULT 1.00;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS image_scale NUMERIC(4,2) NOT NULL DEFAULT 1.00;

CREATE TABLE IF NOT EXISTS product_variants (
  id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  storage TEXT NOT NULL,
  mrp_paise INTEGER NOT NULL DEFAULT 0,
  price_paise INTEGER NOT NULL DEFAULT 0,
  color_hex CHAR(7) NOT NULL,
  image_url TEXT NOT NULL,
  display_order SMALLINT NOT NULL DEFAULT 0,
  UNIQUE (product_id, label)
);

CREATE TABLE IF NOT EXISTS emi_plans (
  id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  variant_id INTEGER REFERENCES product_variants(id) ON DELETE CASCADE,
  monthly_payment_paise INTEGER NOT NULL CHECK (monthly_payment_paise > 0),
  tenure_months SMALLINT NOT NULL CHECK (tenure_months > 0),
  interest_rate_bps INTEGER NOT NULL CHECK (interest_rate_bps >= 0),
  cashback_paise INTEGER NOT NULL DEFAULT 0 CHECK (cashback_paise >= 0),
  display_order SMALLINT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS product_specifications (
  id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  value TEXT NOT NULL,
  display_order SMALLINT NOT NULL DEFAULT 0,
  UNIQUE (product_id, label)
);

ALTER TABLE product_variants ADD COLUMN IF NOT EXISTS ram TEXT NOT NULL DEFAULT '12GB';
ALTER TABLE product_variants ADD COLUMN IF NOT EXISTS configuration_label TEXT NOT NULL DEFAULT '';
ALTER TABLE emi_plans ADD COLUMN IF NOT EXISTS variant_id INTEGER REFERENCES product_variants(id) ON DELETE CASCADE;

-- A finish can be offered at more than one storage capacity.
ALTER TABLE product_variants DROP CONSTRAINT IF EXISTS product_variants_product_id_label_key;

CREATE INDEX IF NOT EXISTS emi_plans_product_order_idx ON emi_plans(product_id, display_order);
DROP INDEX IF EXISTS emi_plans_product_tenure_unique_idx;
CREATE UNIQUE INDEX IF NOT EXISTS emi_plans_product_default_tenure_unique_idx ON emi_plans(product_id, tenure_months) WHERE variant_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS emi_plans_variant_tenure_unique_idx ON emi_plans(variant_id, tenure_months) WHERE variant_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS product_variants_product_order_idx ON product_variants(product_id, display_order);
CREATE UNIQUE INDEX IF NOT EXISTS product_variants_product_finish_storage_unique_idx ON product_variants(product_id, label, storage);
CREATE INDEX IF NOT EXISTS product_specifications_product_order_idx ON product_specifications(product_id, display_order);

INSERT INTO products (slug, name, short_description, mrp_paise, price_paise, image_url) VALUES
  ('iphone-17-pro', 'iPhone 17 Pro', 'A premium pro-grade smartphone.', 13490000, 12740000, '/assets/aurora-one-pro.png'),
  ('samsung-s24-ultra', 'Samsung Galaxy S24 Ultra', 'A large-screen flagship built for detail.', 12999900, 11999900, '/assets/nebula-ultra.png'),
  ('pixel-9-pro', 'Google Pixel 9 Pro', 'A polished camera-first flagship.', 10999900, 9999900, '/assets/vertex-pro.png')
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, short_description = EXCLUDED.short_description, mrp_paise = EXCLUDED.mrp_paise,
  price_paise = EXCLUDED.price_paise, image_url = EXCLUDED.image_url;

-- Preserve category ids while giving their public URLs meaningful electronics names.
UPDATE categories SET slug = CASE slug
  WHEN 'flagship' THEN 'smartphones'
  WHEN 'camera' THEN 'audio'
  WHEN 'performance' THEN 'wearables'
  ELSE slug
END
WHERE slug IN ('flagship', 'camera', 'performance');

INSERT INTO categories (slug, name, description, image_url, image_scale, display_order, is_active) VALUES
  ('smartphones', 'Smartphones', 'Flagship phones built for every day.', '/assets/aurora-one-pro.png', 0.92, 1, TRUE),
  ('audio', 'Audio', 'Headphones, speakers and personal sound.', '/assets/audio-headphones-transparent.png', 0.90, 2, TRUE),
  ('wearables', 'Wearables', 'Watches and essentials that move with you.', '/assets/wearable-watch-transparent.png', 0.90, 3, TRUE)
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description,
  image_url = EXCLUDED.image_url, image_scale = EXCLUDED.image_scale, display_order = EXCLUDED.display_order, is_active = EXCLUDED.is_active;

UPDATE products SET category_id = (SELECT id FROM categories WHERE slug = 'smartphones');

WITH finish_seed (product_slug, label, color_hex, image_url, color_order) AS (
  VALUES
    ('iphone-17-pro', 'Cosmic Orange', '#ff6f19', '/assets/aurora-one-pro.png', 1),
    ('iphone-17-pro', 'Silver Mist', '#e4e5e8', '/assets/aurora-one-pro-silver-v2.png', 2),
    ('iphone-17-pro', 'Deep Blue', '#3f527e', '/assets/aurora-one-pro-blue-v2.png', 3),
    ('samsung-s24-ultra', 'Titanium Gray', '#5d6267', '/assets/nebula-ultra.png', 1),
    ('samsung-s24-ultra', 'Forest Green', '#2e5545', '/assets/nebula-ultra-green-v2.png', 2),
    ('samsung-s24-ultra', 'Titanium Violet', '#766583', '/assets/nebula-ultra-violet-v2.png', 3),
    ('pixel-9-pro', 'Porcelain', '#e7e1d6', '/assets/vertex-pro.png', 1),
    ('pixel-9-pro', 'Hazel', '#6a6752', '/assets/vertex-pro-hazel-v2.png', 2),
    ('pixel-9-pro', 'Rose Quartz', '#9d6e78', '/assets/vertex-pro-rose-v2.png', 3)
), storage_seed (product_slug, storage, storage_order) AS (
  VALUES
    ('iphone-17-pro', '256GB', 1), ('iphone-17-pro', '512GB', 2),
    ('samsung-s24-ultra', '256GB', 1), ('samsung-s24-ultra', '512GB', 2),
    ('pixel-9-pro', '128GB', 1), ('pixel-9-pro', '256GB', 2)
)
INSERT INTO product_variants (product_id, label, storage, color_hex, image_url, display_order)
SELECT products.id, finish_seed.label, storage_seed.storage, finish_seed.color_hex, finish_seed.image_url,
       (finish_seed.color_order * 10) + storage_seed.storage_order
FROM finish_seed
JOIN storage_seed USING (product_slug)
JOIN products ON products.slug = finish_seed.product_slug
ON CONFLICT (product_id, label, storage) DO UPDATE SET color_hex = EXCLUDED.color_hex,
  image_url = EXCLUDED.image_url, display_order = EXCLUDED.display_order;

INSERT INTO emi_plans (product_id, monthly_payment_paise, tenure_months, interest_rate_bps, cashback_paise, display_order)
SELECT id, 4496700, 3, 0, 750000, 1 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 2248300, 6, 0, 750000, 2 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 1124200, 12, 0, 750000, 3 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 562100, 24, 0, 750000, 4 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 429700, 36, 1050, 750000, 5 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 338500, 48, 1050, 750000, 6 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 284200, 60, 1050, 750000, 7 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 3999970, 3, 0, 600000, 1 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 1999990, 6, 0, 600000, 2 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 999990, 12, 0, 600000, 3 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 499995, 24, 0, 600000, 4 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 333330, 36, 1050, 600000, 5 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 3333300, 3, 0, 500000, 1 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 1666650, 6, 0, 500000, 2 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 833325, 12, 0, 500000, 3 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 416663, 24, 0, 500000, 4 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 277775, 36, 1050, 500000, 5 FROM products WHERE slug = 'pixel-9-pro'
ON CONFLICT (product_id, tenure_months) WHERE variant_id IS NULL DO UPDATE SET monthly_payment_paise = EXCLUDED.monthly_payment_paise,
  interest_rate_bps = EXCLUDED.interest_rate_bps, cashback_paise = EXCLUDED.cashback_paise, display_order = EXCLUDED.display_order;

INSERT INTO product_specifications (product_id, label, value, display_order)
SELECT id, 'Display', '6.3-inch Super Retina XDR', 1 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 'Chip', 'A19 Pro', 2 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 'Rear cameras', '48MP Pro Fusion system', 3 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 'Build', 'Aluminum unibody', 4 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 'Battery', 'Up to 31 hours video playback', 5 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 'Connectivity', '5G, Wi-Fi 7 and Bluetooth 6', 6 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 'Protection', 'IP68 dust and water resistance', 7 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 'Charging', 'USB-C with MagSafe wireless charging', 8 FROM products WHERE slug = 'iphone-17-pro'
UNION ALL SELECT id, 'Display', '6.8-inch Dynamic AMOLED 2X', 1 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 'Rear cameras', '200MP quad camera system', 2 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 'Stylus', 'Built-in S Pen support', 3 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 'Processor', 'Snapdragon 8 Gen 3 for Galaxy', 4 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 'Memory', '12GB RAM', 5 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 'Battery', '5,000mAh battery', 6 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 'Protection', 'IP68 dust and water resistance', 7 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 'Connectivity', '5G, Wi-Fi 7 and Bluetooth 5.3', 8 FROM products WHERE slug = 'samsung-s24-ultra'
UNION ALL SELECT id, 'Display', '6.3-inch Super Actua', 1 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 'Processor', 'Google Tensor G4', 2 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 'Rear cameras', 'Pro triple camera system', 3 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 'Memory', '16GB RAM', 4 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 'Battery', '4,700mAh battery', 5 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 'Security', 'Titan M2 security coprocessor', 6 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 'Protection', 'IP68 dust and water resistance', 7 FROM products WHERE slug = 'pixel-9-pro'
UNION ALL SELECT id, 'Connectivity', '5G, Wi-Fi 7 and Bluetooth 5.3', 8 FROM products WHERE slug = 'pixel-9-pro'
ON CONFLICT (product_id, label) DO UPDATE SET value = EXCLUDED.value, display_order = EXCLUDED.display_order;

UPDATE product_variants
SET configuration_label = ram || ' RAM + ' || storage
WHERE configuration_label = '';

ALTER TABLE emi_plans ADD COLUMN IF NOT EXISTS variant_id INTEGER REFERENCES product_variants(id) ON DELETE CASCADE;
DROP INDEX IF EXISTS emi_plans_product_tenure_unique_idx;
CREATE UNIQUE INDEX IF NOT EXISTS emi_plans_variant_tenure_unique_idx ON emi_plans(variant_id, tenure_months) WHERE variant_id IS NOT NULL;

ALTER TABLE product_variants ADD COLUMN IF NOT EXISTS mrp_paise INTEGER NOT NULL DEFAULT 0;
ALTER TABLE product_variants ADD COLUMN IF NOT EXISTS price_paise INTEGER NOT NULL DEFAULT 0;

-- Reapply configuration pricing after all seed variants are present.
UPDATE product_variants AS variant
SET price_paise = CASE product.slug
  WHEN 'iphone-17-pro' THEN CASE variant.storage WHEN '512GB' THEN 14740000 ELSE 12740000 END
  WHEN 'samsung-s24-ultra' THEN CASE variant.storage WHEN '512GB' THEN 13499900 ELSE 11999900 END
  WHEN 'pixel-9-pro' THEN CASE variant.storage WHEN '256GB' THEN 10999900 ELSE 9999900 END
  WHEN 'oneplus-13' THEN CASE variant.storage WHEN '512GB' THEN 8299900 ELSE 7299900 END
  WHEN 'pixel-9a' THEN CASE variant.storage WHEN '256GB' THEN 5499900 ELSE 4999900 END
  WHEN 'xiaomi-15' THEN CASE variant.storage WHEN '512GB' THEN 7499900 ELSE 6499900 END
  ELSE product.price_paise
END,
mrp_paise = CASE product.slug
  WHEN 'iphone-17-pro' THEN CASE variant.storage WHEN '512GB' THEN 15490000 ELSE 13490000 END
  WHEN 'samsung-s24-ultra' THEN CASE variant.storage WHEN '512GB' THEN 14499900 ELSE 12999900 END
  WHEN 'pixel-9-pro' THEN CASE variant.storage WHEN '256GB' THEN 11999900 ELSE 10999900 END
  WHEN 'oneplus-13' THEN CASE variant.storage WHEN '512GB' THEN 8999900 ELSE 7999900 END
  WHEN 'pixel-9a' THEN CASE variant.storage WHEN '256GB' THEN 5999900 ELSE 5499900 END
  WHEN 'xiaomi-15' THEN CASE variant.storage WHEN '512GB' THEN 7999900 ELSE 6999900 END
  ELSE product.mrp_paise
END
FROM products AS product
WHERE product.id = variant.product_id;

ALTER TABLE product_variants ADD COLUMN IF NOT EXISTS mrp_paise INTEGER NOT NULL DEFAULT 0;
ALTER TABLE product_variants ADD COLUMN IF NOT EXISTS price_paise INTEGER NOT NULL DEFAULT 0;

UPDATE product_variants AS variant
SET price_paise = CASE product.slug
  WHEN 'iphone-17-pro' THEN CASE variant.storage WHEN '512GB' THEN 14740000 ELSE 12740000 END
  WHEN 'samsung-s24-ultra' THEN CASE variant.storage WHEN '512GB' THEN 13499900 ELSE 11999900 END
  WHEN 'pixel-9-pro' THEN CASE variant.storage WHEN '256GB' THEN 10999900 ELSE 9999900 END
  WHEN 'oneplus-13' THEN CASE variant.storage WHEN '512GB' THEN 8299900 ELSE 7299900 END
  WHEN 'pixel-9a' THEN CASE variant.storage WHEN '256GB' THEN 5499900 ELSE 4999900 END
  WHEN 'xiaomi-15' THEN CASE variant.storage WHEN '512GB' THEN 7499900 ELSE 6499900 END
  ELSE product.price_paise
END,
mrp_paise = CASE product.slug
  WHEN 'iphone-17-pro' THEN CASE variant.storage WHEN '512GB' THEN 15490000 ELSE 13490000 END
  WHEN 'samsung-s24-ultra' THEN CASE variant.storage WHEN '512GB' THEN 14499900 ELSE 12999900 END
  WHEN 'pixel-9-pro' THEN CASE variant.storage WHEN '256GB' THEN 11999900 ELSE 10999900 END
  WHEN 'oneplus-13' THEN CASE variant.storage WHEN '512GB' THEN 8999900 ELSE 7999900 END
  WHEN 'pixel-9a' THEN CASE variant.storage WHEN '256GB' THEN 5999900 ELSE 5499900 END
  WHEN 'xiaomi-15' THEN CASE variant.storage WHEN '512GB' THEN 7999900 ELSE 6999900 END
  ELSE product.mrp_paise
END
FROM products AS product
WHERE product.id = variant.product_id;

-- RAM and storage are maintained independently from the finish so the UI can offer real-world configurations.
UPDATE product_variants SET ram = CASE
  WHEN product_id = (SELECT id FROM products WHERE slug = 'pixel-9-pro') THEN '16GB'
  ELSE '12GB'
END;

UPDATE product_variants
SET configuration_label = ram || ' RAM + ' || storage
WHERE configuration_label = '';

INSERT INTO products (slug, name, short_description, mrp_paise, price_paise, image_url, category_id) VALUES
  ('oneplus-13', 'OnePlus 13', 'A performance-focused flagship with a refined build.', 7999900, 7299900, '/assets/oneplus-13.png', (SELECT id FROM categories WHERE slug = 'smartphones')),
  ('pixel-9a', 'Google Pixel 9a', 'A smart, camera-ready everyday phone.', 5499900, 4999900, '/assets/pixel-9a.png', (SELECT id FROM categories WHERE slug = 'smartphones')),
  ('xiaomi-15', 'Xiaomi 15', 'A compact flagship built for fast everyday use.', 6999900, 6499900, '/assets/xiaomi-15.png', (SELECT id FROM categories WHERE slug = 'smartphones'))
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, short_description = EXCLUDED.short_description,
  mrp_paise = EXCLUDED.mrp_paise, price_paise = EXCLUDED.price_paise, image_url = EXCLUDED.image_url,
  category_id = EXCLUDED.category_id;

WITH finish_seed (product_slug, label, color_hex, image_url, color_order) AS (
  VALUES
    ('oneplus-13', 'Arctic Dawn', '#e7e8e5', '/assets/oneplus-13.png', 1), ('oneplus-13', 'Midnight Ocean', '#25354d', '/assets/oneplus-13.png', 2),
    ('pixel-9a', 'Iris', '#7073a4', '/assets/pixel-9a.png', 1), ('pixel-9a', 'Porcelain', '#e8e4dc', '/assets/pixel-9a.png', 2),
    ('xiaomi-15', 'Black', '#25272a', '/assets/xiaomi-15.png', 1), ('xiaomi-15', 'Silver', '#dadddf', '/assets/xiaomi-15.png', 2)
), configuration_seed (product_slug, ram, storage, configuration_order) AS (
  VALUES
    ('oneplus-13', '12GB', '256GB', 1), ('oneplus-13', '16GB', '512GB', 2),
    ('pixel-9a', '8GB', '128GB', 1), ('pixel-9a', '8GB', '256GB', 2),
    ('xiaomi-15', '12GB', '256GB', 1), ('xiaomi-15', '16GB', '512GB', 2)
)
INSERT INTO product_variants (product_id, label, ram, storage, color_hex, image_url, display_order)
SELECT products.id, finish_seed.label, configuration_seed.ram, configuration_seed.storage, finish_seed.color_hex, finish_seed.image_url,
       (finish_seed.color_order * 10) + configuration_seed.configuration_order
FROM finish_seed JOIN configuration_seed USING (product_slug) JOIN products ON products.slug = finish_seed.product_slug
ON CONFLICT (product_id, label, storage) DO UPDATE SET ram = EXCLUDED.ram, color_hex = EXCLUDED.color_hex,
  image_url = EXCLUDED.image_url, display_order = EXCLUDED.display_order;

INSERT INTO emi_plans (product_id, monthly_payment_paise, tenure_months, interest_rate_bps, cashback_paise, display_order)
SELECT id, 2433000, 3, 0, 400000, 1 FROM products WHERE slug = 'oneplus-13'
UNION ALL SELECT id, 1216500, 6, 0, 400000, 2 FROM products WHERE slug = 'oneplus-13'
UNION ALL SELECT id, 608250, 12, 0, 400000, 3 FROM products WHERE slug = 'oneplus-13'
UNION ALL SELECT id, 1666300, 3, 0, 250000, 1 FROM products WHERE slug = 'pixel-9a'
UNION ALL SELECT id, 833150, 6, 0, 250000, 2 FROM products WHERE slug = 'pixel-9a'
UNION ALL SELECT id, 416575, 12, 0, 250000, 3 FROM products WHERE slug = 'pixel-9a'
UNION ALL SELECT id, 2166300, 3, 0, 350000, 1 FROM products WHERE slug = 'xiaomi-15'
UNION ALL SELECT id, 1083150, 6, 0, 350000, 2 FROM products WHERE slug = 'xiaomi-15'
UNION ALL SELECT id, 541575, 12, 0, 350000, 3 FROM products WHERE slug = 'xiaomi-15'
ON CONFLICT (product_id, tenure_months) WHERE variant_id IS NULL DO UPDATE SET monthly_payment_paise = EXCLUDED.monthly_payment_paise,
  interest_rate_bps = EXCLUDED.interest_rate_bps, cashback_paise = EXCLUDED.cashback_paise, display_order = EXCLUDED.display_order;

INSERT INTO product_specifications (product_id, label, value, display_order)
SELECT id, 'Display', '6.82-inch AMOLED', 1 FROM products WHERE slug = 'oneplus-13'
UNION ALL SELECT id, 'Processor', 'Snapdragon 8 Elite', 2 FROM products WHERE slug = 'oneplus-13'
UNION ALL SELECT id, 'Battery', '6,000mAh battery', 3 FROM products WHERE slug = 'oneplus-13'
UNION ALL SELECT id, 'Charging', '100W fast charging', 4 FROM products WHERE slug = 'oneplus-13'
UNION ALL SELECT id, 'Display', '6.3-inch Actua display', 1 FROM products WHERE slug = 'pixel-9a'
UNION ALL SELECT id, 'Processor', 'Google Tensor G4', 2 FROM products WHERE slug = 'pixel-9a'
UNION ALL SELECT id, 'Cameras', 'Dual rear camera system', 3 FROM products WHERE slug = 'pixel-9a'
UNION ALL SELECT id, 'Protection', 'IP68 water and dust resistance', 4 FROM products WHERE slug = 'pixel-9a'
UNION ALL SELECT id, 'Display', '6.36-inch AMOLED', 1 FROM products WHERE slug = 'xiaomi-15'
UNION ALL SELECT id, 'Processor', 'Snapdragon 8 Elite', 2 FROM products WHERE slug = 'xiaomi-15'
UNION ALL SELECT id, 'Battery', '5,240mAh battery', 3 FROM products WHERE slug = 'xiaomi-15'
UNION ALL SELECT id, 'Charging', '90W wired and 50W wireless', 4 FROM products WHERE slug = 'xiaomi-15'
ON CONFLICT (product_id, label) DO UPDATE SET value = EXCLUDED.value, display_order = EXCLUDED.display_order;

UPDATE product_variants AS variant
SET price_paise = CASE product.slug
  WHEN 'iphone-17-pro' THEN CASE variant.storage WHEN '512GB' THEN 14740000 ELSE 12740000 END
  WHEN 'samsung-s24-ultra' THEN CASE variant.storage WHEN '512GB' THEN 13499900 ELSE 11999900 END
  WHEN 'pixel-9-pro' THEN CASE variant.storage WHEN '256GB' THEN 10999900 ELSE 9999900 END
  WHEN 'oneplus-13' THEN CASE variant.storage WHEN '512GB' THEN 8299900 ELSE 7299900 END
  WHEN 'pixel-9a' THEN CASE variant.storage WHEN '256GB' THEN 5499900 ELSE 4999900 END
  WHEN 'xiaomi-15' THEN CASE variant.storage WHEN '512GB' THEN 7499900 ELSE 6499900 END
  ELSE product.price_paise
END,
mrp_paise = CASE product.slug
  WHEN 'iphone-17-pro' THEN CASE variant.storage WHEN '512GB' THEN 15490000 ELSE 13490000 END
  WHEN 'samsung-s24-ultra' THEN CASE variant.storage WHEN '512GB' THEN 14499900 ELSE 12999900 END
  WHEN 'pixel-9-pro' THEN CASE variant.storage WHEN '256GB' THEN 11999900 ELSE 10999900 END
  WHEN 'oneplus-13' THEN CASE variant.storage WHEN '512GB' THEN 8999900 ELSE 7999900 END
  WHEN 'pixel-9a' THEN CASE variant.storage WHEN '256GB' THEN 5999900 ELSE 5499900 END
  WHEN 'xiaomi-15' THEN CASE variant.storage WHEN '512GB' THEN 7999900 ELSE 6999900 END
  ELSE product.mrp_paise
END
FROM products AS product
WHERE product.id = variant.product_id;

-- Variant prices are seeded above, before deriving their configuration-specific EMI amounts.
INSERT INTO emi_plans (product_id, variant_id, monthly_payment_paise, tenure_months, interest_rate_bps, cashback_paise, display_order)
SELECT variant.product_id, variant.id,
       ROUND(variant.price_paise / plan.tenure_months::numeric)::integer,
       plan.tenure_months, plan.interest_rate_bps, plan.cashback_paise, plan.display_order
FROM product_variants AS variant
JOIN products AS product ON product.id = variant.product_id
CROSS JOIN (VALUES
  (3, 0, 750000, 1), (6, 0, 750000, 2), (12, 0, 750000, 3), (24, 0, 750000, 4), (36, 1050, 500000, 5)
) AS plan(tenure_months, interest_rate_bps, cashback_paise, display_order)
WHERE product.category_id = (SELECT id FROM categories WHERE slug = 'smartphones')
ON CONFLICT (variant_id, tenure_months) WHERE variant_id IS NOT NULL DO UPDATE
SET monthly_payment_paise = EXCLUDED.monthly_payment_paise, interest_rate_bps = EXCLUDED.interest_rate_bps,
    cashback_paise = EXCLUDED.cashback_paise, display_order = EXCLUDED.display_order;

-- Non-phone catalogue items are first-class products too, with the same API, variants and EMI flow.
INSERT INTO products (slug, name, short_description, mrp_paise, price_paise, image_url, category_id) VALUES
  ('soundpeak-studio-headphones', 'SoundPeak Studio Headphones', 'Wireless over-ear listening with adaptive noise cancellation.', 2499900, 2199900, '/assets/audio-headphones-transparent.png', (SELECT id FROM categories WHERE slug = 'audio')),
  ('soundpeak-studio-max', 'SoundPeak Studio Max', 'A premium over-ear listening experience with spatial audio.', 2999900, 2699900, '/assets/soundpeak-studio-max-champagne.png', (SELECT id FROM categories WHERE slug = 'audio')),
  ('echobeam-mini-speaker', 'EchoBeam Mini Speaker', 'Compact portable sound with a rich, room-filling profile.', 1199900, 999900, '/assets/echobeam-mini-speaker.png', (SELECT id FROM categories WHERE slug = 'audio')),
  ('pulsebuds-pro', 'PulseBuds Pro', 'True wireless earbuds with immersive adaptive listening.', 1799900, 1499900, '/assets/pulsebuds-pro.png', (SELECT id FROM categories WHERE slug = 'audio')),
  ('roomtone-smart-speaker', 'RoomTone Smart Speaker', 'Balanced, voice-ready sound for your everyday space.', 1399900, 1199900, '/assets/roomtone-smart-speaker.png', (SELECT id FROM categories WHERE slug = 'audio')),
  ('orbit-fit-watch', 'Orbit Fit Watch', 'A connected everyday watch for movement, sleep and notifications.', 3299900, 2899900, '/assets/wearable-watch-transparent.png', (SELECT id FROM categories WHERE slug = 'wearables')),
  ('orbit-fit-watch-mini', 'Orbit Fit Watch Mini', 'A lightweight everyday watch for health, activity and notifications.', 2799900, 2499900, '/assets/orbit-fit-watch-mini-blue.png', (SELECT id FROM categories WHERE slug = 'wearables')),
  ('pulse-run-watch', 'Pulse Run Watch', 'A rugged training companion designed for the outdoors.', 2199900, 1899900, '/assets/pulse-run-watch.png', (SELECT id FROM categories WHERE slug = 'wearables')),
  ('halo-smart-ring', 'Halo Smart Ring', 'Discreet daily health tracking in a premium titanium finish.', 2699900, 2399900, '/assets/halo-smart-ring.png', (SELECT id FROM categories WHERE slug = 'wearables')),
  ('trackfit-band', 'TrackFit Band', 'A lightweight fitness tracker for every day and every workout.', 899900, 749900, '/assets/trackfit-band.png', (SELECT id FROM categories WHERE slug = 'wearables'))
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name, short_description = EXCLUDED.short_description, mrp_paise = EXCLUDED.mrp_paise,
  price_paise = EXCLUDED.price_paise, image_url = EXCLUDED.image_url, category_id = EXCLUDED.category_id;

INSERT INTO product_variants (product_id, label, ram, storage, configuration_label, color_hex, image_url, mrp_paise, price_paise, display_order)
SELECT id, 'Midnight', 'Bluetooth 5.4', 'Standard', 'Bluetooth 5.4 + adaptive ANC', '#202124', '/assets/audio-headphones-transparent.png', 2499900, 2199900, 1 FROM products WHERE slug = 'soundpeak-studio-headphones'
UNION ALL SELECT id, 'Forest', 'Bluetooth 5.4', 'Standard', 'Bluetooth 5.4 + adaptive ANC', '#183d31', '/assets/soundpeak-studio-headphones-forest.png', 2499900, 2199900, 2 FROM products WHERE slug = 'soundpeak-studio-headphones'
UNION ALL SELECT id, 'Champagne', 'Bluetooth 5.4', 'Standard', 'Bluetooth 5.4 + spatial audio', '#c9bba5', '/assets/soundpeak-studio-max-champagne.png', 2999900, 2699900, 1 FROM products WHERE slug = 'soundpeak-studio-max'
UNION ALL SELECT id, 'Champagne', 'Bluetooth 5.4', 'Standard', 'Bluetooth 5.4 + spatial audio', '#c9bba5', '/assets/echobeam-mini-speaker.png', 1199900, 999900, 1 FROM products WHERE slug = 'echobeam-mini-speaker'
UNION ALL SELECT id, 'Graphite', 'Bluetooth 5.4', 'Standard', 'Bluetooth 5.4 + adaptive ANC', '#30343a', '/assets/pulsebuds-pro.png', 1799900, 1499900, 1 FROM products WHERE slug = 'pulsebuds-pro'
UNION ALL SELECT id, 'Stone', 'Wi-Fi + Bluetooth', 'Standard', 'Wi-Fi + Bluetooth smart audio', '#958a7d', '/assets/roomtone-smart-speaker.png', 1399900, 1199900, 1 FROM products WHERE slug = 'roomtone-smart-speaker'
UNION ALL SELECT id, 'Graphite', 'GPS + Bluetooth', '42mm', '42mm · GPS + Bluetooth', '#262b2e', '/assets/wearable-watch-transparent.png', 3299900, 2899900, 1 FROM products WHERE slug = 'orbit-fit-watch'
UNION ALL SELECT id, 'Forest', 'GPS + Bluetooth', '46mm', '46mm · GPS + Bluetooth', '#244b3d', '/assets/wearable-watch-transparent.png', 3699900, 3299900, 2 FROM products WHERE slug = 'orbit-fit-watch'
UNION ALL SELECT id, 'Sky', 'GPS + Bluetooth', '40mm', '40mm · GPS + Bluetooth', '#b9d5ef', '/assets/orbit-fit-watch-mini-blue.png', 2799900, 2499900, 1 FROM products WHERE slug = 'orbit-fit-watch-mini'
UNION ALL SELECT id, 'Signal Orange', 'GPS + Bluetooth', '46mm', '46mm · GPS + Bluetooth', '#fb641d', '/assets/pulse-run-watch.png', 2199900, 1899900, 1 FROM products WHERE slug = 'pulse-run-watch'
UNION ALL SELECT id, 'Titanium', 'Health sensors', 'Size 9', 'Size 9 · Health sensors', '#8b8883', '/assets/halo-smart-ring.png', 2699900, 2399900, 1 FROM products WHERE slug = 'halo-smart-ring'
UNION ALL SELECT id, 'Graphite', 'Bluetooth 5.4', 'Standard', 'Bluetooth 5.4 fitness tracking', '#262b2e', '/assets/trackfit-band.png', 899900, 749900, 1 FROM products WHERE slug = 'trackfit-band'
ON CONFLICT (product_id, label, storage) DO UPDATE SET
  ram = EXCLUDED.ram, configuration_label = EXCLUDED.configuration_label, color_hex = EXCLUDED.color_hex,
  image_url = EXCLUDED.image_url, mrp_paise = EXCLUDED.mrp_paise, price_paise = EXCLUDED.price_paise, display_order = EXCLUDED.display_order;

-- Earlier seed iterations used different finishes for these two items. Keep the
-- current catalogue images and options in sync after a repeatable migration.
DELETE FROM product_variants AS variant
USING products AS product
WHERE variant.product_id = product.id
  AND ((product.slug = 'soundpeak-studio-max' AND variant.label IN ('Midnight', 'Sand'))
    OR (product.slug = 'orbit-fit-watch-mini' AND variant.label IN ('Graphite', 'Forest')));

INSERT INTO emi_plans (product_id, variant_id, monthly_payment_paise, tenure_months, interest_rate_bps, cashback_paise, display_order)
SELECT variant.product_id, variant.id, ROUND(variant.price_paise / tenure.months::numeric)::integer,
       tenure.months, tenure.interest_rate_bps, tenure.cashback_paise, tenure.display_order
FROM product_variants AS variant
JOIN products AS product ON product.id = variant.product_id
CROSS JOIN (VALUES (3, 0, 150000, 1), (6, 0, 150000, 2), (12, 0, 150000, 3), (24, 1050, 100000, 4))
  AS tenure(months, interest_rate_bps, cashback_paise, display_order)
WHERE product.slug IN ('soundpeak-studio-headphones', 'soundpeak-studio-max', 'echobeam-mini-speaker', 'pulsebuds-pro', 'roomtone-smart-speaker', 'orbit-fit-watch', 'orbit-fit-watch-mini', 'pulse-run-watch', 'halo-smart-ring', 'trackfit-band')
ON CONFLICT (variant_id, tenure_months) WHERE variant_id IS NOT NULL DO UPDATE SET
  monthly_payment_paise = EXCLUDED.monthly_payment_paise, interest_rate_bps = EXCLUDED.interest_rate_bps,
  cashback_paise = EXCLUDED.cashback_paise, display_order = EXCLUDED.display_order;

INSERT INTO product_specifications (product_id, label, value, display_order)
SELECT id, 'Audio', '40mm custom dynamic drivers', 1 FROM products WHERE slug = 'soundpeak-studio-headphones'
UNION ALL SELECT id, 'Noise control', 'Adaptive active noise cancellation', 2 FROM products WHERE slug = 'soundpeak-studio-headphones'
UNION ALL SELECT id, 'Battery', 'Up to 38 hours of listening', 3 FROM products WHERE slug = 'soundpeak-studio-headphones'
UNION ALL SELECT id, 'Connectivity', 'Bluetooth 5.4 multipoint', 4 FROM products WHERE slug = 'soundpeak-studio-headphones'
UNION ALL SELECT id, 'Audio', '40mm low-distortion drivers', 1 FROM products WHERE slug = 'soundpeak-studio-max'
UNION ALL SELECT id, 'Spatial audio', 'Personalised immersive listening', 2 FROM products WHERE slug = 'soundpeak-studio-max'
UNION ALL SELECT id, 'Battery', 'Up to 45 hours of listening', 3 FROM products WHERE slug = 'soundpeak-studio-max'
UNION ALL SELECT id, 'Connectivity', 'Bluetooth 5.4 multipoint', 4 FROM products WHERE slug = 'soundpeak-studio-max'
UNION ALL SELECT id, 'Audio', '45mm full-range driver', 1 FROM products WHERE slug = 'echobeam-mini-speaker'
UNION ALL SELECT id, 'Battery', 'Up to 18 hours of playback', 2 FROM products WHERE slug = 'echobeam-mini-speaker'
UNION ALL SELECT id, 'Protection', 'IP67 water and dust resistance', 3 FROM products WHERE slug = 'echobeam-mini-speaker'
UNION ALL SELECT id, 'Connectivity', 'Bluetooth 5.4', 4 FROM products WHERE slug = 'echobeam-mini-speaker'
UNION ALL SELECT id, 'Audio', 'Dual dynamic acoustic drivers', 1 FROM products WHERE slug = 'pulsebuds-pro'
UNION ALL SELECT id, 'Noise control', 'Adaptive active noise cancellation', 2 FROM products WHERE slug = 'pulsebuds-pro'
UNION ALL SELECT id, 'Battery', 'Up to 30 hours with case', 3 FROM products WHERE slug = 'pulsebuds-pro'
UNION ALL SELECT id, 'Connectivity', 'Bluetooth 5.4 multipoint', 4 FROM products WHERE slug = 'pulsebuds-pro'
UNION ALL SELECT id, 'Audio', '360-degree room-filling sound', 1 FROM products WHERE slug = 'roomtone-smart-speaker'
UNION ALL SELECT id, 'Control', 'Voice-ready touch controls', 2 FROM products WHERE slug = 'roomtone-smart-speaker'
UNION ALL SELECT id, 'Connectivity', 'Wi-Fi 6 and Bluetooth 5.4', 3 FROM products WHERE slug = 'roomtone-smart-speaker'
UNION ALL SELECT id, 'Finish', 'Recycled woven fabric', 4 FROM products WHERE slug = 'roomtone-smart-speaker'
UNION ALL SELECT id, 'Display', '1.8-inch always-on AMOLED', 1 FROM products WHERE slug = 'orbit-fit-watch'
UNION ALL SELECT id, 'Health', 'Heart rate, sleep and workout tracking', 2 FROM products WHERE slug = 'orbit-fit-watch'
UNION ALL SELECT id, 'Battery', 'Up to 36 hours', 3 FROM products WHERE slug = 'orbit-fit-watch'
UNION ALL SELECT id, 'Protection', '5ATM water resistance', 4 FROM products WHERE slug = 'orbit-fit-watch'
UNION ALL SELECT id, 'Display', '1.6-inch always-on AMOLED', 1 FROM products WHERE slug = 'orbit-fit-watch-mini'
UNION ALL SELECT id, 'Health', 'Heart rate, sleep and workout tracking', 2 FROM products WHERE slug = 'orbit-fit-watch-mini'
UNION ALL SELECT id, 'Battery', 'Up to 30 hours', 3 FROM products WHERE slug = 'orbit-fit-watch-mini'
UNION ALL SELECT id, 'Protection', '5ATM water resistance', 4 FROM products WHERE slug = 'orbit-fit-watch-mini'
UNION ALL SELECT id, 'Display', '1.43-inch transflective AMOLED', 1 FROM products WHERE slug = 'pulse-run-watch'
UNION ALL SELECT id, 'Training', 'Multi-band GPS and recovery insights', 2 FROM products WHERE slug = 'pulse-run-watch'
UNION ALL SELECT id, 'Battery', 'Up to 14 days', 3 FROM products WHERE slug = 'pulse-run-watch'
UNION ALL SELECT id, 'Protection', '10ATM water resistance', 4 FROM products WHERE slug = 'pulse-run-watch'
UNION ALL SELECT id, 'Sensors', 'Heart rate, skin temperature and sleep', 1 FROM products WHERE slug = 'halo-smart-ring'
UNION ALL SELECT id, 'Material', 'Hypoallergenic titanium', 2 FROM products WHERE slug = 'halo-smart-ring'
UNION ALL SELECT id, 'Battery', 'Up to 6 days', 3 FROM products WHERE slug = 'halo-smart-ring'
UNION ALL SELECT id, 'Protection', '10ATM water resistance', 4 FROM products WHERE slug = 'halo-smart-ring'
UNION ALL SELECT id, 'Display', '1.62-inch AMOLED', 1 FROM products WHERE slug = 'trackfit-band'
UNION ALL SELECT id, 'Health', 'All-day activity and sleep tracking', 2 FROM products WHERE slug = 'trackfit-band'
UNION ALL SELECT id, 'Battery', 'Up to 12 days', 3 FROM products WHERE slug = 'trackfit-band'
UNION ALL SELECT id, 'Protection', '5ATM water resistance', 4 FROM products WHERE slug = 'trackfit-band'
ON CONFLICT (product_id, label) DO UPDATE SET value = EXCLUDED.value, display_order = EXCLUDED.display_order;

UPDATE product_variants
SET configuration_label = ram || ' RAM + ' || storage
WHERE configuration_label = '';

-- Asset-specific presentation scaling is data, not a frontend product exception.
UPDATE products
SET image_scale = CASE slug
  WHEN 'iphone-17-pro' THEN 0.98
  WHEN 'samsung-s24-ultra' THEN 0.92
  WHEN 'pixel-9-pro' THEN 0.92
  WHEN 'oneplus-13' THEN 1.16
  WHEN 'pixel-9a' THEN 1.10
  WHEN 'xiaomi-15' THEN 1.05
  WHEN 'soundpeak-studio-headphones' THEN 0.92
  WHEN 'soundpeak-studio-max' THEN 0.90
  WHEN 'echobeam-mini-speaker' THEN 0.84
  WHEN 'pulsebuds-pro' THEN 0.86
  WHEN 'roomtone-smart-speaker' THEN 0.84
  WHEN 'orbit-fit-watch' THEN 0.92
  WHEN 'orbit-fit-watch-mini' THEN 0.90
  WHEN 'pulse-run-watch' THEN 0.90
  WHEN 'halo-smart-ring' THEN 0.82
  WHEN 'trackfit-band' THEN 0.86
  ELSE 1.00
END;
