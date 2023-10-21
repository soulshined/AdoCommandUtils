<#PSScriptInfo

.VERSION 1.0

.GUID 00b59a1d-a330-47ff-9a30-394080089364

.AUTHOR davidfreer@me.com

.COMPANYNAME

.COPYRIGHT

.TAGS ado utils log command

.LICENSEURI

.PROJECTURI https://github.com/soulshined/AdoCommandUtils

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.DESCRIPTION
 Ado Logging Command Utils

.RELEASENOTES
Hello World


.PRIVATEDATA

#>

Param()

if ($PSVersionTable.PSVersion.Major -lt 7 -and $PSVersionTable.PSVersion.Minor -lt 4) {
    class ValidateNotNullOrWhiteSpaceAttribute : System.Management.Automation.ValidateEnumeratedArgumentsAttribute {

        [void] ValidateElement($element) {
            if (-not ($element -is [string]) -and -not ($element -is [string[]])) {
                throw [System.Management.Automation.ParameterBindingException]::New($element)
            }

            $element | % {
                if ([string]::IsNullOrWhiteSpace($element)) {
                    throw [System.Management.Automation.ParameterBindingException]::New("Can not contain an empty or whitespace value")
                }
            }
        }

    }
}

class AdoCommandProperties {
    hidden [hashtable]$KVPS = [ordered]@{}

    AdoCommandProperties([hashtable]$Members) {
        $this.KVPS += $Members
    }

    [string] ToString() {
        $Flattened = $this.KVPS.GetEnumerator() | % {
            if ($null -eq $_.Value -or ($_.Value -is [string] -and [string]::IsNullOrWhiteSpace($_.Value))) { return }

            "{0}={1}" -f $_.Key.ToLower(), $_.Value
        }

        return ($Flattened ?? "") -join ";"
    }
}

function Add-AdoArtifactAssociation {
    <#
    .SYNOPSIS
        Wrapper for ##vso[artifact.associate]artifact location

    .DESCRIPTION
        Create a link to an existing Artifact. Artifact location must be a file container path, VC path or UNC share path.

    .EXAMPLE
        Add-AdoArtifactAssociation "\\MyShare\\MyDropLocation" -Name MyServerDrop -Type filepath

        echo "##vso[artifact.associate type=filepath;artifactname=MyServerDrop]\\MyShare\\MyDropLocation"

    .EXAMPLE
        Add-AdoArtifactAssociation "$/MyTeamProj/MyFolder" -Name MyTfvcPath -Type versioncontrol

        echo "##vso[artifact.associate type=versioncontrol;artifactname=MyTfvcPath]$/MyTeamProj/MyFolder"

    .EXAMPLE
        Add-AdoArtifactAssociation "#/1/build" -Name MyServerDrop -Type container

        echo "##vso[artifact.associate type=container;artifactname=MyServerDrop]#/1/build"

    .EXAMPLE
        adoassociation "refs/tags/MyGitTag" -Name MyTag -Type gitref

        echo "##vso[artifact.associate type=gitref;artifactname=MyTag]refs/tags/MyGitTag"

    .EXAMPLE
        adoassociation "MyTfvcLabel" -Name MyTag -Type gitref

        echo "##vso[artifact.associate type=gitref;artifactname=MyTag]MyTfvcLabel"

    .EXAMPLE
        adoassociation "MyTfvcLabel" -Name MyTag -Type tfvclabel

        echo "##vso[artifact.associate type=tfvclabel;artifactname=MyTag]MyTfvcLabel"

    .EXAMPLE
        adoassociation "https://downloads.visualstudio.com/foo/bar/package.zip" -Name myDrop -Type mfartifacttype

        echo "##vso[artifact.associate type=mfartifacttype;artifactname=myDrop]https://downloads.visualstudio.com/foo/bar/package.zip"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash#associate-initialize-an-artifact
    #>
    [Alias("adoassociation")]
    param(
        # Artifact Location
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Value,

        # Artifact Name
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true)]
        [string]$Name,

        # Artifact Type
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    process {
        $Props = [AdoCommandProperties]::New(@{
            Type=$Type;
            ArtifactName=$Name;
        })
        Write-Host "##vso[artifact.associate $Props]$Value"
    }

}

function Add-AdoBuildTag {
    <#
    .SYNOPSIS
        Wrapper for ##vso[build.addbuildtag]build tag

    .DESCRIPTION
        Add a tag for current build. You can expand the tag with a predefined or user-defined variable. For example, here a new tag gets added in a Bash task with the value last_scanned-$(currentDate). You can't use a colon with AddBuildTag

    .EXAMPLE
        Add-AdoBuildTag foobar

        echo "##vso[build.addbuildtag]foobar"

    .EXAMPLE
        Add-AdoBuildTag 'foobar/bazz/1.0.0'

        echo "##vso[build.addbuildtag]foobar/bazz/1.0.0"

    .EXAMPLE
        buildtag 'foobar:1.0.0' -ColonReplacement ' '

        echo "##vso[build.addbuildtag]foobar 1.0.0"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash#addbuildtag-add-a-tag-to-the-build
    #>
    [CmdletBinding()]
    [Alias('buildtag')]
    param(
        # Build tags to add
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Value,

        # By default a colon (:) will produce an error in build tags. This parameter will replace any colons
        [ValidateNotNull()]
        [char]$ColonReplacement
    )

    process {
        $Value | % {
            $Tag = $_
            if ($ColonReplacement) {
                $Tag = $Tag -replace ':', $ColonReplacement
            }

            if ($Tag -imatch ':') {
                throw "Build tags can not contain colons"
            }

            Write-Host "##vso[build.addbuildtag]$Tag"
        }
    }
}

function Export-ToAdoPath {
    <#
    .SYNOPSIS
        Wrapper for ##vso[task.prependpath]local file path

    .DESCRIPTION
        Update the PATH environment variable by prepending to the PATH. The updated environment variable will be reflected in subsequent tasks.

    .EXAMPLE
        Export-ToAdoPath 'c:\my\directory\path'

        echo "##vso[task.prependpath]c:\my\directory\path"

    .EXAMPLE
        adopath 'c:\my\directory\path'

        echo "##vso[task.prependpath]c:\my\directory\path"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash#prependpath-prepend-a-path-to-the--path-environment-variable
    #>
    [Alias("adopath")]
    param(
        # Paths to prepend
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Value
    )

    process {
        $Value | % {
            Write-Host "##vso[task.prependpath]$_"
        }
    }
}

function Publish-AdoArtifact {
    <#
    .SYNOPSIS
        Wrapper for ##vso[artifact.upload]local file path

    .DESCRIPTION
        Upload a local file into a file container folder, and optionally publish an artifact as artifactname.

    .EXAMPLE
        Publish-AdoArtifact 'c:\testresult.trx' -Name uploadedresult

        echo "##vso[artifact.upload artifactname=uploadedresult]c:\my\directory\path"

    .EXAMPLE
        adoartifact 'c:\testresult.trx' -Name uploadedresult -ContainerFolder TRX

        echo "##vso[artifact.upload artifactname=uploadedresult]c:\my\directory\path"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash#upload-upload-an-artifact
    #>
    [CmdletBinding()]
    [Alias("adoartifact")]
    param(
        # Artifact local file path
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias("Path")]
        [string]$LocalFilePath,

        # Artifact Name
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true)]
        [string]$Name,

        # Container Folder
        [ValidateNotNullOrWhiteSpace()]
        [string]$ContainerFolder
    )

    process {
        $Props = [AdoCommandProperties]::New(@{
                ArtifactName = $Name;
                ContainerFolder = $ContainerFolder;
            })
        Write-Host "##vso[artifact.upload $Props]$LocalFilePath"
    }
}

function Publish-AdoFile {
    <#
    .SYNOPSIS
        Wrapper for ##vso[task.uploadfile]local file path

    .DESCRIPTION
        Upload user interested file as additional log information to the current timeline record. The file shall be available for download along with task logs.

    .EXAMPLE
        Publish-AdoFile 'c:\additionalfile.log'

        echo "##vso[task.uploadfile]c:\additionalfile.log"

    .EXAMPLE
        adofile 'c:\additionalfile.log'

        echo "##vso[task.uploadfile]c:\additionalfile.log"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash#uploadfile-upload-a-file-that-can-be-downloaded-with-task-logs
    #>
    [Alias("adofile")]
    param(
        # Local file paths
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Value
    )

    process {
        $Value | % {
            Write-Host "##vso[task.uploadfile]$_"
        }
    }
}

function Publish-AdoSummary {
    <#
    .SYNOPSIS
        Wrapper for ##vso[task.uploadsummary]local file path

    .DESCRIPTION
        Upload and attach summary Markdown from a .md file in the repository to current timeline record. This summary shall be added to the build/release summary and not available for download with logs. The summary should be in UTF-8 or ASCII format. The summary will appear on the Extensions tab of your pipeline run. Markdown rendering on the Extensions tab is different from Azure DevOps wiki rendering.

    .EXAMPLE
        Publish-AdoSummary '$(System.DefaultWorkingDirectory)/testsummary.md'

        echo "##vso[task.uploadsummary]/vst/testsummary.md"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash#uploadsummary-add-some-markdown-content-to-the-build-summary
    #>
    [CmdletBinding()]
    [Alias('adosummary')]
    param(
        # Summaries to publish
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage="File names where markdown file exists")]
        [string[]]$Value
    )

    process {
        $Value | % {
            Write-Host "##vso[task.uploadsummary]$_"
        }
    }
}

function Set-AdoEndpoint {
    <#
    .SYNOPSIS
        Wrapper for ##vso[task.setendpoint]value

    .DESCRIPTION
        Set a service connection field with given value. Value updated will be retained in the endpoint for the subsequent tasks that execute within the same job.

    .EXAMPLE
        Set-AdoEndpoint testvalue -ServiceId 000-0000-0000 -Field authParameter -Key AccessToken

        echo "##vso[task.setendpoint id=000-0000-0000;field=authParameter;key=AccessToken]testvalue"

    .EXAMPLE
        adoendpoint testvalue -ServiceId 000-0000-0000 -Field dataParameter -Key userVariable

        echo "##vso[task.setendpoint id=000-0000-0000;field=dataParameter;key=userVariable]testvalue"

    .EXAMPLE
        adoendpoint 'https://example.com/service' -ServiceId 000-0000-0000 -Field url

        echo "##vso[task.setendpoint id=000-0000-0000;field=url]https://example.com/service"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash#setendpoint-modify-a-service-connection-field
    #>
    [CmdletBinding()]
    [Alias("adoendpoint")]
    param(
        # Value of end point. Value updated will be retained in the endpoint for the subsequent tasks that execute within the same job
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Value,

        # Service Connection Id
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true)]
        [Alias("id")]
        [string]$ServiceId,

        # Field Type, one of authParameter, dataParameter, url
        [ValidateSet('authParameter', 'dataParameter', 'url')]
        [Parameter(Mandatory = $true)]
        [string]$Field,

        # key, required unless field = url
        [ValidateNotNullOrWhiteSpace()]
        [string]$Key
    )

    process {
        $Props = [AdoCommandProperties]::New(@{
                Id         = $Id;
                Field = $Field;
                Key = $Key;
            })

        if ($Field -ne 'url' -and -not($Key)) {
            throw "Key parameter is required for $Field"
        }

        Write-Host "##vso[task.setendpoint $Props]$Value"
    }

}

function Set-AdoSecret {
    <#
    .SYNOPSIS
        Wrapper for ##vso[task.setsecret]value

    .DESCRIPTION
        The value is registered as a secret for the duration of the job. The value will be masked out from the logs from this point forward. This command is useful when a secret is transformed (e.g. base64 encoded) or derived.

        Note: Previous occurrences of the secret value will not be masked

    .EXAMPLE
        $Secret = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Env:OLDSECRET))
        Set-AdoSecret $Secret

        echo "##vso[task.setsecret]$Secret"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=bash#setsecret-register-a-value-as-a-secret
    #>
    [Alias("adosecret")]
    param(
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Value
    )

    Write-Host "##vso[task.setsecret]$Value"
}

function Set-AdoTaskCompletion {
    <#
    .SYNOPSIS
        Wrapper for ##vso[task.complete]current operation

    .DESCRIPTION
        Finish the timeline record for the current task, set task result and current operation. When result not provided, set result to succeeded.

    .EXAMPLE
        Set-AdoTaskCompletion DONE

        echo "##vso[task.complete result=Succeeded;]DONE"

    .EXAMPLE
        adocompletion -SucceededWithIssues

        echo "##vso[task.complete result=SucceededWithIssues;]"

    .EXAMPLE
        adocompletion -Failed

        echo "##vso[task.complete result=Failed;]"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=powershell#complete-finish-timeline
    #>
    [CmdletBinding()]
    [Alias("adocompletion")]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$Value = '',
        [switch]$SucceededWithIssues,
        [switch]$Failed
    )

    process {
        $Result = 'Succeeded'

        if ($SucceededWithIssues.IsPresent) { $Result = 'SucceededWithIssues' }
        elseif ($Failed.IsPresent) { $Result = 'Failed' }

        Write-Host "##vso[task.complete result=$Result;]$Value"
    }

}

function Set-AdoVariable {
    <#
    .SYNOPSIS
        Convienence function for writing variables out to host in a pipe-functionality friendly manner

    .EXAMPLE
        Set-AdoVariable myVarName "Hello World"

        echo "##vso[task.setvariable variable=myVarName]Hello World"

    .EXAMPLE
        & { ... some other script logic ... } | adovar myVarName -Output

        echo "##vso[task.setvariable variable=myVarName;isOutput=true]Hello World"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=powershell#setvariable-initialize-or-modify-the-value-of-a-variable
     #>
    [CmdletBinding()]
    [Alias('adovar')]
    param(
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [ValidateNotNullOrWhiteSpace()]
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [string]$Value,

        [switch]$Secret,
        [switch]$Readonly,
        [switch]$Output
    )

    process {
        $Properties = "variable=$Name"

        if ($Secret.IsPresent) { $Properties += ";isSecret=true" }
        if ($Readonly.IsPresent) { $Properties += ";isReadonly=true" }
        if ($Output.IsPresent) { $Properties += ";isOutput=true" }

        Write-Debug "Setting variable: '$Properties' to '$Value'"
        Write-Host "##vso[task.setvariable $Properties]$Value"
    }
}

function Trace-AdoProgress {
    <#
    .SYNOPSIS
        Convienence function for displaying progress for a given group of elements in a pipe-functionality friendly manner

    .EXAMPLE
        Trace-AdoProgress @('My first element', 'My second element', 'My third element') `
                          -AtCompletion { $_.Value + " Completed" }

    .EXAMPLE
        $Scriptblocks = @(
            { git fetch --prune },
            { git pull },
            { git merge develop },
            { git status }
        )
        Trace-AdoProgress $Scriptblocks -AtCompletion { $_.Value + " Completed" }

    .OUTPUTS
    PSObject

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=powershell#setprogress-show-percentage-completed
     #>
    [CmdletBinding()]
    [Alias("adoprogress")]
    param (
        [ValidateNotNullOrWhiteSpace()]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]$Value,

        # The statement to echo after iterated elements complete (returned value must be a string)
        # The $_ variable given to the scriptblock is [psobject]@{ Index = [int]; $Value = [string]
        # This scriptblock is intentionally invoked without context
        [ValidateNotNullOrEmpty()]
        [scriptblock]$AtCompletion,

        # The statement to echo before starting
        [string]$BeforeProgress,
        # The statement to echo after completion
        [string]$AfterProgress
    )

    process {
        if (-not [string]::IsNullOrWhiteSpace($BeforeProgress)) {
            Write-Host $BeforeProgress
        }

        Write-Host "##vso[task.setprogress value=0;]"

        $ContainsAtCompletion = $PSBoundParameters.ContainsKey('AtCompletion')
        $i = 0
        $Prev = $null;
        $Next = $null;
        for ($step = 100/$Value.Length; $step -le 100; $step+= 100/$Value.Length) {
            $Next = if (-not($i + 1 -lt $Value.Length)) { $null } else { $Value[$i + 1].ToString().Trim() }

            $Result = [psobject]@{
                Next = $Next;
                Previous = $Prev;
                Value = $(if ($Value[$i] -is [scriptblock]) { & $Value[$i] } else { $Value[$i] }) 2>&1
                Index = $i
            }
            $Prev = $Next

            $During = '{0}/{1} Completed' -f ($i + 1), $Value.Length
            if ($ContainsAtCompletion) {
                $AtCompletionScriptResult = $AtCompletion.InvokeWithContext($null, [psvariable]::new('_',
                    [psobject]@{ Index = $i; Value = $Value[$i].ToString().Trim()
                }))
                if ($AtCompletionScriptResult.Count -eq 1 -and $AtCompletionScriptResult[0] -is [string]) {
                    $During = $AtCompletionScriptResult[0]
                } elseif ($Value[$i] -is [scriptblock]) {
                    $During += " | Executed: {0}" -f $Value[$i].ToString().Trim()
                }
            }

            $Result | Write-Output
            "##vso[task.setprogress value={0:n0};]{1}" -f $step, $During | Write-Host
            $i = $i + 1
        }

        if (-not [string]::IsNullOrWhiteSpace($AfterProgress)) {
            Write-Host $AfterProgress
        }
    }
}

function Write-AdoIssue {
    <#
    .SYNOPSIS
        Wrapper for ##vso[task.logissue]error/warning message

    .DESCRIPTION
        Log an error or warning message in the timeline record of the current task.

    .EXAMPLE
        Write-AdoIssue "Foobar Error"

        echo "##vso[task.logissue type=error]Foobar Error"

    .EXAMPLE
        adoissue "Exception: StackOverflow" -SourcePath $SourceClassName -LineNumber 1 -ColumnNumber 5

        echo "##vso[task.logissue type=error;sourcepath=MyClass.java;linenumber=1;columnnumber=5]Exception: StackOverflow"

    .EXAMPLE
        adoissue "This is a warning" -Type warning

        echo "##vso[task.logissue type=warning]This is a warning"

    .OUTPUTS
    NONE

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=powershell#logissue-log-an-error-or-warning
     #>
    [Alias('adoissue')]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Message,

        # defaults to warning
        # possible values are error, warning
        [ValidateSet('error', 'warning')]
        [string]$Type = 'warning',

        [string]$SourcePath,
        [Alias("Line")]
        [string]$LineNumber,
        [Alias("Col")]
        [string]$ColumnNumber,
        [string]$Code
    )

    process {
        $Props = [AdoCommandProperties]::New(@{
                Type         = $Type;
                SourcePath = $SourcePath;
                LineNumber = $LineNumber;
                ColumnNumber = $ColumnNumber;
                Code = $Code;
            })

        Write-Host "##vso[task.logissue $Props]$Message"
    }
}

function Write-AdoLog {
    <#
    .SYNOPSIS
        Writes to host (and Output) channels a generic azure devops log clause while also echoing the input of each passed argument

    .DESCRIPTION
        The Write-AdoLog function aims to make ado logging a 1 line statement. Using this function will echo to host as well as echoing the passed in arguments.

        The default logging command is debug

        All logging types support -PassThru per normal -PassThru conventions. Otherwise this is used as a convience function to print what commands/scriptblocks/value you're about to execute in a pipeline and also then execute said command/scriptblock/value

    .EXAMPLE
        Write-AdoLog "Hello World"

        echo "##[debug]Hello World"

    .EXAMPLE
        "Hello World Section" | adolog -Type section

        echo "##[section]Hello World Section"

    .EXAMPLE
        adolog { node --version } -Type command

        echo "##[command]node --version"
        v18.16.0

    .EXAMPLE
        $Result = { node --version } | adolog -Type command -PassThru

        echo "##[command]node --version"
        v18.16.0

        In this example, by specifying -PassThru the result of the command `node --version` is written to host but also to the output channel (Write-Output) implicitly. Therefore you can use the result of the command later in your script if you need to. Otherwise this is used as a convience function to print what command you're about to execute in a pipeline and also execute it

        $Result -replace 'v18', 'v19' #outputs v19.16.0

    .EXAMPLE
        adolog { ls . } -Type group -Header "Current Working Directory"

        echo "##[group]Current Working Directory"
        folder1
        folder2
        file1.txt
        config.json
        echo "##[endgroup]"

    .INPUTS
    ANY

    .OUTPUTS
    ANY

    .LINK
        https://learn.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=powershell#formatting-commands
    #>
    [CmdletBinding()]
    [Alias('adolog')]
    param(
        # Value can be of any type. When value is of type scriptblock it is invoked using the call operator
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        [ValidateNotNullOrWhiteSpace()]
        $Value,

        # Any ado logging command. Defaults to debug. When Type is 'group' or 'section' pass a title to -Header parameter. See examples
        [ValidateNotNullOrEmpty()]
        [string]$Type = 'debug',

        # This parameter is only used for group & section logging command types
        [string]$Header = '',

        # Passes the resolved value of -Value to the powershell pipeline (Write-Output)
        [switch]$PassThru
    )

    process {
        switch ($Type.ToLower()) {
            group {
                Write-Host "##[group]$Header"
                $Result = $( if ($Value -is [scriptblock]) { & $Value } else { $Value } ) 2>&1

                if ($LASTEXITCODE -ne 0) {
                    Write-Error $Result
                }

                Write-Host $Result
                Write-Host "##[endgroup]"
            }
            { @('command','section') -contains $_ } {
                $Description = if ([string]::IsNullOrWhiteSpace($Header)) {
                    $ExecutionContext.InvokeCommand.ExpandString($MyInvocation.BoundParameters.Value).Trim()
                } else { $Header }

                Write-Host "##[$_]$Description"
                $Result = $( if ($Value -is [scriptblock]) { & $Value } else { $Value } ) 2>&1

                if ($LASTEXITCODE -ne 0) {
                    Write-Error $Result
                }

                Write-Host $Result
            }
            Default {
                Write-Host "##[$_]$Value"
            }
        }

        if ($PassThru.IsPresent) { $Result }
    }
}