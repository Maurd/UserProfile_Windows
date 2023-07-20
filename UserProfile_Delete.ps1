Function Write-Log($string) {
    Write-Host $string
    $TimeStamp = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    $TimeStamp + " " + $string | Out-File -FilePath $LogFile -Append -Force
}

$LogFile = "C:\"
$MagicDate = (Get-Date).AddDays(-7) 

# Get a profile list with a single call to Where-Object
# Use regex to filter profile list
$Exclude = "Help$|Bindview$|Metuser$"
# $UserProfiles is too close to $UserProfile so we use $UserProfileList to prevent typo bugs
# Only call Get-CimInstance once
$UserProfileList = Get-CimInstance -ClassName Win32_UserProfile -Filter "Special=False"  | Where-Object { $_.LastUseTime -lt $MagicDate -and $_.LocalPath -notmatch $Exclude -and $_.LocalPath -notlike "C:\Users\Administrator*" }

# Declare location once, outside of loop
$location = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\ProfileList"
ForEach ($UserProfile in $UserProfileList) {
    Write-Log "Removing $($UserProfile.LocalPath)"
	Remove-CimInstance $UserProfile

    # remove from registry. We have the SID still from before. 
    $remove = "$location\$($UserProfile.SID)"
    if (Test-Path $Remove) {
        Write-Log "Removing $remove"
        try {
            Remove-Item $remove -Force -ErrorAction:Stop
        }catch{
            Write-Log "Failed to remove SID from registry"
        }
    }
    else {
        Write-Log "SID removed from registry by Remove-CimInstance"
    }
}