using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

if (!$Request.Query.algorithm -or !$Request.Query.content) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest;
            Headers    = @{
                "Content-type" = "application/json"
            };
            Body       = @{ error = "Missing Algorithm and or Content" } | ConvertTo-Json;
        })
}
else {
    $Hash = [System.Security.Cryptography.HashAlgorithm]::Create($Request.Query.algorithm.ToLower()).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Request.Query.content))
    
    $Result = ([System.BitConverter]::ToString($Hash).Replace('-', '').ToLower())

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK;
            Headers    = @{
                "Content-type" = "application/json"
            };
            Body       = @{ result = $Result } | ConvertTo-Json;
        })
}