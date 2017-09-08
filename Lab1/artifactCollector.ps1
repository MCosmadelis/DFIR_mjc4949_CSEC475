# artifactCollector
# By: Michael Cosmadelis
#
# Gathers information from remote and local Windows systems
# and outputs results to a csv that can be sent from gmail.
#


$pcArr = @()
while ($true){
    $PC = Read-Host -Prompt "Enter hostname or IP (enter . when done): "
    if ($PC -eq "."){
        break
    }
    $pcArr += $PC
}

foreach ($curPC in $pcArr){ 

    $session = New-PSSession -ComputerName $curPC -Credential Forensics

    Write-Host "Enter credentials for $curPC"

    Write-Host "Gathering data and writing to csv. . ."
    Write-Host "Please wait. . .`n"

    $output = Invoke-Command -Session $session -ScriptBlock {

        ####### Get uptime
        Write-Output "########## Get Current Time and Uptime ##########" 
        $os = Get-WmiObject win32_operatingsystem
        $uptime = (Get-Date) - ($os.ConvertToDateTime($os.LastBootUpTime))
        $Display = "" + $uptime.Days + " days, " + $uptime.Hours + " hour(s), " + $uptime.minutes + " minute(s), " + $uptime.Seconds + " second(s)."

        ####### Get current time & Get current time zone
        $GetTimeTable = @( @{Date=Get-Date; TimeZone=[System.TimeZone]::CurrentTimeZone.StandardName; Uptime=$Display})
        $GetTimeTable.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

        Write-Output "########## Windows Version ##########" 
        ####### Windows Version
        $ver=[System.Environment]::OSVersion.Version
        $GetVersionTable = @( @{Major=$ver.Major; Minor=$ver.Minor; Build=$ver.build; Revision=$ver.revision; Version=$os.caption})
        $GetVersionTable.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

        Write-Output "########## Windows Hardware ##########"-ForegroundColor Yellow
        ####### Windows Hardware
        $GetHardwareTable = @( @{CPU=(Get-WmiObject win32_processor).name; CPU_Type=$os.osarchitecture; 
        "RAM (GB)"=(Get-WmiObject win32_physicalmemory).capacity / 1GB; "HDD Size (GB)"=[math]::round(((Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'").size / 1GB))
        ; Root=Get-PSDrive -PSProvider 'FileSystem'})
        $GetHardwareTable.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

        ####### Domain information
        Write-Output "########## Domain Information ##########"-ForegroundColor Yellow
        if ((gwmi win32_computersystem).partofdomain -eq $true) {
            $domain = [System.Directoryservices.Activedirectory.Domain]::GetCurrentDomain()
            $domain | ForEach-Object {$_.DomainControllers} | 
            ForEach-Object {
            $hostEntry= [System.Net.Dns]::GetHostByName($_.Name)
            New-Object -TypeName PSObject -Property @{
              Name = $_.Name
              IPAddress = $hostEntry.AddressList[0].IPAddressToString 
              }
            } | Select Name, IPAddress | Format-Table -AutoSize
        }

        Write-Output "########## Domain and Hostname ##########" 
        ####### Get Domain name and hostname
        $GetDomainNameTable = @( @{Hostname=(Get-WmiObject win32_computersystem).name; Domain=(Get-WmiObject win32_computersystem).domain})
        $GetDomainNameTable.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

        Write-Output "########## User's Info ##########" 
        ####### Get user's info - gets domain users, system users, local users, service users, and user login history.
        Get-LocalUser | select Name, LastLogon, SID | Format-table -AutoSize

        if ((gwmi win32_computersystem).partofdomain -eq $true) {
            Get-ADUser -Filter * -Properties WhenCreated, lastlogondate | Select Name, SID, WhenCreated, lastlogondate
        }

        Write-Output "########## Starts at boot ##########`n" 
        #Start at Boot
        Write-Output "##### Programs #####`n" 
        Get-CimInstance win32_startupcommand | select Location, Command, User | Format-Table -AutoSize

        Write-Output "##### Services #####`n" 
        Get-CimInstance win32_service | where {$_.startmode -eq "Auto"} | select Name | Format-Table -AutoSize

        Write-Output "########## Scheduled tasks ##########" 
        # List of scheduled tasks
        Get-ScheduledTask | where {$_.state -eq "Ready"} | select TaskName |  Format-Table -AutoSize

        Write-Output "########## Network information ##########" 

        ############ Network #############
        Write-Output "########## Arp table ##########" 
        # Get the arp table
        arp -a
        Write-Output "########## Interface MAC addresses ##########" 
        ##### Get MAC address for all interfaces
        getmac

        Write-Output "########## Routing table ##########" 
        ###### Get routing table
        Get-NetRoute | Format-Table -AutoSize

        Write-Output "########## Interface IP addresses ##########" 
        ###### Get IPv4 and IPv6 addresses for all interfaces
        Get-NetIPAddress | select IPAddress | Format-Table -AutoSize

        Write-Output "########## DHCP Server ##########" 
        ###### Get DHCP Servers
        $temp = ipconfig /all | Select-String -Pattern "DHCP Server"
        $DHCP = "$temp".Split(": ") | select -last 1
        $DHCPTable = @( @{DHCPIP=$DHCP;})
        $DHCPTable.ForEach({[PSCustomObject]$_}) | Format-Table -AutoSize

        Write-Output "########## DNS Servers ##########" 
        ###### Get DNS Servers 
        Get-DnsClientServerAddress | Select ServerAddresses | Format-Table -AutoSize

        Write-Output "########## Interface Gateways ##########" 
        ###### Get gateways for all interfaces
        Get-WmiObject -Class Win32_IP4RouteTable | where { $_.destination -eq '0.0.0.0' -and $_.mask -eq '0.0.0.0'} | Sort-Object metric1 | select-object -property @{N="Gateway(s)"; E={$_.nexthop}} | Format-Table -AutoSize

        Write-Output "########## Listening Services ##########" 
        ###### Show listening services
        Get-NetTCPConnection | where {$_.state -eq "Listen" } | select LocalAddress, LocalPort, @{N="Protocol"; E={"TCP"}}, Name | Format-Table -AutoSize

        Write-Output "########## Established connections ##########" 
        ###### Show established connections
        Get-NetTCPConnection | where {$_.state -eq "Established" } | select Name, LocalPort, RemoteAddress, RemotePort, CreationTime, @{N="Protocol"; E={"TCP"}} | Format-Table -AutoSize

        Write-Output "########## DNS Cache ##########`n" 
        ###### DNS Cache
        Get-DnsClientCache | Format-Table


        Write-Output "########## Network shares, printers, and wifi access profiles ##########" 
        ###### Network shares, printers and wifi access profiles
        Get-WmiObject -Query "Select * from win32_share" | Format-Table -AutoSize
        Get-Printer | Format-Table -AutoSize
        netsh wlan show profiles

        Write-Output "`n`n########## List of installed software ##########" 
        ####### List of installed software
        Get-WmiObject -Class Win32_product | Format-Table 

        Write-Output "########## Current process List ##########" 
        ####### Current Process List
        # need to get user who owns the process
        Get-CimInstance -Class Win32_Process | select name, processid, parentprocessid, path | Format-Table -AutoSize

        Write-Output "########## Driver list ##########" 
        ####### Driver list
        Get-WindowsDriver -online | select Driver, BootCritical, Version, Date, ProviderName, OriginalFileName | Format-table -AutoSize

        Write-Output "########## Check for SMB1.0 ##########"
        Get-SmbServerConfiguration | Select-Object EnableSMB1protocol | Format-Table -AutoSize


        Write-Output "########## Firewall info ##########"
        netsh advfirewall show allprofiles

        Write-Output "########## PnP Device ##########"
        Get-PnpDevice | select Class, FriendlyName, InstanceID | Format-Table -AutoSize

        Write-Output "########## Files in Documents and Downloads of all users ##########" 
        ####### List of files in downloads and documents of all users
        # Find all directories in the users folder. For each user's folder . . .
        Get-ChildItem -path "C:\Users" | ForEach-Object {
            if ($_.fullname -eq "C:\Users\Public"){
                continue
            }
            Get-ChildItem "$($_.FullName)\Documents"
            Get-ChildItem "$($_.FullName)\Downloads"
        }
                            
        "`n --------------------------------------------`n"

        exit
    }
    $output | Tee-Object -file "output.csv" -Append
}

$ifEmail = Read-Host -Prompt "Email results? [y/n]: "

if( $ifEmail -eq "y"){
    $From = Read-Host -Prompt "From: "
    $To = Read-Host -Prompt "To: "
    $Attachment = "output.csv"
    $Subject = "Forensics Csv"
    $Body = "Attached is the Csv file."
    $SMTPServer = "smtp.gmail.com"
    $SMTPPort = "587"
    Send-MailMessage -From $From -to $To -Subject $Subject `
    -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl `
    -Credential (Get-Credential) -Attachments $Attachment
}




