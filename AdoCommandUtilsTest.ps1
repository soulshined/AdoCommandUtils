. ./AdoCommandUtils.ps1

Describe 'Add-AdoArtifactAssociation' {
    It "Write-Hosts <name> (<type>)" -ForEach @(
        @{ Value = "#/1/build"; Name = "MyServerDrop"; Type = "container"; },
        @{ Value = "\\MyShare\\MyDropLocation"; Name = "MyServerDrop"; Type = "filepath"; },
        @{ Value = "$/MyTeamProj/MyFolder"; Name = "MyTfvcPath"; Type = "versioncontrol"; },
        @{ Value = "refs/tags/MyGitTag"; Name = "MyTag"; Type = "gitref"; },
        @{ Value = "MyTfvcLabel"; Name = "MyTag"; Type = "gitref"; },
        @{ Value = "MyTfvcLabel"; Name = "MyTag"; Type = "tfvclabel"; },
        @{ Value = "https://downloads.visualstudio.com/foo/bar/package.zip"; Name = "myDrop"; Type = "mfartifacttype"; }
    ) {
        $Props = [AdoCommandProperties]::New(@{
            Type = $Type;
            ArtifactName = $Name;
        })
        adoassociation $Value -Type $Type -Name $Name 6>&1 | Should -BeExactly "##vso[artifact.associate $Props]$Value"
    }
}

Describe 'Add-AdoBuildTag' {
    It "Write-Hosts <expected> (<actual>)" -ForEach @(
        @{ Actual = "foobar"; Expected = 'foobar' }
        @{ Actual = "foobar/1/bazz"; Expected = 'foobar/1/bazz' }
        @{ Actual = "foobar 1.0.0"; Expected = 'foobar 1.0.0'; ColonReplacement = ' ' }
    ) {
        buildtag $Actual -ColonReplacement $ColonReplacement 6>&1 | Should -BeExactly "##vso[build.addbuildtag]$Expected"
    }

    It "Write-Many (<actual>)" -ForEach @(
        @{ Actual = @("foobar", "foobar/1/bazz", "foobar 1.0.0") }
    ) {
        buildtag $Actual 6>&1 | Should -BeExactly @("##vso[build.addbuildtag]foobar", "##vso[build.addbuildtag]foobar/1/bazz", "##vso[build.addbuildtag]foobar 1.0.0")
    }

    It "Should Fail <actual>" -ForEach @(
        @{ Actual = "foobar: 1.0.0"; Expected = 'Build tags can not contain colons' }
        @{ Actual = "foobar: 1.0.0"; ColonReplacement = ":"; Expected = 'Build tags can not contain colons' }
    ) {
        { buildtag $Actual -ColonReplacement $ColonReplacement } | Should -Throw $Expected
    }
}

Describe 'Export-ToAdoPath' {
    It "Write-Host Single Value (<value>)" -ForEach @(
        @{ Value = "/usr/bin/path" }
    ) {
        adopath $Value 6>&1 | Should -BeExactly "##vso[task.prependpath]$Value"
    }

    It "Write-Many (<actual>)" -ForEach @(
        @{ Actual = @("/usr/bin/path", "/usr/bin/pat" ) }
    ) {
        $Actual | adopath 6>&1 | Should -BeExactly @("##vso[task.prependpath]/usr/bin/path", "##vso[task.prependpath]/usr/bin/pat")
    }

    It "Should Fail <value>" -ForEach @(
        @{ Value = "  "; Expected = "Cannot validate argument on parameter 'Value'. Can not contain an empty or whitespace value" }
    ) {
        { adopath $Value }  | Should -Throw $Expected

    }
}

Describe 'Publish-AdoArtifact' {
    It "Write-Hosts" -ForEach @(
        @{ Path = "c:\testresult.trx"; Name = "uploadedresult"; }
        @{ Path = "c:\testresult.trx"; Name = "uploadedresult"; ContainerFolder = "testresult" }
    ) {
        if ($ContainerFolder) {
            adoartifact $Path -Name $Name -ContainerFolder $ContainerFolder 6>&1 | Should -BeExactly "##vso[artifact.upload artifactname=$Name;containerfolder=$ContainerFolder]$Path"
        }
        else {
            adoartifact $Path -Name $Name 6>&1 | Should -BeExactly "##vso[artifact.upload artifactname=$Name]$Path"

        }
    }
}

Describe 'Publish-AdoFile' {
    It "Write-Hosts" -ForEach @(
        @{ Value = "c:\testresult.trx"; Name = "uploadedresult"; }
        @{ Value = "c:\testresult.trx"; Name = "uploadedresult"; ContainerFolder = "testresult" }
    ) {
        adofile $Value 6>&1 | Should -BeExactly "##vso[task.uploadfile]$Value"
    }

    It "Write-Many (<actual>)" -ForEach @(
        @{ Actual = @("c:\testresult.trx", "c:\testresult2.trx") }
    ) {
        $Actual | adofile 6>&1 | Should -BeExactly @("##vso[task.uploadfile]c:\testresult.trx", "##vso[task.uploadfile]c:\testresult2.trx")
    }
}

Describe 'Publish-AdoSummary' {
    It "Write-Hosts" -ForEach @(
        @{ Value = "readme.md";}
    ) {
        adosummary $Value 6>&1 | Should -BeExactly "##vso[task.uploadsummary]$Value"
    }
}

Describe 'Set-AdoEndpoint' {
    It "Write-Hosts" -ForEach @(
        @{ Value = "testvalue"; Field = "authParameter"; Id = "000-0000-0000"; Key = "AccessToken" },
        @{ Value = "testvalue"; Field = "dataParameter"; Id = "000-0000-0000"; Key = "userVariable"},
        @{ Value = "https://example.com/service"; Field = "url"; Id = "000-0000-0000"; }
    ) {
        $Props = [AdoCommandProperties]::New(@{
            Key = $Key;
            Field = $Field;
            Id = $Id
        })
        if ($Key) {
            adoendpoint -Value $Value -ServiceId $Id -Field $Field -Key $Key 6>&1 | Should -BeExactly "##vso[task.setendpoint $Props]$Value"
        }
        else {
            adoendpoint -Value $Value -ServiceId $Id -Field $Field 6>&1 | Should -BeExactly "##vso[task.setendpoint $Props]$Value"
        }
    }

    It "Should-Throw" -ForEach @(
        @{ Value = "testvalue"; Field = "authParameter"; Expected = "Key parameter is required for authParameter" }
    ) {
        { adoendpoint $Value -Field $Field -Id "000-0000-0000" } | Should -Throw $Expected
    }
}

Describe 'Set-AdoSecret' {
    It "Write-Hosts" -ForEach @(
        @{ Value = "MySecret"; }
    ) {
        adosecret $Value 6>&1 | Should -BeExactly "##vso[task.setsecret]$Value"
    }
}

Describe 'Set-AdoTaskCompletion' {
    It "Write-Hosts" -ForEach @(
        @{ Value = "Completed!!!"; }
        @{ Value = "Completed But Kinda"; SucceededWithIssues = $true }
        @{ Value = "Failed"; Failed = $true }
    ) {
        if ($SucceededWithIssues) {
            adocompletion $Value -SucceededWithIssues 6>&1 | Should -BeExactly "##vso[task.complete result=SucceededWithIssues;]$Value"
        }
        elseif ($Failed) {
            adocompletion $Value -Failed 6>&1 | Should -BeExactly "##vso[task.complete result=Failed;]$Value"
        }
        else {
            adocompletion $Value 6>&1 | Should -BeExactly "##vso[task.complete result=Succeeded;]$Value"
        }
    }
}

Describe 'Write-AdoIssue' {
    It "Write-Hosts" -ForEach @(
        @{ Message = "Not Completed"; }
        @{ Message = "Oof"; Type="error"; SourcePath = 'consoleapp/main.cs' }
        @{ Message = "Oof"; Type="error"; SourcePath = 'consoleapp/main.cs'; LineNumber = 1; }
        @{ Message = "Oof"; Type="error"; SourcePath = 'consoleapp/main.cs'; LineNumber = 1; ColumnNumber = 1; }
        @{ Message = "Oof"; Type="error"; SourcePath = 'consoleapp/main.cs'; LineNumber = 1; ColumnNumber = 1; Code = 100 }
    ) {
        if (-not $Type) { $Type = 'warning' }
        $Props = [AdoCommandProperties]::New(@{
            Type = $Type;
            SourcePath = $SourcePath;
            LineNumber = $LineNumber;
            ColumnNumber = $ColumnNumber;
            Code = $Code;
        })
        adoissue $Message -Type $Type -SourcePath $SourcePath -Line $LineNumber -Col $ColumnNumber -Code $Code 6>&1 | Should -BeExactly "##vso[task.logissue $Props]$Message"
    }
}
