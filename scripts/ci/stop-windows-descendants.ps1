param([int]$ParentId, [long]$StartedMs, [long]$ExitedMs)
$ErrorActionPreference = 'Stop'
# A parent may exit before taskkill /T sees it. Match only children created
# during this invocation, so a subsequently reused parent PID cannot confer ownership.
$children = Get-CimInstance Win32_Process -Filter "ParentProcessId=$ParentId" |
    Where-Object {
        $created = ([DateTimeOffset]$_.CreationDate.ToUniversalTime()).ToUnixTimeMilliseconds()
        $created -ge $StartedMs -and $created -le $ExitedMs
    }
foreach ($child in $children) {
    & "$env:SystemRoot/System32/taskkill.exe" /PID $child.ProcessId /T /F | Out-Null
    if ($LASTEXITCODE -ne 0 -and (Get-Process -Id $child.ProcessId -ErrorAction SilentlyContinue)) {
        throw 'Owned descendant did not terminate'
    }
}
