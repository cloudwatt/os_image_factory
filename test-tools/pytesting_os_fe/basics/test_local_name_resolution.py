from basics import test_resources
import openstackutils


cwlib = openstackutils.OpenStackUtils()



def test_local_name_resolution():
    global test_resources
    ssh_stdin, ssh_stdout, ssh_stderr = test_resources['ssh_connection'].exec_command('sudo ls 2>&1')
    ssh_local_name_resolution = ssh_stdout.read()
    validate_local_resolution = (ssh_local_name_resolution.find('unable to resolve host') == -1)

    assert validate_local_resolution
