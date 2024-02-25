
# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

function Set-GroupListToken {
    param (
        [string]$AppId,
        [string]$SecretId,
        [int]$CompanyId,
        [string]$GroupList
    )

    # Construct the basic authentication header
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${AppId}:${SecretId}"))
    $headers = @{
        "Authorization" = "Basic $base64AuthInfo"
        "Content-Type" = "application/json"
    }

    $body = @{
        "companyId" = $CompanyId
        "token" = "CompanyGroups"
        "value" = "$GroupList"
    }

    $bodyJson = $body | ConvertTo-Json

    # Replace the following URL with the actual REST API endpoint
    $apiUrl = "https://api.us.cloudradial.com/api/beta/token"

    # Make the REST API request
    #    try {
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Body $bodyJson -Method Post
    # Process the response as needed (e.g., parse JSON, handle errors, etc.)
    Write-Host "API response: $($response | ConvertTo-Json -Depth 4)"
    #    } catch {
    #        Write-Host "Error occurred: $($_.Exception.Message)"
    #    }
}

$companyId = $Request.Body.companyId
if (-Not $companyId) {
    $companyId = 1
}

$secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
$credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $env:Ms365_TenantId

# Get all groups in the tenant
$groupList = Get-MgGroup -All

# Extract group names
$groupNames = $groupList | Select-Object -ExpandProperty DisplayName

# Convert the array of group names to a comma-separated string
$groupNamesString = $groupNames -join ","

Set-GroupListToken -AppId $$env:CloudRadialCsa_ApiPublicKey -SecretId $env:CloudRadialCsa_ApiPrivateKey -CompanyId $companyId -GroupList $groupNamesString


# Write to the Azure Functions log stream.
Write-Host "Updating folders for Company Id: $companyId."

$body = @{
    text = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."
} 

if ($name) {
    $body.text = "Hello, $name. This HTTP triggered function executed successfully."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
