# artifactCollector
# By: Michael Cosmadelis

# TODO - Add PSremote, Add exporting tables to CSV, AD support

####### Get uptime
Write-Host "########## Get Current Time and Uptime ##########" -ForegroundColor Yellow
$os = Get-WmiObject win32_operatingsystem
$uptime = (Get-Date) - ($os.ConvertToDateTime($os.LastBootUpTime))
$Display = "" + $uptime.Days + " days, " + $uptime.Hours + " hour(s), " + $uptime.minutes + " minute(s), " + $uptime.Seconds + " second(s)."

####### Get current time & Get current time zone
$GetTimeTable = @( @{Date=Get-Date; TimeZone=[System.TimeZone]::CurrentTimeZone.StandardName; Uptime=$Display})
$GetTimeTable.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

Write-Host "########## Windows Version ##########" -ForegroundColor Yellow
####### Windows Version
$ver=[System.Environment]::OSVersion.Version
$GetVersionTable = @( @{Major=$ver.Major; Minor=$ver.Minor; Build=$ver.build; Revision=$ver.revision; Version=$os.caption})
$GetVersionTable.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

Write-Host "########## Windows Hardware ##########"-ForegroundColor Yellow
####### Windows Hardware
$GetHardwareTable = @( @{CPU=(Get-WmiObject win32_processor).name; CPU_Type=$os.osarchitecture; 
"RAM (GB)"=(Get-WmiObject win32_physicalmemory).capacity / 1GB; "HDD Size (GB)"=[math]::round(((Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'").size / 1GB))
})
$GetHardwareTable.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

Write-Host "########## Domain and Hostname ##########" -ForegroundColor Yellow
####### Get Domain name and hostname
$GetDomainNameTable = @( @{Hostname=(Get-WmiObject win32_computersystem).name; Domain=(Get-WmiObject win32_computersystem).domain})
$GetDomainNameTable.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

Write-Host "########## User's Info ##########" -ForegroundColor Yellow
####### Get user's info - gets domain users, system users, local users, service users, and user login history.
Get-LocalUser | select Name, LastLogon, SID | Format-table -AutoSize


Write-Host "########## Starts at boot ##########`n" -ForegroundColor Yellow
#Start at Boot
Write-Host "##### Programs #####`n" -ForegroundColor Yellow
Get-CimInstance win32_startupcommand | select Location, Command, User | Format-Table -AutoSize

Write-Host "##### Services #####`n" -ForegroundColor Yellow
Get-CimInstance win32_service | where {$_.startmode -eq "Auto"} | select Name | Format-Table -AutoSize

Write-Host "########## Scheduled tasks ##########" -ForegroundColor Yellow
# List of scheduled tasks
Get-ScheduledTask | where {$_.state -eq "Ready"} | select TaskName |  Format-Table -AutoSize


Write-Host "########## Network information ##########" -ForegroundColor Yellow


############ Network #############
Write-Host "########## Arp table ##########" -ForegroundColor Yellow
# Get the arp table
arp -a
Write-Host "########## Interface MAC addresses ##########" -ForegroundColor Yellow
##### Get MAC address for all interfaces
getmac

Write-Host "########## Routing table ##########" -ForegroundColor Yellow
###### Get routing table
Get-NetRoute | Format-Table -AutoSize

Write-Host "########## Interface IP addresses ##########" -ForegroundColor Yellow
###### Get IPv4 and IPv6 addresses for all interfaces
Get-NetIPAddress | select IPAddress | Format-Table -AutoSize

Write-Host "########## DHCP Server ##########" -ForegroundColor Yellow
###### Get DHCP Servers
$temp = ipconfig /all | Select-String -Pattern "DHCP Server"
$DHCP = "$temp".Split(": ") | select -last 1
$DHCPTable = @( @{DHCPIP=$DHCP;})
$DHCPTable.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

Write-Host "########## DNS Servers ##########" -ForegroundColor Yellow
###### Get DNS Servers 
Get-DnsClientServerAddress | Select ServerAddresses | Format-Table -AutoSize

Write-Host "########## Interface Gateways ##########" -ForegroundColor Yellow
###### Get gateways for all interfaces
Get-WmiObject -Class Win32_IP4RouteTable | where { $_.destination -eq '0.0.0.0' -and $_.mask -eq '0.0.0.0'} | Sort-Object metric1 | select-object -property @{N="Gateway(s)"; E={$_.nexthop}} | Format-Table -AutoSize

Write-Host "########## Listening Services ##########" -ForegroundColor Yellow
###### Show listening services
Get-NetTCPConnection | where {$_.state -eq "Listen" } | select LocalAddress, LocalPort, @{N="Protocol"; E={"TCP"}}, Name | Format-Table -AutoSize

Write-Host "########## Established connections ##########" -ForegroundColor Yellow
###### Show established connections
Get-NetTCPConnection | where {$_.state -eq "Established" } | select Name, LocalPort, RemoteAddress, RemotePort, CreationTime, @{N="Protocol"; E={"TCP"}} | Format-Table -AutoSize

Write-Host "########## DNS Cache ##########`n" -ForegroundColor Yellow
###### DNS Cache
Get-DnsClientCache | Format-Table


Write-Host "########## Network shares, printers, and wifi access profiles ##########" -ForegroundColor Yellow
###### Network shares, printers and wifi access profiles
Get-WmiObject -Query "Select * from win32_share" | Format-Table -AutoSize
Get-Printer | Format-Table -AutoSize
netsh wlan show profiles

Write-Host "`n`n########## List of installed software ##########" -ForegroundColor Yellow
####### List of installed software
Get-WmiObject -Class Win32_product | Format-Table 

Write-Host "########## Current process List ##########" -ForegroundColor Yellow
####### Current Process List
# need to get user who owns the process
Get-CimInstance -Class Win32_Process | select name, processid, parentprocessid, path | Format-Table -AutoSize

Write-Host "########## Driver list ##########" -ForegroundColor Yellow
####### Driver list
Get-WindowsDriver -online | select Driver, BootCritical, Version, Date, ProviderName, OriginalFileName | Format-table -AutoSize

Write-Host "########## Files in Documents and Downloads of all users ##########" -ForegroundColor Yellow
####### List of files in downloads and documents of all users
$fold = Get-ChildItem -path "C:\Users" -recurse | ForEach-Object {
    # This is only printing out one user???? y tho
    if ($_.fullname -eq "C:\Users\Public"){
        continue
    }
    ls "$($_.FullName)\Documents" | format-table
    ls "$($_.FullName)\Downloads" | format-table
}

####### 3 of my own




