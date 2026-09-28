package com.quickbite.user;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit test chay tren CI. KHONG dung @SpringBootTest nen khong can database,
 * chay xong trong vai giay.
 */
class WalletRulesTest {

    @Test
    @DisplayName("Du tien thi cho tru")
    void duTien() {
        assertTrue(WalletRules.duTienDeTru(500_000, 75_000));
    }

    @Test
    @DisplayName("Tru dung bang so du van hop le")
    void truHetSoDu() {
        assertTrue(WalletRules.duTienDeTru(75_000, 75_000));
    }

    @Test
    @DisplayName("Khong du tien thi tu choi")
    void khongDuTien() {
        assertFalse(WalletRules.duTienDeTru(30_000, 75_000));
    }

    @Test
    @DisplayName("Tinh dung so du con lai")
    void tinhSoDuConLai() {
        assertEquals(425_000, WalletRules.soDuSauKhiTru(500_000, 75_000));
    }

    @Test
    @DisplayName("Tru khi khong du tien phai nem loi")
    void truKhiThieuTienThiNemLoi() {
        assertThrows(IllegalStateException.class,
                () -> WalletRules.soDuSauKhiTru(30_000, 75_000));
    }

    @Test
    @DisplayName("So tien tru phai lon hon 0")
    void soTienKhongHopLe() {
        assertThrows(IllegalArgumentException.class,
                () -> WalletRules.duTienDeTru(500_000, 0));
    }
}
