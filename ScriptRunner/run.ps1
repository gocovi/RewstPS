using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -Path "~/tmp")) {
    New-Item -Path "~/tmp" -ItemType Directory | Out-Null
}

$ScriptGuid = [Guid]::NewGuid().ToString()
$ScriptFilePath = "~/tmp/$ScriptGuid.ps1"

try {
    if ($null -eq $Request.Body.script) {
        Write-Host "No script provided so will use the entire request body as the script"
        $ScriptBody = $Request.Body
    }
    else {
        Write-Host "Script was provided in the script property"

        $ScriptBody = $Request.Body.script
    }

    if ($Request.Query.encoded -eq "true") {
        $ScriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ScriptBody))
    }
    else {
        $ScriptContent = $ScriptBody
    }

    # Used to get parameters from script
    $ScriptWrapper = @"
function Test-Script {
    $ScriptContent
}

(Get-Command Test-Script).Parameters
"@

    $InputParameters = @{}

    if ($Request.Body.input) {
        Write-Host "Input was provided so will convert the input object to variables"
            
        # Convert all of the properites in the input object to variables
        $Request.Body.input.GetEnumerator() | ForEach-Object {
            Set-Variable -Name $_.key -Value $_.value
        }

        # Setting input parameters from
        (Invoke-Expression -Command $ScriptWrapper).GetEnumerator() | ForEach-Object {
            if ($Request.Body.input.ContainsKey($_.Key)) {
                $InputParameters.Add($_.Key, $Request.Body.input[$_.Key])
            }
        }
    }

    # Save script to a temporary file
    $ScriptContent | Out-File -FilePath $ScriptFilePath
    $Result = . $ScriptFilePath @InputParameters

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK;
            Headers    = @{
                "Content-type" = "application/json"
            };
            Body       = @{ response = $Result } | ConvertTo-Json -Depth 99;
        })
}
catch {
    if ((Test-Path -Path $ScriptFilePath)) {
        Remove-Item -Path $ScriptFilePath
    }

    Write-Host $_.Exception.Message
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest;
            Headers    = @{
                "Content-type" = "application/json"
            };
            Body       = @{ error = $_.Exception.Message } | ConvertTo-Json -Depth 99;
        })
}