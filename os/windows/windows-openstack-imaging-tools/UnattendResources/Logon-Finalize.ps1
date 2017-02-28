$ErrorActionPreference = "Stop"
$resourcesDir = "$ENV:SystemDrive\UnattendResources"
$configIniPath = "$resourcesDir\config.ini"
#MODIF: moved here for simplicity
$programFilesDir = $ENV:ProgramFiles
#END MODIF 

function Set-PersistDrivers {
    Param(
    [parameter(Mandatory=$true)]
    [string]$Path,
    [switch]$Persist=$true
    )
    if (!(Test-Path $Path)){
        return $false
    }
    try {
        $xml = [xml](Get-Content $Path)
    }catch{
        Write-Error "Failed to load $Path"
        return $false
    }
    if (!$xml.unattend.settings){
        return $false
    }
    foreach ($i in $xml.unattend.settings) {
        if ($i.pass -eq "generalize"){
            $index = [array]::IndexOf($xml.unattend.settings, $i)
            if ($xml.unattend.settings[$index].component -and $xml.unattend.settings[$index].component.PersistAllDeviceInstalls -ne $Persist.ToString()){
                $xml.unattend.settings[$index].component.PersistAllDeviceInstalls = $Persist.ToString()
            }
        }
    }
    $xml.Save($Path)
}

function Clean-UpdateResources {
    $HOST.UI.RawUI.WindowTitle = "Running update resources cleanup"
    # We're done, disable AutoLogon
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name Unattend*
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoLogonCount

    # Cleanup
    Remove-Item -Recurse -Force $resourcesDir
    Remove-Item -Force "$ENV:SystemDrive\Unattend.xml"

}

function Clean-WindowsUpdates {
    $HOST.UI.RawUI.WindowTitle = "Running Dism cleanup..."
    if (([System.Environment]::OSVersion.Version.Major -gt 6) -or ([System.Environment]::OSVersion.Version.Minor -ge 2))
    {
        Dism.exe /Online /Cleanup-Image /StartComponentCleanup
        if ($LASTEXITCODE)
        {
            throw "Dism.exe clean failed"
        }
    }
}

function Run-Defragment {
    $HOST.UI.RawUI.WindowTitle = "Running Defrag..."
    #Defragmenting all drives at normal priority
    defrag.exe /C /H /V
    if ($LASTEXITCODE)
    {
        throw "Defrag.exe failed"
    }
}

function Release-IP {
    $HOST.UI.RawUI.WindowTitle = "Releasing IP..."
    ipconfig.exe /release
    if ($LASTEXITCODE)
        {
            throw "IPconfig release failed"
        }
}

function Clean-AllEventLogs {
	$HOST.UI.RawUI.WindowTitle = "Cleaning all event logs..."
	wevtutil el | Foreach-Object {wevtutil cl "$_"}
}

function Disable-CBServiceOnStop(){
	$pyScriptsPath = "$programFilesDir\Cloudbase Solutions\Cloudbase-Init\Python\lib\site-packages\cloudbaseinit\osutils"
    move "$pyScriptsPath\windows.py" "$pyScriptsPath\windows-orig.py" -Force
	copy "$resourcesDir\windows.py" "$pyScriptsPath\windows.py" -Force
}

function AddLicenseToSetup(){
    cmd /c "copy $resourcesDir\SetupLicenseCmds.cmd+c:\Windows\Setup\Scripts\SetupComplete.cmd c:\Windows\Temp\SetupComplete.cmd"
	cmd /c "move /Y c:\Windows\Temp\SetupComplete.cmd c:\Windows\Setup\Scripts\SetupComplete.cmd"
}

try
{
    
    Clean-WindowsUpdates
	
    $Host.UI.RawUI.WindowTitle = "Ready to run Sysprep."
    $unattendedXmlPath = "$programFilesDir\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml"

	Write-Host "Press any key to move to sysprep stage..."
	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

	#Release-IP
	
	Clean-AllEventLogs

	$Host.UI.RawUI.WindowTitle = "Running Sysprep..."
    & "$ENV:SystemRoot\System32\Sysprep\Sysprep.exe" `/generalize `/oobe `/shutdown `/unattend:"$unattendedXmlPath"
}
catch
{
    $host.ui.WriteErrorLine($_.Exception.ToString())
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    throw
}
