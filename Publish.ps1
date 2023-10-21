$ErrorActionPreference = 'Stop'
$Script = "$PSScriptRoot/AdoCommandUtils"

. "${Script}Test.ps1"

if ($LASTEXITCODE -ne 0) {
    throw "Tests failed"
}

Publish-Script -Path "$Script.ps1" -NuGetApiKey $Env:NuGetApiKey

if ($?) {
    Test-ScriptFileInfo "$Script.ps1"
}
