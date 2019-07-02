
<#
.SYNOPSIS
    Perform IIS rewrite http to https on remote machine. Code partly used from the blog 'https://dbaland.wordpress.com/2019/02/13/create-a-http-to-https-url-redirect-in-iis-with-powershell/'
.EXAMPLE
    Invoke-IISURLRewrite -SiteName 'ChocolateyCentralManagement' -ComputerName choco-3
#>
function Invoke-IISURLRewrite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SiteName,
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    process {
        Invoke-Command -ComputerName $ComputerName -ArgumentList $SiteName -ScriptBlock {
            try {
                Import-Module WebAdministration -ErrorAction Stop
            }
            catch {
                'Could not import IIS module'
                Exit
            }

            choco install urlrewrite -y
            if ($LASTEXITCODE -ne 0){
                'Could not install urlrewrite package'
                Exit
            }

            $webname= $Using:SiteName
            $rulename = $webname + ' http to https'
            $inbound = '(.*)'
            $outbound = 'https://{HTTP_HOST}{REQUEST_URI}'
            $site = 'IIS:\Sites\' + $webname
            $root = 'system.webServer/rewrite/rules'
            $filter = "{0}/rule[@name='{1}']" -f $root, $rulename
            Add-WebConfigurationProperty -PSPath $site -filter $root -name '.' -value @{name=$rulename; patterSyntax='Regular Expressions'; stopProcessing='True'}
            Set-WebConfigurationProperty -PSPath $site -filter "$filter/match" -name 'url' -value $inbound
            Set-WebConfigurationProperty -PSPath $site -filter "$filter/conditions" -name '.' -value @{input='{HTTPS}'; matchType='0'; pattern='^OFF$'; ignoreCase='True'; negate='False'}
            Set-WebConfigurationProperty -PSPath $site -filter "$filter/action" -name 'type' -value 'Redirect'
            Set-WebConfigurationProperty -PSPath $site -filter "$filter/action" -name 'url' -value $outbound
        }
    }
 }


