package com.quickbite.user;

/**
 * Quy tac nghiep vu cua vi tien - THUAN JAVA, khong phu thuoc Spring hay database.
 * Nho vay unit test chay duoc tren CI trong vai giay, khong can dung PostgreSQL.
 */
public final class WalletRules {

    /** So du toi thieu phai giu lai trong vi (dong). */
    public static final long SO_DU_TOI_THIEU = 0L;

    private WalletRules() { }

    /** Kiem tra vi co du tien de tru khong. */
    public static boolean duTienDeTru(long soDuHienTai, long soTienCanTru) {
        if (soTienCanTru <= 0) {
            throw new IllegalArgumentException("So tien can tru phai lon hon 0");
        }
        return soDuHienTai - soTienCanTru >= SO_DU_TOI_THIEU;
    }

    /** Tinh so du sau khi tru. Nem loi neu khong du tien. */
    public static long soDuSauKhiTru(long soDuHienTai, long soTienCanTru) {
        if (!duTienDeTru(soDuHienTai, soTienCanTru)) {
            throw new IllegalStateException(
                "So du khong du: co " + soDuHienTai + ", can " + soTienCanTru);
        }
        return soDuHienTai - soTienCanTru;
    }
}
