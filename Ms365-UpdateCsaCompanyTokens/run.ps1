<#

Ms365-UpdateCsaCompanyTokens

This script updates the company tokens in CloudRadial with the list of groups in the tenant.
 
Parameters

    companyId - numeric company id
    tenantId - string value of the tenant id, if blank uses the environment variable Ms365_TenantId

JSON Structure

    {
        "companyId": "12"
        "tenantId": "12345678-1234-1234-1234-123456789012"
    }

#>

using namespace System.Net

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

    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Body $bodyJson -Method Post

    Write-Host "API response: $($response | ConvertTo-Json -Depth 4)"
}

$companyId = $Request.Body.companyId
$tenantId = $Request.Body.tenantId

if (-Not $companyId) {
    $companyId = 1
}
if (-Not $tenantId) {
    $tenantId = $env:Ms365_TenantId
}

$secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
$credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $tenantId

# Get all groups in the tenant
$groupList = Get-MgGroup -All

# Extract group names
$groupNames = $groupList | Select-Object -ExpandProperty DisplayName

# Convert the array of group names to a comma-separated string
$groupNamesString = $groupNames -join ","

Set-GroupListToken -AppId $$env:CloudRadialCsa_ApiPublicKey -SecretId $env:CloudRadialCsa_ApiPrivateKey -CompanyId $companyId -GroupList $groupNamesString

Write-Host "Updatedfolders for Company Id: $companyId."

$body = @{
    response = "Company tokens for $comanyId have been updated."
} 

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
