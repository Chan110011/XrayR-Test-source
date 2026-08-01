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


def test_bbr_support_check_loads_kernel_module_before_detecting_bbr():
    text = SCRIPT.read_text(encoding="utf-8")
    support_check = text.split("check_bbr_supported()", 1)[1].split("\n}", 1)[0]

    assert "modprobe tcp_bbr" in support_check
    assert support_check.index("modprobe tcp_bbr") < support_check.index(
        "grep -qw \"bbr\""
    )


if __name__ == "__main__":
    test_bbr_menu_is_embedded_and_not_remote_runner()
    test_bbr_support_check_loads_kernel_module_before_detecting_bbr()
    print("ok")
