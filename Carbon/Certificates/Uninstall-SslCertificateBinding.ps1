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

function Remove-SslCertificateBinding
{
    <#
    .SYNOPSIS
    Removes an SSL certificate binding.
    
    .DESCRIPTION
    Uses the netsh command line application to remove an SSL certificate binding for an IP/port combination.  If the binding doesn't exist, nothing is changed.
    
    .EXAMPLE
    > Remove-SslCertificateBinding -IPPort 45.72.89.57:443
    
    Removes the SSL certificate bound to IP 45.72.89.57 on port 443.
    
    .EXAMPLE
    > Remove-SslCertificateBinding -IPPort 0.0.0.0:443
    
    Removes the default SSL certificate from port 443.  The default certificate is bound to all IP addresses.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The IP address and port to bind the SSL certificate to.  Should be in the form IP:port.
        # Use 0.0.0.0 for all IP addresses.  For example formats, run
        # 
        #    >  netsh http delete sslcert /?
        $IPPort
    )
    
    if( -not (Test-SslCertificateBinding -IPPort $IPPort) )
    {
        return
    }
    
    if( $pscmdlet.ShouldProcess( $IPPort, "removing SSL certificate binding" ) )
    {
        Write-Host "Removing SSL certificate binding for $IPPort."
        netsh http delete sslcert ipport=$IPPort
    }
}
