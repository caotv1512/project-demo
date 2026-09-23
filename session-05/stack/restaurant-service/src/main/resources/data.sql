INSERT INTO restaurants (name, menu_item, price, is_open) VALUES
    ('Pho Thin',           'Pho bo tai lan',  75000, TRUE),
    ('Bun Cha Huong Lien', 'Bun cha dac biet', 60000, TRUE),
    ('Com Tam Ba Ghien',   'Com tam suon bi',  55000, TRUE)
ON CONFLICT (name) DO NOTHING;
