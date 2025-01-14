# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#Requires -Version 4

$startedAt = Get-Date
function Write-Timing
{
    param(
        [Parameter(Position=0)]
        $Message
    )

    $now = Get-Date
    Write-Debug -Message ('[{0}]  [{1}]  {2}' -f $now,($now - $startedAt),$Message)
}

if( -not (Test-Path 'variable:IsWindows') )
{
    $IsWindows = $true
    $IsLinux = $IsMacOS = $false
}

Write-Timing ('BEGIN')
$carbonRoot = $PSScriptRoot
$CarbonBinDir = Join-Path -Path $PSScriptRoot -ChildPath 'bin' -Resolve
$carbonAssemblyDir = Join-Path -Path $CarbonBinDir -ChildPath 'fullclr' -Resolve
$warnings = @{}

# Used to detect how to manager windows features. Determined at run time to improve import speed.
$windowsFeaturesNotSupported = $null
$useServerManager = $null
$useOCSetup = $false
$supportNotFoundErrorMessage = 'Unable to find support for managing Windows features.  Couldn''t find servermanagercmd.exe, ocsetup.exe, or WMI support.'

$IsPSCore = $PSVersionTable['PSEdition'] -eq 'Core'
if( $IsPSCore )
{
    $carbonAssemblyDir = Join-Path -Path $CarbonBinDir -ChildPath 'coreclr' -Resolve
}

Write-Timing ('Loading Carbon assemblies from "{0}".' -f $carbonAssemblyDir)
Get-ChildItem -Path (Join-Path -Path $carbonAssemblyDir -ChildPath '*') -Filter 'Carbon*.dll' -Exclude 'Carbon.Iis.dll' |
    ForEach-Object { Add-Type -Path $_.FullName }

# Active Directory

# COM
$ComRegKeyPath = 'hklm:\software\microsoft\ole'

# IIS
$exportIisFunctions = $false
if( (Test-Path -Path 'env:SystemRoot') )
{
    Write-Timing ('Adding System.Web assembly.')
    Add-Type -AssemblyName "System.Web"
    $microsoftWebAdministrationPath = Join-Path -Path $env:SystemRoot -ChildPath 'system32\inetsrv\Microsoft.Web.Administration.dll'
    if( -not (Test-Path -Path 'env:CARBON_SKIP_IIS_IMPORT') -and `
        (Test-Path -Path $microsoftWebAdministrationPath -PathType Leaf) )
    {
        $exportIisFunctions = $true
        if( -not $IsPSCore )
        {
            Write-Timing ('Adding Microsoft.Web.Administration assembly.')
            Add-Type -Path $microsoftWebAdministrationPath
            Write-Timing ('Adding Carbon.Iis assembly.')
            Add-Type -Path (Join-Path -Path $carbonAssemblyDir -ChildPath 'Carbon.Iis.dll' -Resolve)
        }
    }
}

Write-Timing ('Adding System.ServiceProcess assembly.')
Add-Type -AssemblyName 'System.ServiceProcess'

if( $IsWindows )
{
    Write-Timing ('Adding System.ServiceProcess assembly.')
    Add-Type -AssemblyName 'System.Messaging'
}

#PowerShell
$TrustedHostsPath = 'WSMan:\localhost\Client\TrustedHosts'

# Users and Groups
Write-Timing ('Adding System.DirectoryServices.AccountManagement assembly.')
Add-Type -AssemblyName 'System.DirectoryServices.AccountManagement'

Write-Timing ('Dot-sourcing functions.')
$functionRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Functions' -Resolve

Get-ChildItem -Path (Join-Path -Path $functionRoot -ChildPath '*') -Filter '*.ps1' -Exclude '*Iis*','Initialize-Lcm.ps1' | 
    ForEach-Object { 
        . $_.FullName 
    }

function Write-CWarningOnce
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [String]$Message
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    if( $script:warnings[$Message] )
    {
        return
    }

    Write-Warning -Message $Message
    $script:warnings[$Message] = $true
}

$developerImports = & {
    Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psm1.Import.Iis.ps1' 
    Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psm1.Import.Lcm.ps1' 
    Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psm1.Import.Post.ps1' 
}
foreach( $developerImport in $developerImports )
{
    if( -not (Test-Path -Path $developerImport -PathType Leaf) )
    {
        continue
    }

    Write-Timing ('Dot-sourcing "{0}".' -f $developerImport)
    . $developerImport
}

# Allows us to be platform agnostic in our calls of 'GetAccessControl'.
if( -not ([IO.DirectoryInfo]::New([Environment]::CurrentDirectory) | Get-Member -Name 'GetAccessControl') )
{
    Update-TypeData -MemberName 'GetAccessControl' -MemberType 'ScriptMethod' -TypeName 'IO.DirectoryInfo' -Value {
        [CmdletBinding()]
        param(
            [Security.AccessControl.AccessControlSections]$IncludeSections = [Security.AccessControl.AccessControlSections]::All
        )
        
        return [IO.FileSystemAclExtensions]::GetAccessControl($this, $IncludeSections)
    }
}

if( -not ([IO.FileInfo]::New($PSCommandPath) | Get-Member -Name 'GetAccessControl') )
{
    Update-TypeData -MemberName 'GetAccessControl' -MemberType 'ScriptMethod' -TypeName 'IO.FileInfo' -Value {
        [CmdletBinding()]
        param(
            [Security.AccessControl.AccessControlSections]$IncludeSections = [Security.AccessControl.AccessControlSections]::All
        )
        
        return [IO.FileSystemAclExtensions]::GetAccessControl($this, $IncludeSections)
    }
}