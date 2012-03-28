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

function Get-PathToHostsFile
{
    <#
    .SYNOPSIS
    Gets the path to this computer's hosts file.
    #>
    return Join-Path $env:windir system32\drivers\etc\hosts
}

function Reset-HostsFile
{
    <#
    .SYNOPSIS
    Removes all custom host entries from this computer's hosts file.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
       [string]
       # The path to the hosts file to modify.  Defaults to the local computer's hosts file.
       $Path = (Get-PathToHostsFile)
    )
 
    if(-not (Test-Path $Path) )
    {
       Write-Warning "Creating hosts file '$Path'."
       New-Item $Path -ItemType File
    }
    
    $lines = @( Get-Content -Path $Path )
    $outLines = New-Object System.Collections.ArrayList
    foreach($line in $lines)
    {
     
        if($line.Trim().StartsWith("#") -or ($line.Trim() -eq '') )
        {
            [void] $outlines.Add($line)
        }
        else
        {
            break
        }
    }
    
    [void] $outlines.Add("127.0.0.1       localhost")
    
    if( $pscmdlet.ShouldProcess( $Path, "Reset-HostsFile" ) )
    {
        Write-Host "Clearing all hosts entries from '$Path'."
        $outlines | Out-File -FilePath $Path -Encoding OEM
    }
            
     
}

function Set-HostsEntry
{
    <#
    Sets a hosts entry in a hosts file.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern('\A(?:\b(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b)\Z')]
        # The IP address for the hosts entry.
        $IPAddress,

        [Parameter(Mandatory=$true)]
        # The hostname for the hosts entry.
        $HostName,

        [string]
        # An optional description of the hosts entry.
        $Description,

        [string]
        # The path to the hosts file where the entry should be set. Defaults to the local computer's hosts file.
        $Path = (Get-PathToHostsFile)
    )
 
    $matchPattern = '^(?<IP>[0-9a-f.:]+)\s+(?<HostName>[^\s#]+)(?<Tail>.*)$'  
    $lineFormat = "{0,-16}{1}{2}"
    
    if(-not (Test-Path $Path))
    {
        Write-Warning "Creating hosts file at: $Path"
        New-Item $Path -ItemType File
    }
     
    $lines = @( Get-Content -Path $Path )
    $outLines = New-Object System.Collections.ArrayList
    $found = $false
     
    foreach($line in $lines)
    {
     
        if($line.Trim().StartsWith("#") -or ($line.Trim() -eq '') )
        {
            [void] $outlines.Add($line)
        }
        elseif($line -match $matchPattern)
        {
            $ip = $matches["IP"]
            $hn = $matches["HostName"]
            $tail = $matches["Tail"].Trim()
            if($HostName -eq $hn)
            {
                if($found)
                {
                    #this is a duplicate so, let's comment it out
                    [void] $outlines.Add("#$line")
                    continue
                }
                $ip = $IPAddress
                $tail = if( $Description ) { "`t# $Description" } else { '' }
                $found = $true   
            }
           
            if($tail.Trim() -eq "#")
            {
                $tail = ""
            }
           
            $outline = $lineformat -f $ip, $hn, $tail
            [void] $outlines.Add($outline)
                
        }
        else
        {
            throw "Found invalid line '$line' in hosts file '$Path'."
        }

    }
     
    if(-not $found)
    {
       #add a new entry
       $tail = "`t# $Description"
       if($tail.Trim() -eq "#")
       {
           $tail = ""
       }
           
       $outline = $lineformat -f $IPAddress, $HostName, $tail
       [void] $outlines.Add($outline)
    }
    
    if( $pscmdlet.ShouldProcess( $Path, "set hosts entry $HostName to point to $IPAddress" ) )
    {
        $outlines | Out-File -FilePath $Path -Encoding OEM
    }
     
}
