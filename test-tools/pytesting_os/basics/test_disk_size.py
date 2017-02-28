from os import environ as env
from basics import test_resources
import openstackutils


cwlib = openstackutils.OpenStackUtils()

def test_disk_size():
    global test_resources
    expected_disk_size = str(cwlib.get_flavor_disk_size(env['NOSE_FLAVOR'])).strip()
    ssh_stdin, ssh_stdout, ssh_stderr = test_resources['ssh_connection'].exec_command(
        'lsblk | grep vda1 | awk \'{$1=" "; print $4}\'| tr -d "G"')

    actual_disk_size = str(ssh_stdout.read()).strip()

    print("EXPECTED '" + str(expected_disk_size) + "' vs ACTUAL '" + str(actual_disk_size)+"'")

    assert expected_disk_size == actual_disk_size