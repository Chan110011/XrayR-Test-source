from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "XrayR.sh"


def test_bbr_menu_is_embedded_and_not_remote_runner():
    text = SCRIPT.read_text(encoding="utf-8")

    assert "bbr_menu()" in text
    assert "show_bbr_status()" in text
    assert "enable_bbr()" in text
    assert "disable_bbr()" in text
    assert "net.ipv4.tcp_congestion_control=bbr" in text
    assert "/etc/sysctl.d/99-xrayr-bbr.conf" in text

    install_bbr_body = text.split("install_bbr()", 1)[1].split("\n}", 1)[0]
    assert "curl" not in install_bbr_body
    assert "wget" not in install_bbr_body
    assert "bbr_menu" in install_bbr_body


if __name__ == "__main__":
    test_bbr_menu_is_embedded_and_not_remote_runner()
    print("ok")
