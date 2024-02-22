using namespace System.Net

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

$tenantId = $env:Azurative365AutomationsTenantId
$appId = $env:Azurative365AutomationsAppId
$appSecret = $env:Azurative365AutomationsAppSecretId

$securePassword = ConvertTo-SecureString -String $appSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($appId, $securePassword)

Connect-MgGraph -ClientSecretCredential $credential -TenantId $tenantId

# Get all groups in the tenant
$groupList = Get-MgGroup -All

# Extract group names
$groupNames = $groupList | Select-Object -ExpandProperty DisplayName

# Convert the array of group names to a comma-separated string
$groupNamesString = $groupNames -join ", "

# Example usage:
$cloudRadialPublicKey = $env:CloudRadialApiPublicKey
$cloudRadialSecretKey = $env:CloudRadialApiSecretKey
Set-GroupListToken -AppId $cloudRadialPublicKey -SecretId $cloudRadialSecretKey -CompanyId $companyId -GroupList $groupNamesString


# Write to the Azure Functions log stream.
Write-Host "Updating folders for Company Id: $companyId."

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
