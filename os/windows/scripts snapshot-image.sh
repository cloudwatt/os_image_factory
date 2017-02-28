glance image-download b159ae3a-3863-4ad6-9077-7d75401d6176 --file "/d/work/Windows Server 2008 R2 FR (Oct 2016).qcow2" --progress
glance image-download f4ea78d1-733d-43fe-b4f4-3464ac27380d --file "/d/work/Windows Server 2008 R2 EN (Oct 2016).qcow2" --progress
glance image-download 547ee930-7e7d-415f-a947-3782abff1385 --file "/d/work/Windows Server 2012 R2 FR (Oct 2016).qcow2"
glance image-download f85d3783-3ef2-41af-ae08-38a7b24b2576 --file "/d/work/Windows Server 2012 R2 EN (Oct 2016).qcow2" --progress

glance image-create --name "Windows Server 2008 R2 Enterprise EN" --file "/d/work/Windows Server 2008 R2 EN (Oct 2016).qcow2" --disk-format qcow2 --container-format bare
glance image-create --name "Windows Server 2008 R2 Enterprise FR" --file "/d/work/Windows Server 2008 R2 FR (Oct 2016).qcow2" --disk-format qcow2 --container-format bare
glance image-create --name "Windows Server 2012 R2 Standard EN" --file "/d/work/Windows Server 2012 R2 EN (Oct 2016).qcow2" --disk-format qcow2 --container-format bare
glance image-create --name "Windows Server 2012 R2 Standard FR" --file "/d/work/Windows Server 2012 R2 FR (Oct 2016).qcow2" --disk-format qcow2 --container-format bare
