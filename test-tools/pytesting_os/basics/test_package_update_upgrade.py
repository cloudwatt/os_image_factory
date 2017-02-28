from basics import test_resources
import openstackutils


cwlib = openstackutils.OpenStackUtils()


def test_package_update_upgrade():
    global test_resources
    ssh_stdin, ssh_stdout, ssh_stderr = test_resources['ssh_connection'].exec_command('cat /etc/cloud/cloud.cfg')
    ssh_update_upgrade = ssh_stdout.read()
    update_upgrade_result = (ssh_update_upgrade.find('update-upgrade') != -1)

    assert update_upgrade_result
