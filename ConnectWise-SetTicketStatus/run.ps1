<# 

ConnectWise-SetTicketStatus

This PowerShell script sets the status of a ConnectWise ticket based on the result code.

Parameters

    TicketId - string value of numeric ticket number
    ResultCode - numeric value of result code, 200 = success
    StatusClosed - text value of ticket status if result code indicated success
    StatusOpen - text value of ticket status if esult code indicated failure

JSON Structure

    {
        "TicketId": "123456",
        "StatusClosed": "Closed",
        "StatusOpen": "New"
    }

#>

using namespace System.Net

param($Request, $TriggerMetadata)

function Set-ConnectWiseTicketStatus {
    param (
        [string]$ConnectWiseUrl,
        [string]$PublicKey,
        [string]$PrivateKey,
        [string]$ClientId,
        [string]$TicketId,
        [string]$Status
    )

    # Construct the API endpoint for adding a note
    $apiUrl = "$ConnectWiseUrl/v4_6_release/apis/3.0/service/tickets/$TicketId"

    $statusPayload = @{
        status = @{
            name = $Status
        }
    } | ConvertTo-Json
    
    # Set up the authentication headers
    $headers = @{
        "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${PublicKey}:${PrivateKey}"))
        "Content-Type" = "application/json"
        "clientId" = $ClientId
    }

    # Make the API request to add the note
    $result = Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers $headers -Body $statusPayload
    Write-Host $result
    return $result
}

$TicketId = $Request.Body.TicketId
$StatusClosed = $Request.Body.StatusClosed
$StatusOpen = $Request.Body.StatusOpen

if (-Not $TicketId) {
    Write-Host "Missing ticket number"
    break;
}
if (-Not $StatusClosed) {
    Write-Host "Missing status closed value"
    break;
}
if (-Not $StatusOpen) {
    Write-Host "Missing status open value"
    break;
}

if ($Request.Body.ResultCode -eq 200) {
    $Status = $StatusClosed
}
else {
    $Status = $StatusOpen
}

Write-Host "TicketId: $TicketId"
Write-Host "StatusOpen: $StatusOpen"
Write-Host "StatusClosed: $StatusClosed"
Write-Host "Status: $Status"

$result = Set-ConnectWiseTicketStatus -ConnectWiseUrl $env:ConnectWisePsa_ApiBaseUrl `
    -PublicKey "$env:ConnectWisePsa_ApiCompanyId+$env:ConnectWisePsa_ApiPublicKey" `
    -PrivateKey $env:ConnectWisePsa_ApiPrivateKey `
    -ClientId $env:ConnectWisePsa_ApiClientId `
    -TicketId $TicketId `
    -Status = $Status

Write-Host $result.Message

$body = @{
    response = $result | ConvertTo-Json;
} 

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
