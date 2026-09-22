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

-- ============================================================================
-- Batch 2 (2026-09-18): East/Central London venues + Love Hackney aggregator
-- Coordinates are best-effort; verify pins on the map. Crawl URLs are best-guess;
-- a source that returns 0 events likely needs its listing URL corrected.
-- ============================================================================

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Mildmay Club', 'https://mildmay.club', 'Members'' club and events venue, Newington Green', 4, 'primary', '🎭'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Mildmay Club');
SET @w := (SELECT id FROM websites WHERE name = 'Mildmay Club' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.tickettailor.com/events/mildmayclubandinstituteltd', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.tickettailor.com/events/mildmayclubandinstituteltd');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Mildmay Club', 'Mildmay Club', '34 Newington Green, London N16 9PR', 51.5526, -0.0863, '🎭'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Mildmay Club');
SET @l := (SELECT id FROM locations WHERE name = 'Mildmay Club' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Dalston Curve Garden', 'https://dalstongarden.org', 'Community garden with events, Dalston', 4, 'primary', '🌿'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Dalston Curve Garden');
SET @w := (SELECT id FROM websites WHERE name = 'Dalston Curve Garden' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://dalstongarden.org/whats-on', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://dalstongarden.org/whats-on');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Dalston Curve Garden', 'Dalston Curve Garden', '13 Dalston Lane, London E8 3DF', 51.5466, -0.0748, '🌿'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Dalston Curve Garden');
SET @l := (SELECT id FROM locations WHERE name = 'Dalston Curve Garden' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Bethnal Green Working Men''s Club', 'https://www.workersplaytime.net', 'Cabaret and events club (BGWMC)', 4, 'primary', '🎭'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Bethnal Green Working Men''s Club');
SET @w := (SELECT id FROM websites WHERE name = 'Bethnal Green Working Men''s Club' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.workersplaytime.net', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.workersplaytime.net');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Bethnal Green Working Men''s Club', 'Bethnal Green Working Men''s Club', '42-44 Pollard Row, London E2 6NB', 51.5266, -0.0655, '🎭'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Bethnal Green Working Men''s Club');
SET @l := (SELECT id FROM locations WHERE name = 'Bethnal Green Working Men''s Club' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Moth Club', 'https://mothclub.co.uk', 'Music and events venue, Hackney', 4, 'primary', '🎸'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Moth Club');
SET @w := (SELECT id FROM websites WHERE name = 'Moth Club' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.songkick.com/venues/3062884-moth-club/calendar', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.songkick.com/venues/3062884-moth-club/calendar');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Moth Club', 'Moth Club', 'Old Trades Hall, Valette St, London E9 6NU', 51.5442, -0.0555, '🎸'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Moth Club');
SET @l := (SELECT id FROM locations WHERE name = 'Moth Club' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Chats Palace', 'https://chatspalace.com', 'Community arts centre, Homerton', 4, 'primary', '🎭'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Chats Palace');
SET @w := (SELECT id FROM websites WHERE name = 'Chats Palace' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://chatspalace.com/new-events/', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://chatspalace.com/new-events/');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Chats Palace', 'Chats Palace', '42-44 Brooksby''s Walk, London E9 6DF', 51.5497, -0.0466, '🎭'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Chats Palace');
SET @l := (SELECT id FROM locations WHERE name = 'Chats Palace' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'The Castle Cinema', 'https://thecastlecinema.com', 'Independent cinema, Homerton', 4, 'primary', '🎬'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'The Castle Cinema');
SET @w := (SELECT id FROM websites WHERE name = 'The Castle Cinema' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://thecastlecinema.com/whats-on', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://thecastlecinema.com/whats-on');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'The Castle Cinema', 'The Castle Cinema', '64-66 Brooksby''s Walk, London E9 6DA', 51.5508, -0.0456, '🎬'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'The Castle Cinema');
SET @l := (SELECT id FROM locations WHERE name = 'The Castle Cinema' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Pelican House', 'https://pelicanhouse.org', 'Social centre and arts space, Bethnal Green', 4, 'primary', '✊'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Pelican House');
SET @w := (SELECT id FROM websites WHERE name = 'Pelican House' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://pelicanhouse.org/events', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://pelicanhouse.org/events');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Pelican House', 'Pelican House', '144 Cambridge Heath Rd, London E1 5QJ', 51.527, -0.0576, '✊'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Pelican House');
SET @l := (SELECT id FROM locations WHERE name = 'Pelican House' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Jazz Cafe', 'https://thejazzcafelondon.com', 'Music venue, Camden', 4, 'primary', '🎷'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Jazz Cafe');
SET @w := (SELECT id FROM websites WHERE name = 'Jazz Cafe' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://thejazzcafelondon.com/whats-on', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://thejazzcafelondon.com/whats-on');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Jazz Cafe', 'Jazz Cafe', '5 Parkway, London NW1 7PG', 51.5394, -0.1447, '🎷'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Jazz Cafe');
SET @l := (SELECT id FROM locations WHERE name = 'Jazz Cafe' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Shacklewell Arms', 'https://www.songkick.com/venues/1347121-shacklewell-arms/calendar', 'Music venue and pub, Dalston', 4, 'primary', '🎸'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Shacklewell Arms');
SET @w := (SELECT id FROM websites WHERE name = 'Shacklewell Arms' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.songkick.com/venues/1347121-shacklewell-arms/calendar', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.songkick.com/venues/1347121-shacklewell-arms/calendar');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Shacklewell Arms', 'Shacklewell Arms', '71 Shacklewell Lane, London E8 2EB', 51.5502, -0.0736, '🎸'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Shacklewell Arms');
SET @l := (SELECT id FROM locations WHERE name = 'Shacklewell Arms' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'FOLD', 'https://fold.london', 'Nightclub, Canning Town', 4, 'primary', '🔊'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'FOLD');
SET @w := (SELECT id FROM websites WHERE name = 'FOLD' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.fold.london/tickets', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.fold.london/tickets');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'FOLD', 'FOLD', 'Gillian House, Stephenson St, London E16 4SA', 51.5158, -0.002, '🔊'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'FOLD');
SET @l := (SELECT id FROM locations WHERE name = 'FOLD' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Dalston Superstore', 'https://dalstonsuperstore.com', 'LGBTQ+ bar and club, Dalston', 4, 'primary', '🪩'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Dalston Superstore');
SET @w := (SELECT id FROM websites WHERE name = 'Dalston Superstore' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://dalstonsuperstore.com/events', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://dalstonsuperstore.com/events');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Dalston Superstore', 'Dalston Superstore', '117 Kingsland High St, London E8 2PB', 51.5486, -0.0757, '🪩'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Dalston Superstore');
SET @l := (SELECT id FROM locations WHERE name = 'Dalston Superstore' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'The Bath House', 'https://thebathhouse.co', 'Cultural hub and community sauna, Hackney Wick', 4, 'primary', '🛁'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'The Bath House');
SET @w := (SELECT id FROM websites WHERE name = 'The Bath House' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://thebathhouse.co/whats-on', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://thebathhouse.co/whats-on');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'The Bath House', 'The Bath House', '80 Eastway, London E9 5JH', 51.5452, -0.033, '🛁'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'The Bath House');
SET @l := (SELECT id FROM locations WHERE name = 'The Bath House' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'The Jago', 'https://thejago.com', 'Music and events venue, Dalston', 4, 'primary', '🎶'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'The Jago');
SET @w := (SELECT id FROM websites WHERE name = 'The Jago' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.songkick.com/venues/4229084-jago-dalston/calendar', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.songkick.com/venues/4229084-jago-dalston/calendar');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'The Jago', 'The Jago', '440 Kingsland Rd, London E8 4AA', 51.5443, -0.0757, '🎶'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'The Jago');
SET @l := (SELECT id FROM locations WHERE name = 'The Jago' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'London Mithraeum', 'https://www.londonmithraeum.com', 'Roman temple museum (Bloomberg SPACE), City', 4, 'primary', '🏛️'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'London Mithraeum');
SET @w := (SELECT id FROM websites WHERE name = 'London Mithraeum' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.londonmithraeum.com/whats-on', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.londonmithraeum.com/whats-on');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'London Mithraeum', 'London Mithraeum', '12 Walbrook, London EC4N 8AA', 51.5127, -0.0902, '🏛️'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'London Mithraeum');
SET @l := (SELECT id FROM locations WHERE name = 'London Mithraeum' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'V&A East Storehouse', 'https://www.vam.ac.uk', 'Museum storehouse, Queen Elizabeth Olympic Park', 4, 'primary', '🏛️'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'V&A East Storehouse');
SET @w := (SELECT id FROM websites WHERE name = 'V&A East Storehouse' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.vam.ac.uk/whatson?venue=east-storehouse', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.vam.ac.uk/whatson?venue=east-storehouse');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'V&A East Storehouse', 'V&A East Storehouse', 'Parkes St, London E20 3AX', 51.5385, -0.0175, '🏛️'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'V&A East Storehouse');
SET @l := (SELECT id FROM locations WHERE name = 'V&A East Storehouse' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Museum of London Docklands', 'https://www.londonmuseum.org.uk', 'London Museum Docklands', 4, 'primary', '🏛️'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Museum of London Docklands');
SET @w := (SELECT id FROM websites WHERE name = 'Museum of London Docklands' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.londonmuseum.org.uk/whats-on/', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.londonmuseum.org.uk/whats-on/');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'Museum of London Docklands', 'Museum of London Docklands', 'No.1 Warehouse, West India Quay, London E14 4AL', 51.5074, -0.0235, '🏛️'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'Museum of London Docklands');
SET @l := (SELECT id FROM locations WHERE name = 'Museum of London Docklands' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'BFI Southbank', 'https://whatson.bfi.org.uk', 'Film centre and Mediatheque, Southbank', 4, 'primary', '🎬'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'BFI Southbank');
SET @w := (SELECT id FROM websites WHERE name = 'BFI Southbank' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://whatson.bfi.org.uk', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://whatson.bfi.org.uk');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'BFI Southbank', 'BFI Southbank', 'Belvedere Rd, London SE1 8XT', 51.5065, -0.1153, '🎬'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'BFI Southbank');
SET @l := (SELECT id FROM locations WHERE name = 'BFI Southbank' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'SET Social', 'https://social.setspace.uk', 'Community arts, cafe and events space (SET)', 4, 'primary', '🎨'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'SET Social');
SET @w := (SELECT id FROM websites WHERE name = 'SET Social' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://social.setspace.uk', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://social.setspace.uk');
INSERT INTO locations (name, short_name, address, lat, lng, emoji)
SELECT 'SET Social', 'SET Social', 'London SE15', 51.4725, -0.0685, '🎨'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name = 'SET Social');
SET @l := (SELECT id FROM locations WHERE name = 'SET Social' LIMIT 1);
INSERT IGNORE INTO website_locations (website_id, location_id, is_primary) VALUES (@w, @l, 1);

-- Aggregator: crawled for discovery; events resolve to their own venues (no primary location link).
INSERT INTO websites (name, base_url, description, crawl_frequency, source_type, emoji)
SELECT 'Love Hackney', 'https://www.lovehackney.uk', 'Hackney events listings aggregator', 3, 'aggregator', '📰'
WHERE NOT EXISTS (SELECT 1 FROM websites WHERE name = 'Love Hackney');
SET @w := (SELECT id FROM websites WHERE name = 'Love Hackney' LIMIT 1);
INSERT INTO website_urls (website_id, url, sort_order)
SELECT @w, 'https://www.lovehackney.uk/whats-on', 0
WHERE NOT EXISTS (SELECT 1 FROM website_urls WHERE website_id = @w AND url = 'https://www.lovehackney.uk/whats-on');
