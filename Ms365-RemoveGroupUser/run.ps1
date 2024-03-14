<# 

.SYNOPSIS
    
    This function is used to remove a user from a distribution group in Microsoft 365.

.DESCRIPTION
            
        This function is used to remove a user from a distribution group in Microsoft 365.
        
        The function requires the following environment variables to be set:
        
        Ms365_AuthAppId - Application Id of the service principal
        Ms365_AuthSecretId - Secret Id of the service principal
        Ms365_TenantId - Tenant Id of the Microsoft 365 tenant
        
        The function requires the following modules to be installed:
        
        Microsoft.Graph

.INPUTS

    UserEmail - user email address that exists in the tenant
    GroupName - group name that exists in the tenant
    TenantId - string value of the tenant id, if blank uses the environment variable Ms365_TenantId
    TicketId - optional - string value of the ticket id used for transaction tracking

    JSON Structure

    {
        "UserEmail": "email@address.com",
        "GroupName": "Group Name",
        "TenantId": "12345678-1234-1234-123456789012",
        "TicketId": "123456
    }

.OUTPUTS

    Message - Descriptive string of result
    TicketId - TicketId passed in Parameters
    ResultCode - 200 for success, 500 for failure
    ResultStatus - "Success" or "Failure"

#>

using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Add User to Group function triggered."

$resultCode = 200
$message = ""

$UserEmail = $Request.Body.UserEmail
$GroupName = $Request.Body.GroupName
$TenantId = $Request.Body.TenantId
$TicketId = $Request.Body.TicketId

if (-Not $userEmail) {
    $message = "UserEmail cannot be blank."
    $resultCode = 500
}
else {
    $UserEmail = $UserEmail.Trim()
}

if (-Not $groupName) {
    $message = "GroupName cannot be blank."
    $resultCode = 500
}
else {
    $GroupName = $GroupName.Trim()
}

if (-Not $TenantId) {
    $TenantId = $env:Ms365_TenantId
}
else {
    $TenantId = $TenantId.Trim()
}

if (-Not $TicketId) {
    $TicketId = ""
}

Write-Host "User Email: $UserEmail"
Write-Host "Group Name: $GroupName"
Write-Host "Tenant Id: $TenantId"
Write-Host "Ticket Id: $TicketId"

if ($resultCode -Eq 200)
{
    $secure365Password = ConvertTo-SecureString -String $env:Ms365_AuthSecretId -AsPlainText -Force
    $credential365 = New-Object System.Management.Automation.PSCredential($env:Ms365_AuthAppId, $secure365Password)

    Connect-MgGraph -ClientSecretCredential $credential365 -TenantId $TenantId

    $GroupObject = Get-MgGroup -Filter "displayName eq '$GroupName'"

    Write-Host $GroupObject.DisplayName
    Write-Host $GroupObject.Id

    $UserObject = Get-MgUser -Filter "userPrincipalName eq '$UserEmail'"

    Write-Host $UserObject.userPrincipalName
    Write-Host $UserObject.Id

    if (-Not $GroupObject) {
        $message = "Request failed. Group `"$GroupName`" could not be found to add user `"$UserEmail`" to."
        $resultCode = 500
    }

    if (-Not $UserObject) {
        $message = "Request failed. User `"$UserEmail`" not be found to add to group `"$GroupName`"."
        $resultCode = 500
    }

    $GroupMembers = Get-MgGroupMember -GroupId $GroupObject.Id

    if ($GroupMembers.Id -NotContains $UserObject.Id) {
        $message = "Request failed. User `"$UserEmail`" is not a member of group `"$GroupName`"."
        $resultCode = 500
    } 

    if ($resultCode -Eq 200) {
        Remove-MgGroupMember -GroupId $GroupObject.Id -DirectoryObjectId $UserObject.Id
        $message = "Request completed. `"$UserEmail`" has been removed from group `"$GroupName`"."
    }
}

$body = @{
    Message = $message
    TicketId = $TicketId
    ResultCode = $resultCode
    ResultStatus = if ($resultCode -eq 200) { "Success" } else { "Failure" }
} 

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
