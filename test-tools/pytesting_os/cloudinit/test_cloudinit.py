from cloudinit import test_resources
import openstackutils
import time

cwlib = openstackutils.OpenStackUtils()

global test_resources

def test_cloudinit_package():

    time.sleep(20)
    print test_resources['my_floating']
    ssh_stdin, ssh_stdout, ssh_stderr = test_resources['ssh_connection'].exec_command('emacs --version')
    cmd_stdout = ssh_stdout.read()
    package_installed_by_userdata_is_present = (cmd_stdout.find('GNU Emacs') != -1)

    print("Expecting to find 'GNU Emacs' in:\n" + cmd_stdout)

    assert package_installed_by_userdata_is_present


def test_cloudinit_runcmd():
    print test_resources['my_floating']
    time.sleep(20)
    ssh_stdin, ssh_stdout, ssh_stderr = test_resources['ssh_connection'].exec_command('sudo ls /root')
    cmd_stdout= ssh_stdout.read()
    print cmd_stdout
    file_created_by_userdata_is_present = (cmd_stdout.find('cloud-init.txt') !=-1)
    print file_created_by_userdata_is_present
    assert file_created_by_userdata_is_present

