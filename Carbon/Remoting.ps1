# Copyright 2012 Aaron Jensen
# 
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

function Add-TrustedHosts
{
    <#
    .SYNOPSIS
    Adds an item to the computer's list of trusted hosts.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        # The computer name(s) to add to the trusted hosts
        $Entries
    )
    
    $trustedHosts = @( Get-TrustedHosts )
    $newEntries = @()
    
    foreach( $entry in $Entries )
    {
        if( $trustedHosts -notcontains $entry )
        {
            $trustedHosts += $entry 
            $newEntries += $entry
        }
    }
    
    if( $pscmdlet.ShouldProcess( "trusted hosts", "adding $( ($newEntries -join ',') )" ) )
    {
        Set-TrustedHosts -Entries $trustedHosts
    }
}

function Get-TrustedHosts
{
    <#
    .SYNOPSIS
    Returns the current computer's trusted hosts list.
    #>
    $trustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts -Force).Value 
    if( -not $trustedHosts )
    {
        return @()
    }
    
    return $trustedHosts -split ','
}


function Set-TrustedHosts
{
    <#
    .SYNOPSIS
    Sets the current computer's trusted hosts list.  Overwrites the existing list.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter()]
        [string[]]
        # An array of trusted host entries.
        $Entries = @()
    )
    
    $value = $Entries -join ','
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $Value -Force
}

