#
# Ce script est dépendant du repository windows-openstack-imaging-tools-master
# Une copie complete du repository est maintenue (pas de référence type sous-module)
# Note: windows-openstack-imaging-tools-master a un autre sous-module (windows-curtin-hooks\curtin), mais qui ne sera pas utilisé dans cette génération
# 
# AVANT : COPIER CE SCRIPT A LA BASE DU DOSSIER DE TRAVAIL
#
# Assume le repertoire courant étant celui où se trouve le script

$crtDir = Get-Location # "D:\work2012r2"

$installUpdates = $true


$outBaseDir = "$crtDir\out"
$isoPath = "D:\ISOs"
$virtIOISOPath = "$isoPath\virtio-win-0.1.102.iso"

$relativePathToImagingTools = "cloudwatt-base-image-factory\images\windows\windows-openstack-imaging-tools"


# Bloc de paramètres à décommenter selon le type d'image ciblée

# 2012R2 EN
#$mainIso = "$isoPath\2012R2\SW_DVD9_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_English_-4_MLF_X19-82891.ISO"
#$imageIndex = 1
#$virtualDiskPath = "$outBaseDir\winimage2012r2-EN.qcow2"
#$unattendSourceFile = "UnattendTemplate-EN.xml"

#2012R2 FR
#$mainIso = "$isoPath\2012R2\SW_DVD9_Windows_Svr_Std_and_DataCtr_2012_R2_64Bit_French_-4_MLF_X19-82899.ISO"
#$imageIndex = 1
#$virtualDiskPath = "$outBaseDir\winimage2012r2-FR.qcow2"
#$unattendSourceFile = "UnattendTemplate-FR.xml"


#2008R2 EN
#$mainIso = "$isoPath\2008R2\SW_DVD5_Windows_Svr_DC_EE_SE_Web_2008_R2_64Bit_English_w_SP1_MLF_X17-22580.ISO"
#$imageIndex = 2
#$virtualDiskPath = "$outBaseDir\winimage2008r2-EN.qcow2"
#$unattendSourceFile = "UnattendTemplate-EN.xml"

#2008R2 FR
#$mainIso = "$isoPath\2008R2\SW_DVD5_Windows_Svr_DC_EE_SE_Web_2008_R2_64Bit_French_w_SP1_MLF_X17-22584.ISO"
#$imageIndex = 2
#$virtualDiskPath = "$outBaseDir\winimage2008r2-FR.qcow2"
#$unattendSourceFile = "UnattendTemplate-FR.xml"


if ((Get-DiskImage -ImagePath $mainIso | Get-Volume) -eq $null)
{
    Mount-DiskImage -imagepath $mainIso
}
$isoCdDrive = (get-diskimage $mainIso | Get-Volume).DriveLetter
$wimFilePath = "${isoCdDrive}:\sources\install.wim"  


cd $crtDir

if (!(Test-Path $outBaseDir))
{ 
    mkdir $outBaseDir
}

if (Test-Path $virtualDiskPath)
{ 
    rm $virtualDiskPath -Force
}



cd $relativePathToImagingTools

cp $unattendSourceFile UnattendTemplate.xml -Force

Import-Module .\WinImageBuilder.psm1

$images = Get-WimFileImagesInfo -WimFilePath $wimFilePath
$image = $images[$imageIndex]
echo "The image selected form the ISO is the following:"
$image

# The product key is optional
#$productKey = “xxxxx-xxxxx…"
#no product key needed in our case, the ISOs are already VL and language ready

# Add -InstallUpdates for the Windows updates (it takes longer and requires
# more space but it's highly recommended)
#New-WindowsCloudImage -WimFilePath $wimFilePath -ImageName $image.ImageName `
#-VirtualDiskFormat QCow2 -VirtualDiskPath $virtualDiskPath `
#-SizeBytes 16GB -ProductKey $productKey -VirtIOISOPath $virtIOISOPath

#New-WindowsCloudImage -WimFilePath $wimFilePath -ImageName $image.ImageName `
#-VirtualDiskFormat QCow2 -VirtualDiskPath $virtualDiskPath `
#-SizeBytes 20GB -VirtIOISOPath $virtIOISOPath -InstallUpdates

# The disk format can be: VHD, VHDX, QCow2, VMDK or RAW
New-WindowsCloudImage -WimFilePath $wimFilePath -ImageName $image.ImageName `
    -VirtualDiskFormat QCow2 -VirtualDiskPath $virtualDiskPath `
    -SizeBytes 20GB -VirtIOISOPath $virtIOISOPath -InstallUpdates:$installUpdates

Dismount-DiskImage -ImagePath $mainIso
