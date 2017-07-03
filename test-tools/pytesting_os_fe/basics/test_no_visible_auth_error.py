from basics import test_resources
import openstackutils


cwlib = openstackutils.OpenStackUtils()

def test_no_visible_auth_error():
    global test_resources
    ssh_stdin, ssh_stdout, ssh_stderr = test_resources['ssh_connection'].exec_command('cat /var/log/auth.log')
    auth_error = ssh_stdout.read()
    ssh_auth_error = (auth_error.find('error') == -1)

    assert ssh_auth_error
