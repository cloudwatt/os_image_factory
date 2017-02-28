import openstackutils,time
from basics import test_resources
from dateutil.parser import parse as parse_date


cwlib = openstackutils.OpenStackUtils()
global test_resources

def test_hard_reboot():
    last_boot_before_reboot = get_last_boot_date()

    print last_boot_before_reboot

    cwlib.server_reboot(test_resources['my_server'],'HARD')

    last_boot_after_reboot = get_last_boot_date()
    time.sleep(10)

    print last_boot_after_reboot

    assert last_boot_before_reboot < last_boot_after_reboot


def test_soft_reboot():

    last_boot_before_reboot = get_last_boot_date()

    print last_boot_before_reboot

    cwlib.server_reboot_reboot(test_resources['my_server'],'SOFT')

    time.sleep(10)

    last_boot_after_reboot = get_last_boot_date()

    print last_boot_after_reboot

    assert last_boot_before_reboot < last_boot_after_reboot


def get_last_boot_date():
    ssh_stdin, ssh_stdout, ssh_stderr = test_resources['ssh_connection'].exec_command(
        'who -b | tr -s " " | cut -d" " -f4,5')
    return parse_date(ssh_stdout.read())
