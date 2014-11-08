# Copyright 2012 - 2014 Aaron Jensen
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
<#
.SYNOPSIS
Imports the Blade module.

.DESCRIPTION
Normally, you shouldn't need to import Blade.  Usually, you'll just call the `blade.ps1` script directly and it will import Blade for you.

If Blade is already imported, it will be removed and then re-imported.

.EXAMPLE
Import-Blade.ps1

Demonstrates how to import the Blade module.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
)

#Requires -Version 2
Set-StrictMode -Version 'Latest'
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

if( (Get-Module -Name 'Blade') )
{
    Remove-Module 'Blade' -Verbose:$false
}

Import-Module -Name (Join-Path -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition) -ChildPath 'Blade.psd1' -Resolve) -Verbose:$false

