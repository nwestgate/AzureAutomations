using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "Add User Distribution Group function triggered."

$error = ""

$userEmail = $Request.Body.userEmail
$groupName = $Request.Body.groupName
$command = $Request.Body.command

Write-Host "User Email: $userEmail"
Write-Host "Group Name: $groupName"

if (-Not $userEmail) {
    $error = "userEmail cannot be blank."
}
if (-Not $groupName) {
    $error = "groupName cannot be blank."
}

if ($error) {
    Write-Host $error
    break
}

$tenantId = $env:Azurative365AutomationsTenantId
$appId = $env:Azurative365AutomationsAppId
$appSecret = $env:Azurative365AutomationsAppSecretId

$securePassword = ConvertTo-SecureString -String $appSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($appId, $securePassword)

Connect-MgGraph -ClientSecretCredential $credential -TenantId $tenantId

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
