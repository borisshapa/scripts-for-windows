If ($args.count -eq 0) {
    Write-Output "poll <URL> to check new notifications. background <URL> to check new notifications in background process."
    Exit
} ElseIf ($args.count -gt 2) {
    Write-Output "Expected 2 arguments."
    Exit
}

$arg = $args[0]
$url = $args[1]

$wc = New-Object system.Net.WebClient

if ($arg -eq "poll") {
     $cur_notif = $wc.downloadString($url)
     while($true) {
        $request = $wc.downloadString($url)
        If ($request -ne $cur_notif) {
            Add-Type -AssemblyName System.Windows.Forms
            $objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon
            $objNotifyIcon.Icon = [System.Drawing.SystemIcons]::Information
            $objNotifyIcon.BalloonTipIcon = “Info"
            $objNotifyIcon.BalloonTipTitle = “String has been changed.”
            $objNotifyIcon.BalloonTipText = “Previous: '” + $cur_notif + "'. New: '" + $request + "'." 
            $objNotifyIcon.Visible = $True
            $objNotifyIcon.ShowBalloonTip(1)
            
            $cur_notif = $request
        }
        Start-Sleep -s 5
    }
} 


if ($arg -eq "background") {
    $bg_proc = Start-Process PowerShell -arg ".\notifications.ps1 poll $url" -WindowStyle Hidden -Passthru
    Add-Content -Path "temp.txt" -Value $bg_proc.Id
}

if ($arg -eq "kill") {
    $working_dir = Get-Location
    $temp_file = Get-Content "$($working_dir)\temp.txt" | Out-String
    $nl = [Environment]::NewLine
    $pids = ($temp_file -split "$nl" | Where-Object {$_})
    foreach($kill_pid in $pids) {
        If ($kill_pid) {
            Stop-Process -Id $kill_pid
        }
    }
    Clear-Content -Path "$($working_dir)\temp.txt"
}