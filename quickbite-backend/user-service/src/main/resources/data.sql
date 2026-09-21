-- Du lieu mau de demo. ON CONFLICT DO NOTHING => khoi dong lai khong bi trung khoa.
INSERT INTO users (full_name, email) VALUES
    ('Nguyen Van An',  'an.nguyen@quickbite.vn'),
    ('Tran Thi Binh',  'binh.tran@quickbite.vn'),
    ('Le Hoang Cuong', 'cuong.le@quickbite.vn')
ON CONFLICT (email) DO NOTHING;
