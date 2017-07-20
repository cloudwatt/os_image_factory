from basics import test_resources
import openstackutils

cwlib = openstackutils.OpenStackUtils()


def test_dns_resolver():
    global test_resources

    hostname = test_resources['my_server'].name
    ssh_stdin, ssh_stdout, ssh_stderr = test_resources['ssh_connection'].exec_command(
        'time host -t A ' + hostname + ' 2>&1')
    dns_resolver = ssh_stdout.read()
    ssh_resolver_found = (dns_resolver.find('Host ' + dns_resolver + ' not found') == -1)

    assert ssh_resolver_found
