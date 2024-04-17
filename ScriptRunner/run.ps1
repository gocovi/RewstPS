using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

try {
    if ($null -eq $Request.Body.script) {
        Write-Host "No script provided so will use the entire request body as the script".
        $ScriptBody = $Request.Body
    }
    else {
        Write-Host "Script was provided in the script property.".

        $ScriptBody = $Request.Body.script

        if ($Request.Body.input) {
            Write-Host "Input was provided so will convert the input object to variables".
            
            # Convert all of the properites in the input object to variables
            $Request.Body.input.GetEnumerator() | ForEach-Object {
                Set-Variable -Name $_.key -Value $_.value
            }
        }
    }

    if ($Request.Query.encoded -eq "true") {
        $ScriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ScriptBody))
    }
    else {
        $ScriptContent = $ScriptBody
    }

    $Result = $ScriptContent | Invoke-Expression

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK;
            Headers    = @{
                "Content-type" = "application/json"
            };
            Body       = @{ response = $Result } | ConvertTo-Json -Depth 99;
        })
}
catch {
    Write-Host $_.Exception.Message
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest;
            Headers    = @{
                "Content-type" = "application/json"
            };
            Body       = @{ error = $_.Exception.Message } | ConvertTo-Json -Depth 99;
        })
}