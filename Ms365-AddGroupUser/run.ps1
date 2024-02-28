using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "Add User Distribution Group function triggered."

$err = ""

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

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
