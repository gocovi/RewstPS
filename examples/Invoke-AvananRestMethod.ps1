<#
    These are the variables that you need to set in Rewst with as org variables or context in your workflows.
#>

$ApplicationID = "{{ ORG.VARIABLES.avanan_app_id }}"
$ApplicationSecret = "{{ ORG.VARIABLES.avanan_app_secret }}"

$Method = "{{ CTX.method }}"
$Path = "{{ CTX.url_path }}"
$Body = '{{ CTX.body }}'

function New-AvananSignature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RequestID,

        [Parameter(Mandatory = $true, HelpMessage = "Must be the same for every request.")]
        [string]
        $RequestDate,

        [Parameter()]
        [string]
        $RequestText = ""
    )

    # Calculating the signature
    $Request = $RequestID, $ApplicationID, $RequestDate, $RequestText, $ApplicationSecret -join ""
    $Base64Signature = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Request))
    $Hash = [System.Security.Cryptography.HashAlgorithm]::Create('sha256').ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Base64Signature))

    ([System.BitConverter]::ToString($Hash).Replace('-', '').ToLower())
}

function New-AvananAuthorization {
    $RequestID = (New-Guid).Guid
    $RequestDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss")

    $Signature = New-AvananSignature -RequestID $RequestID -RequestDate $RequestDate

    $Params = @{
        Headers = @{
            "Accept"      = "application/json";
            "x-av-req-id" = $RequestID;
            "x-av-token"  = "";
            "x-av-app-id" = $ApplicationID;
            "x-av-date"   = $RequestDate;
            "x-av-sig"    = $Signature;
        };
        Uri     = "https://smart-api-production-1-us.avanan.net/v1.0/auth";
    }

    (Invoke-RestMethod @Params)
}

function Invoke-AvananRestMethod {
    [CmdletBinding()]
    param (
        [Parameter(
            HelpMessage = "The path to the resource. Defaults to /v1.0/auth if not specified. Example: /v1.0/tenants"
        )]
        [string]
        $Path = "/v1.0/auth",

        # Parameter that allows GET, POST, PUT, DELETE, PATCH.
        [Parameter()]
        [ValidateSet("GET", "POST", "PUT", "DELETE", "PATCH")]
        [string]
        $Method = "GET",

        [Parameter]
        [string]
        $Body,

        [Parameter(Mandatory = $true)]
        [string]
        $Token
    )

    if (!$Token -and $Path -ne "/v1.0/auth") {
        throw "You must provide a token if you're not using the /v1.0/auth endpoint."
    }

    $RequestID = (New-Guid).Guid
    $RequestDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss")

    $Signature = New-AvananSignature -RequestID $RequestID -RequestDate $RequestDate -RequestText $Path

    $Params = @{
        Headers = @{
            "Accept"      = "application/json";
            "x-av-req-id" = $RequestID;
            "x-av-token"  = $Token;
            "x-av-app-id" = $ApplicationID;
            "x-av-date"   = $RequestDate;
            "x-av-sig"    = $Signature;
        };
        Method  = $Method;
        Uri     = "https://smart-api-production-1-us.avanan.net$Path";
    }

    if ($JSONBody) {
        $Params.Headers.Add("Body", $Body)
        $Params.Headers.Add("Content-Type", "application/json")
    }

    (Invoke-RestMethod @Params)
}

$Token = New-AvananAuthorization

$Params = @{
    Path   = $Path;
    Token  = $Token;
    Method = $Method;
}

if ($Method -ne "GET" -and $Body) {
    # Add body to params
    $Params.Add("Body", $Body)
}

Invoke-AvananRestMethod @Params