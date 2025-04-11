Write-Host ""
Write-Host ""
Write-Host ""
Write-Host -ForegroundColor Red "By iDxvd :D"
Write-Host ""
Write-Host ""
Write-Host -ForegroundColor Magenta "discord.gg/sololegends"
Write-Host ""
Write-Host ""

$bootTime = (Get-CimInstance Win32_LogonSession | Where-Object { $_.LogonType -eq 2 } | 
    Sort-Object StartTime -Descending | 
    Select-Object -First 1).StartTime



function Test-ServiceRestart {
    param (
        [System.ServiceProcess.ServiceController]$Service
    )
    
    if ($Service.Status -eq 'Running') {
        try {
            $serviceProcess = Get-Process -Id $Service.Id;
            $serviceStartTime = $serviceProcess.StartTime;
            $timeSinceBoot = $serviceStartTime - $bootTime;
            if ($timeSinceBoot.TotalMinutes -gt 10) {
                return $true;
            }
        } catch {
            return $false;
        }
    }
    return $false;
}


$servicesToCheck = @(
    "dps",
    "eventlog",
    "SysMain",
    "appinfo",
    "pcasvc",
    "dusmsvc",
    "diagtrack",
    "vss",
    "sgrmbroker"
)

Write-Host "`nService Status Check Report" -ForegroundColor Cyan;
Write-Host "=======================================";
Write-Host "Boot Time: $bootTime" -ForegroundColor Yellow;
Write-Host "";
foreach ($serviceName in $servicesToCheck) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop;
        
       
        $serviceConfig = sc.exe qc $serviceName | Out-String;
        $startType = if ($serviceConfig -match "AUTO_START") { "Auto" } else { "Disabled" };
        
        
        $status = $service.Status;
        
        
        $wasRestarted = Test-ServiceRestart -Service $service;
        
        if ($status -eq "Running" -and $startType -eq "Auto") {
            Write-Host "[$serviceName]" -NoNewline;
            Write-Host " - Status: Running (Auto)" -ForegroundColor Green;
            
            if ($wasRestarted) {
                Write-Host "   * Service was restarted after system boot" -ForegroundColor Yellow;
            }
        } else {
            Write-Host "[$serviceName]" -NoNewline;
            Write-Host " - Status: $status ($startType)" -ForegroundColor Red;
            
            
            $failureActions = sc.exe qfailure $serviceName | Out-String;
            if ($failureActions -match "Last failure") {
                $lastFailure = ($failureActions -replace '.*Last failure: ', '').Trim();
                Write-Host "   * Last disabled: $lastFailure" -ForegroundColor Red;
            }
        }
    }
    catch {
        Write-Host "[$serviceName] - Service not found" -ForegroundColor Red;
    }
}
Write-Host ""
Write-Host "======================================="

