<#
.SYNOPSIS
This script is a Powershell to gather artifacts for IR in Windows Enviroments. 
#>

#Define variables

#File Path and Name
$PathArtifacts = "C:\DFIR\Results\DFIR-$env:COMPUTERNAME-$env:username-$(((get-date).ToUniversalTime()).ToString("yyyy-MM-dd-hh-mm-ss-")).xlsx"
$PathMemory = "C:\DFIR\Results\Memory\Memory-$env:COMPUTERNAME-$env:username-$(((get-date).ToUniversalTime()).ToString("yyyy-MM-dd-hh-mm-ss-")).dmp"

#Script

#Memory Aquisition
C:\DFIR\Tools\Dumpit.exe /Q /O $PathMemory
#End of Memory Aquisition

#Autoruns
c:\DFIR\Tools\autorunsc64.exe -a * -s -t -h -c -o "C:\DFIR\Results\Autoruns_$env:username.csv" 
#End of Autoruns

#Network
Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, AppliedSetting, OwningProcess, CreationTime | Export-Excel -worksheetname "NETIPConnections" $PathArtifacts
Get-NetIPInterface | Select-Object ifIndex, InterfaceAlias, AddressFamily, InterfaceMetric, Dhcp, ConnectionState | Sort-Object ifindex | Export-Excel -WorkSheetname "NETIPInterfaces" $Pathartifacts
#End of Network

#DNS
get-dnsclientcache | Export-Excel -WorkSheetname "DNS Cache" $PathArtifacts
#End of DNS

#UserList
Get-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | select-object profileimagepath,pschildname | export-Excel -WorkSheetname "User List" $PathArtifacts
#End of UserList

#Powershell History
get-history | Export-Excel -WorkSheetname "Powershell History" $PathArtifacts
#End of Powershell History

#PreFetch Files
C:\DFIR\Tools\PECmd.exe -d "C:\Windows\Prefetch" --csv C:\DFIR\Results\ | out-null
#End of PreFetch Files

#Shim Cache
C:\DFIR\Tools\AppCompatCacheParser.exe --csv C:\DFIR\Results\
#End of Shim Cache

#Recent File Cache
Copy C:\Windows\appcompat\Programs\recentfilecache.bcf C:\DFIR\Results\
#End of Recent File Cache

#AMCache
Copy C:\Windows\Appcompat\Programs\Amcache.hve C:\DFIR\Results\
#End of AMCache

<#
End Script
#>
