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

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldProtectString
{
    $cipherText = Protect-String -String 'Hello World!'
    Assert-IsBase64EncodedString( $cipherText )
}

function Test-ShouldProtectStringWithScope
{
    $user = Protect-String -String 'Hello World' 
    $machine = Protect-String -String 'Hello World' -Scope LocalMachine
    Assert-NotEqual $user $machine 'encrypting at different scopes resulted in the same string'
}

function Test-ShouldProtectStringsInPipeline
{
    $secrets = @('Foo','Fizz','Buzz','Bar') | Protect-String 
    Assert-Equal 4 $secrets.Length 'Didn''t encrypt all items in the pipeline.'
    foreach( $secret in $secrets )
    {
        Assert-IsBase64EncodedString $secret
    }
}

function Assert-IsBase64EncodedString($String)
{
    Assert-NotEmpty $String 'Didn''t encrypt cipher text.'
    [Convert]::FromBase64String( $String )
}
