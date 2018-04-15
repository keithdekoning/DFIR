#Define Variables
$PathArtifacts = "C:\DFIR\Results\DFIR-$env:COMPUTERNAME-$env:username-$(((get-date).ToUniversalTime()).ToString("yyyy-MM-dd-hh-mm-ss-")).xlsx"
$PathMemory = "C:\DFIR\Results\Memory\Memory-$env:COMPUTERNAME-$env:username-$(((get-date).ToUniversalTime()).ToString("yyyy-MM-dd-hh-mm-ss-")).dmp"


#Define Function ScopeScan-Primary
function ScopeScan-Primary{

    
    #Create a VSS snapshot of the disk
    Write-Host "VSS"
    wmic shadowcopy call create Volume='C:\' | Out-Null
    #End VSS


    #Computer Info
    Write-Host "Computer Info"
    Get-ComputerInfo | Export-Excel -WorkSheetname "ComputerInfo" $PathArtifacts
    #End of Computer Info


    #Antivirus Info
    Write-Host "AV Info"
    Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Export-excel -WorkSheetname "AntiVirus" $PathArtifacts
    #End Antivirus Info


    #Running Processes
    Write-Host "Processes"
    Get-Process | Export-Excel -WorkSheetname "Get-Process" $PathArtifacts
    #End of Running Processes


    #Running Services
    Write-Host "Services"
    Get-Service | Export-Excel -WorkSheetname "Get-Services" $PathArtifacts
    #End of Running Services


    #Running Drivers
    Write-Host "Drivers"
    Get-WindowsDriver -Online -All | Export-Excel -WorkSheetname "Get-WindowsDriver" $PathArtifacts
    #End of Running Drivers


    #Get Non-Microsoft Process Executables
    Write-Host "Process Executables"
    $ProcExes = Get-WmiObject -Namespace root\cimv2 -Class CIM_ProcessExecutable
    $Result = foreach ($item in $ProcExes)
    {
        [wmi]"$($item.Antecedent)" | ? { $_.Manufacturer -ne 'Microsoft Corporation' } | select FileName,Extension,Manufacturer,Version
    }
    $Result | Export-Excel -WorkSheetname "Non-Microsoft Process Executables" $PathArtifacts
    #End of Non-Microsoft Process Exacutables


    #Get SMB Open Shares
    Write-Host "Shares"
    Get-SmbOpenFile | Export-Excel -WorkSheetname "Open SMB Shares" $PathArtifacts
    #End of SMB Open Shares


    #Autoruns
    Write-Host "Autoruns"
    c:\DFIR\Tools\autorunsc64.exe -a * -s -t -h -c -o "C:\DFIR\Results\Autoruns_$env:username.csv" 
    #End of Autoruns


    #Network
    Write-Host "Network"
    Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, AppliedSetting, OwningProcess, CreationTime | Export-Excel -worksheetname "NETIPConnections" $PathArtifacts
    Get-NetIPInterface | Select-Object ifIndex, InterfaceAlias, AddressFamily, InterfaceMetric, Dhcp, ConnectionState | Sort-Object ifindex | Export-Excel -WorkSheetname "NETIPInterfaces" $Pathartifacts
    #End of Network


    #Get Mapped Drives
    Write-Host "Mapped Drives"
    Get-PSDrive | Export-Excel -WorkSheetname "Mapped Drives" $PathArtifacts
    #End of Mapped Drives


    #Get all Created Shadow Copies 
    Write-Host "VSS"
    Get-WmiObject Win32_ShadowCopy | Export-Excel -WorkSheetname "All created VSS Copies" $PathArtifacts
    #End of Shadow Copies


    #Get Scheduled Items
    Write-Host "Scheduled Items"
    Get-ScheduledJob | Export-Excel -WorkSheetname "Scheduled Jobs" $PathArtifacts
    Get-ScheduledTask | Export-Excel -WorkSheetname "Scheduled Task" $PathArtifacts
    #End of Scheduled Items


    #Get-Hotfixes
    Write-Host "hotfixes"
    Get-HotFix | Export-Excel -WorkSheetname "Hotfixes" $PathArtifacts
    #End of Hotfixes


    #Get Installed Programs
    Write-Host "Installed programs"
    Get-WmiObject -Class Win32_Product -ComputerName . | Format-List -Property * | Export-Excel -WorkSheetname "Installed Programs" $PathArtifacts
    #End of Installed Programs


    #DNS
    Write-Host "DNS"
    get-dnsclientcache | Export-Excel -WorkSheetname "DNS Cache" $PathArtifacts
    #End of DNS


    #UserList
    Write-Host "Userlist"
    Get-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | select-object profileimagepath,pschildname | export-Excel -WorkSheetname "User List" $PathArtifacts
    #End of UserList


    #Powershell History
    Write-Host "PSHistory"
    get-history | Export-Excel -WorkSheetname "Powershell History" $PathArtifacts
    #End of Powershell History


    #Get Firewall Configuration
    Write-Host "fwconfig"
    netsh firewall show config | Export-Excel -WorkSheetname "Windows Firewall" $PathArtifacts
    #End of Firewall Configuration


    #Get Host File
    Write-Host "hostfile"
    gc $env:windir\system32\drivers\etc\hosts | Export-Excel -WorkSheetname "Host File" $PathArtifacts
    #End of Host File


    #PreFetch Files
    Write-Host "pffiles"
    C:\DFIR\Tools\PECmd.exe -d "C:\Windows\Prefetch" --csv C:\DFIR\Results\ | out-null
    #End of PreFetch Files


    #Shim Cache
    Write-Host "Shim"
    C:\DFIR\Tools\AppCompatCacheParser.exe --csv C:\DFIR\Results\
    #End of Shim Cache


    #Recent File Cache and AM Cache
    Write-Host "AMCache"
    $s1 = (Get-WmiObject -List Win32_ShadowCopy).Create("C:\", "ClientAccessible")
    $s2 = Get-WmiObject Win32_ShadowCopy | Where-Object { $_.ID -eq $s1.ShadowID }
    $s3 = Get-ComputerInfo | Select-Object WindowsProductName

    $d  = $s2.DeviceObject + "\" 

    cmd /c mklink /d C:\DFIR\shadowcopy "$d"

    if ($s3 = "*windows 10*") { 
    
        mkdir C:\DFIR\Results\AMCache\

        Copy C:\DFIR\Shadowcopy\Windows\Appcompat\Programs\Amcache.hve C:\DFIR\Results\AMCache

        }
        else {

        mkdir C:\DFIR\Results\Appcompat\

        Copy C:\DFIR\Shadowcopy\Windows\appcompat\Programs\recentfilecache.bcf C:\DFIR\Results\AppCompat\
        }

        $s2.Delete()
    #End of Recent File / AM Cache


    <#
    End of Primary Scan
    #>


}


#Define Function ScopeScan-Additional
function ScopeScan-Additional{


    #Get All Connected USB Devices
    gp -ea 0 hklm:\system\currentcontrolset\enum\usbstor\*\* | select FriendlyName,PSChildName,ContainerID | Export-Excel -WorkSheetname "USB Devices" $PathArtifacts
    #End of all Connected USb Devices


    #Get First Seen Date of USB Devices
    Get-ItemProperty -ea 0 hklm:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\* | select PSChildName | foreach-object {$P = $_.PSChildName ; Get-Content C:\Windows\inf\setupapi.dev.log | select-string $P -SimpleMatch -context 1 } | Export-Excel -WorkSheetname "First Connected USB" $PathArtifacts
    #End of First Seen Date USB Devices


    #Get Reparse Points 
    dir 'C:\' -recurse -force | ?{$_.LinkType} | select FullName,LinkType,@{ Name="Targets"; Expression={$_.Target -join "`t"} }
    #End of Reparse Points


    #Get Entropy
    densityscout.exe -pe -r -o C:\dfir\results\entropy\entropy.txt C:\
    #End of Entropy


    #Get Audit  Policy
    auditpol /get /category:* | select-string 'No Auditing' -notmatch | Export-Excel -WorkSheetname "Audit Policy" $PathArtifacts
    #End of Audit Policy


    #Get Event Logs
    Get-Eventlog -logname "Application" | Export-Excel -WorkSheetname "Appliation Log" $PathArtifacts
    Get-Eventlog -logname "HardwareEvents" | Export-Excel -WorkSheetname "HardwareEvents Log" $PathArtifacts
    Get-Eventlog -logname "Internet Explorer" | Export-Excel -WorkSheetname "Internet Explorer Log" $PathArtifacts
    Get-Eventlog -logname "Key Management Service" | Export-Excel -WorkSheetname "Key Management Service Log" $PathArtifacts
    Get-Eventlog -logname "OAlerts" | Export-Excel -WorkSheetname "OAlerts Log" $PathArtifacts
    Get-Eventlog -logname "Security" | Export-Excel -WorkSheetname "Security Log" $PathArtifacts
    Get-Eventlog -logname "System" | Export-Excel -WorkSheetname "System Log" $PathArtifacts
    Get-Eventlog -logname "Windows PowerShell" | Export-Excel -WorkSheetname "Windows PowerShell Log" $PathArtifacts
    #End Event Logs


    <#
    End of Additional Scan
    #>


    }


#Define Function ScanType-Quick
function ScanType-Quick {
    

        #Show Scan Type
        Write-Host "This would be a quick Scan"
        #End of Show Scan Type


        #Memory Aquisition
        if($MemoryScanType -eq "Yes"){
        Write-Host "Begining Memory Scan..."
        mkdir "C:\DFIR\Results\Memory\"
        C:\DFIR\Tools\Dumpit.exe /Q /O $PathMemory
        Write-Host "Memory Scan Completed"
        }
        #End of Memory Aquisition

    
        #No Memory Scan Selected
        elseif($MemoryscanType -eq "No"){
        Write-Host "No Memory Scan Selected"
        }
        #End of No Memory Scan selected


        #Begin Quick Scan
        ScopeScan-Primary
        #End Quick Scan

    }


#Define Function ScanType-Full
function ScanType-Full {

    
        #Show Scan Type
        Write-Host "This would be a full scan"
        #End Show Scan Type


        #Memory Aquisition
        if($MemoryScanType -eq "Yes"){
        Write-Host "Begining Memory Scan..."
        mkdir "C:\DFIR\Results\Memory\"
        C:\DFIR\Tools\Dumpit.exe /Q /O $PathMemory
        Write-Host "Memory Scan Completed"
        }
        #End of Memory Aquisition

    
        #No Memory Scan Selected
        elseif($MemoryscanType -eq "No"){
        Write-Host "No Memory Scan Selected"
        }
        #End of No Memory Scan selected


        #Begin Quick Scan
        ScopeScan-Primary
        #End Quick Scan


        #Begin Full Scan
        ScopeScan-Additional
        #End Full Scan
       
}


#Choose the type of scan
do {
    Write-Host "
==========Choose Scan Type==========
Quick
Full
===================================="
$ScanType = Read-Host -prompt "Select Scan Type and Press Enter"
    }
until ($scanType -eq "Quick" -or $ScanType -eq "Full")


#Decide if you would like a memory dump
do {
    Write-Host " 
============Memory Dump?============
Yes
No
===================================="
$MemoryScanType = Read-Host -Prompt "Enter an Option and Press Enter"
    } 
until ($MemoryScanType -eq "Yes" -or $MemoryScanType -eq "No")


#Begin Scan
if($ScanType -eq "Quick"){
    ScanType-Quick
} elseif($scanType -eq "Full"){
    ScanType-Full
}

