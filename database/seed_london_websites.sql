-- ============================================================================
-- Fomo London — event source seed
-- ============================================================================
-- The crawl source list lives in the DATABASE (the `websites` table), NOT in
-- config/london.yaml. This file seeds a starter set of London sources so the
-- pipeline has something to crawl on the first run.
--
-- Usage (after loading database/schema.sql into an empty `fomo` DB):
--   mysql -u root fomo < database/seed_london_websites.sql
--
-- Each source is 4 related rows:
--   1. websites            — the source itself (crawl behaviour lives here)
--   2. website_urls        — one or more listing URLs to crawl for that source
--   3. locations           — the physical venue (lat/lng drive the map pin)
--   4. website_locations   — links the source to its primary venue
--
-- IDEMPOTENT BY DESIGN: `websites.name` and `locations.name` are NOT unique in the
-- schema (only plain indexes), so this uses `INSERT ... SELECT ... WHERE NOT EXISTS`
-- rather than ON DUPLICATE KEY — safe to re-run without creating duplicate rows.
-- Fill in real lat/lng — the placeholders below are approximate and should be verified.
--
-- Column reference: see database/schema.sql (websites / locations tables).
-- Leave optional crawl-tuning columns out to accept engine defaults.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Southbank Centre
-- ----------------------------------------------------------------------------
INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Southbank Centre', 'https://www.southbankcentre.co.uk',
       'Arts complex on the South Bank (Royal Festival Hall, Hayward Gallery)', 3, 'primary', '🎶'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Southbank Centre');
SET @w := (SELECT id FROM websites WHERE name = 'Southbank Centre' LIMIT 1);

INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.southbankcentre.co.uk/whats-on', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.southbankcentre.co.uk/whats-on');

INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Southbank Centre', 'Southbank Centre', 'Belvedere Rd, London SE1 8XX', 51.5057, -0.1160, '🎶'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Southbank Centre');
SET @l := (SELECT id FROM locations WHERE name = 'Southbank Centre' LIMIT 1);

INSERT IGNORE INTO website_locations (website_id, location_id, is_primary)
VALUES (@w, @l, 1);

-- ----------------------------------------------------------------------------
-- Barbican Centre
-- ----------------------------------------------------------------------------
INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Barbican Centre', 'https://www.barbican.org.uk',
       'Performing arts centre in the City of London', 3, 'primary', '🎭'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Barbican Centre');
SET @w := (SELECT id FROM websites WHERE name = 'Barbican Centre' LIMIT 1);

INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.barbican.org.uk/whats-on', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.barbican.org.uk/whats-on');

INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Barbican Centre', 'Barbican', 'Silk St, London EC2Y 8DS', 51.5200, -0.0937, '🎭'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Barbican Centre');
SET @l := (SELECT id FROM locations WHERE name = 'Barbican Centre' LIMIT 1);

INSERT IGNORE INTO website_locations (website_id, location_id, is_primary)
VALUES (@w, @l, 1);

-- ----------------------------------------------------------------------------
-- Roundhouse
-- ----------------------------------------------------------------------------
INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Roundhouse', 'https://www.roundhouse.org.uk',
       'Music and performing arts venue in Camden', 4, 'primary', '🎤'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Roundhouse');
SET @w := (SELECT id FROM websites WHERE name = 'Roundhouse' LIMIT 1);

INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.roundhouse.org.uk/whats-on/', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.roundhouse.org.uk/whats-on/');

INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Roundhouse', 'Roundhouse', 'Chalk Farm Rd, London NW1 8EH', 51.5436, -0.1522, '🎤'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Roundhouse');
SET @l := (SELECT id FROM locations WHERE name = 'Roundhouse' LIMIT 1);

INSERT IGNORE INTO website_locations (website_id, location_id, is_primary)
VALUES (@w, @l, 1);

-- ----------------------------------------------------------------------------
-- Tate Modern
-- ----------------------------------------------------------------------------
INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Tate Modern', 'https://www.tate.org.uk',
       'Modern and contemporary art gallery on Bankside', 5, 'primary', '🖼️'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Tate Modern');
SET @w := (SELECT id FROM websites WHERE name = 'Tate Modern' LIMIT 1);

INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.tate.org.uk/whats-on?gallery=tate-modern', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.tate.org.uk/whats-on?gallery=tate-modern');

INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Tate Modern', 'Tate Modern', 'Bankside, London SE1 9TG', 51.5076, -0.0994, '🖼️'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Tate Modern');
SET @l := (SELECT id FROM locations WHERE name = 'Tate Modern' LIMIT 1);

INSERT IGNORE INTO website_locations (website_id, location_id, is_primary)
VALUES (@w, @l, 1);

-- ----------------------------------------------------------------------------
-- TEMPLATE — copy this block for each new source, replacing <placeholders>
-- ----------------------------------------------------------------------------
-- INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
-- SELECT '<Venue Name>', 'https://<domain>', '<one-line description>', 4, 'primary', '📍'
-- WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = '<Venue Name>');
-- SET @w := (SELECT id FROM websites WHERE name = '<Venue Name>' LIMIT 1);
--
-- INSERT INTO website_urls (website_id, url, sort_order)
-- SELECT @w, 'https://<domain>/whats-on', 0
-- WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://<domain>/whats-on');
--
-- INSERT INTO locations (name, short_name, address, lat, lng, emoji)
-- SELECT '<Venue Name>', '<Short Name>', '<address, London POSTCODE>', <lat>, <lng>, '📍'
-- WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = '<Venue Name>');
-- SET @l := (SELECT id FROM locations WHERE name = '<Venue Name>' LIMIT 1);
--
-- INSERT IGNORE INTO website_locations (website_id, location_id, is_primary)
-- VALUES (@w, @l, 1);
