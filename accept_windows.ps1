param(
    [Parameter(Mandatory=$true)][string]$Archive,
    [Parameter(Mandatory=$true)][string]$ExpectedSha256,
    [Parameter(Mandatory=$true)][string]$Fixture,
    [Parameter(Mandatory=$true)][string]$WorkDirectory
)
$ErrorActionPreference = 'Stop'
$archivePath = (Resolve-Path -LiteralPath $Archive).Path
$fixturePath = (Resolve-Path -LiteralPath $Fixture).Path
$workPath = [IO.Path]::GetFullPath($WorkDirectory)
if (Test-Path -LiteralPath $workPath) { throw 'WorkDirectory must be new. Prior acceptance evidence is preserved.' }
$actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ExpectedSha256 -notmatch '^[a-fA-F0-9]{64}$' -or $actualHash -ne $ExpectedSha256.ToLowerInvariant()) {
    throw 'Archive SHA256 does not match the expected release.'
}
New-Item -ItemType Directory -Path $workPath | Out-Null
$reportPath = Join-Path $workPath 'acceptance.json'
$report = [ordered]@{
    archiveSha256 = $actualHash
    fixtureSha256 = (Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash.ToLowerInvariant()
    os = [Environment]::OSVersion.VersionString
    powershell = $PSVersionTable.PSVersion.ToString()
    status = 'running'
    isolatedProfile = $true
    pythonRemovedFromPath = $true
    cleanMachineEstablished = $false
    tests = @()
    limitations = @('Host cleanliness must be independently established.', 'Native dialogs, visual layout and audible playback are not tested.')
}
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($archivePath, (Join-Path $workPath 'Extracted app'))
    $payload = Join-Path $workPath 'Extracted app\LocalMemory'
    $exe = Join-Path $payload 'LocalMemory.exe'
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'LocalMemory.exe is missing from archive.' }
    $before = @{}
    Get-ChildItem -LiteralPath $payload -Recurse -File | ForEach-Object {
        $before[$_.FullName] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }
    $copiedFixture = Join-Path $workPath ('qualification speech' + [IO.Path]::GetExtension($fixturePath))
    Copy-Item -LiteralPath $fixturePath -Destination $copiedFixture
    foreach ($test in @('storage', 'audio')) {
        $output = Join-Path $workPath ($test + '.json')
        $options = if ($test -eq 'storage') { @('--self-test-report', $output) } else {
            @('--qualify-audio', $copiedFixture, '--result-report', $output)
        }
        $start = New-Object System.Diagnostics.ProcessStartInfo
        $start.FileName = $exe
        $start.Arguments = (($options | ForEach-Object { '"' + $_ + '"' }) -join ' ')
        $start.WorkingDirectory = $workPath
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        foreach ($key in @('PYTHONPATH','PYTHONHOME','VIRTUAL_ENV','CONDA_PREFIX')) { $start.EnvironmentVariables.Remove($key) }
        $start.EnvironmentVariables['PATH'] = "$env:SYSTEMROOT\System32;$env:SYSTEMROOT"
        foreach ($key in @('LOCALAPPDATA','APPDATA','USERPROFILE','HF_HOME')) {
            $folder = Join-Path $workPath ('Isolated profile\' + $key)
            [IO.Directory]::CreateDirectory($folder) | Out-Null
            $start.EnvironmentVariables[$key] = $folder
        }
        $start.EnvironmentVariables['HF_HUB_OFFLINE'] = '1'
        $start.EnvironmentVariables['TRANSFORMERS_OFFLINE'] = '1'
        $process = [Diagnostics.Process]::Start($start)
        try {
            if (-not $process.WaitForExit(300000)) {
                $process.Kill()
                throw "$test exceeded the five-minute limit."
            }
            if ($process.ExitCode -ne 0) { throw "$test exited with code $($process.ExitCode)." }
        } finally { $process.Dispose() }
        if (-not (Test-Path -LiteralPath $output)) { throw "$test produced no result receipt." }
        $result = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
        if ($result.PSObject.Properties.Name -contains 'error') { throw "$test failed: $($result.error)" }
        if ($test -eq 'storage' -and ($result.storage -ne 'passed' -or $result.ui_callbacks -ne 'passed')) { throw 'Storage checks failed.' }
        if ($test -eq 'audio') {
            foreach ($key in @('cancelled_without_partial_data','desktop_search','desktop_export','reopen_persistence','network_blocked','source_unchanged')) {
                if ($result.$key -ne $true) { throw "Audio acceptance did not prove $key." }
            }
            if ($result.retry_segments -lt 1) { throw 'Audio acceptance produced no transcript.' }
        }
        $report.tests += [ordered]@{name=$test; status='passed'; result=$result}
    }
    $after = @(Get-ChildItem -LiteralPath $payload -Recurse -File)
    if ($after.Count -ne $before.Count) { throw 'Package file count changed during execution.' }
    foreach ($file in $after) {
        if (-not $before.ContainsKey($file.FullName) -or (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne $before[$file.FullName]) {
            throw "Package changed during execution: $($file.Name)"
        }
    }
    $report['packageUnchanged'] = $true
    $report['status'] = 'passed'
} catch {
    $report['status'] = 'failed'
    $report['error'] = $_.Exception.Message
    throw
} finally {
    $report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $reportPath -Encoding UTF8
}
Write-Output "Acceptance passed. Evidence: $reportPath"
