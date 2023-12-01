$Request = "{{ CTX.request }}"
$Base64Signature = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Request))
$Hash = [System.Security.Cryptography.HashAlgorithm]::Create('sha256').ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Base64Signature))
([System.BitConverter]::ToString($Hash).Replace('-', '').ToLower())