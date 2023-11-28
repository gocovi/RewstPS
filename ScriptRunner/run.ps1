using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

try {
    if ($Request.Query.encoded -eq "true") {
        $ScriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Request.Body))
    }
    else {
        $ScriptContent = $Request.Body
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