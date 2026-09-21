INSERT INTO restaurants (name, address, rating) VALUES
    ('Pho Thin',       '13 Lo Duc, Ha Noi',        4.5),
    ('Bun Cha Huong Lien', '24 Le Van Huu, Ha Noi', 4.7),
    ('Com Tam Ba Ghien',   '84 Dang Van Ngu, TPHCM', 4.3)
ON CONFLICT (name) DO NOTHING;
