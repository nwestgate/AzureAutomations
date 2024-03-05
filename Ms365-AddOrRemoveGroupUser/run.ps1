<# 

Ms365-AddOrRemoveGroupUser

This function is used to add or remove a user from a distribution group in Microsoft 365.

Parameters

    userEmail - user email address that exists in the tenant
    groupName - group name that exists in the tenant
    command - string value of "add" or "remove"
    tenantId - string value of the tenant id, if blank uses the environment variable Ms365_TenantId

JSON Structure

    {
        "userEmail": "email@address.com",
        "groupName": "Group Name",
        "command": "add",
        "tenantId": "12345678-1234-1234-1234-123456789012"
    }

#>

using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Add User Distribution Group function triggered."

$userEmail = $Request.Body.userEmail
$groupName = $Request.Body.groupName
$command = $Request.Body.command
$tenantId = $Request.Body.tenantId

if (-Not $userEmail) {
    Write-Host "userEmail cannot be blank."
    break
}
if (-Not $groupName) {
    Write-Host "groupName cannot be blank."
    break
}

if (-Not $tenantId) {
    $tenantId = $env:Ms365_TenantId
}

Write-Host "User Email: $userEmail"
Write-Host "Group Name: $groupName"
Write-Host "Tenant Id: $tenantId"

$secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
$credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $tenantId

$groupObject = Get-MgGroup -Filter "displayName eq '$groupName'"

Write-Host $groupObject.DisplayName
Write-Host $groupObject.Id

$userObject = Get-MgUser -Filter "userPrincipalName eq '$userEmail'"

Write-Host $userObject.userPrincipalName
Write-Host $userObject.Id

if (-Not $command) {
    $command = "add"
}

if ($command -eq "add") {
    New-MgGroupMember -GroupId $groupObject.Id -DirectoryObjectId $userObject.Id
}
else {
    if ($command -eq "remove") {
        Remove-MgGroupMember -GroupId $groupObject.Id -DirectoryObjectId $userObject.Id
    }
}

$body = @{
    response = "Group $groupName has been updated ($command) with user $userEmail."
} 

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
