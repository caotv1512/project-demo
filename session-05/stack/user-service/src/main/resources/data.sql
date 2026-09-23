INSERT INTO users (full_name, email, wallet_balance) VALUES
    ('Nguyen Van An',  'an.nguyen@quickbite.vn',  500000),
    ('Tran Thi Binh',  'binh.tran@quickbite.vn',  120000),
    ('Le Hoang Cuong', 'cuong.le@quickbite.vn',    30000)
ON CONFLICT (email) DO NOTHING;
