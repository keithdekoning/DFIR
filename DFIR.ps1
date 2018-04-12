<#
.SYNOPSIS
This script is a Powershell to gather artifacts for IR in Windows Enviroments. 
#>

#Memory Aquisition
C:\DFIR\Tools\Dumpit.exe /Q /O C:\DFIR\Results\Memory_$env:username.dmp
#End of Memory Aquisition

#Autoruns
c:\DFIR\Tools\autorunsc64.exe -a * -s -t -h -c -o C:\DFIR\Results\Autoruns_$env:username.csv
#End of Autoruns

#Netstat
netstat -q -b -f -o > C:\DFIR\Results\Netstat_Connections_$env:username.txt
netstat -r > C:\DFIR\Results\RouteTable_$env:username.txt
#End of Netstat

#DNS
get-dnsclientcache > C:\DFIR\Results\DNS_$env:username.txt
#End of DNS

#UserList
Get-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | ft profileimagepath,pschildname > C:\DFIR\Results\Userslist_$env:username.txt
#End of UserList

#Powershell History
get-history > C:\DFIR\Results\PS_History_$env:username.csv
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
