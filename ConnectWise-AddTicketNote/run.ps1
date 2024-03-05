<# 

ConnectWise-AddTicketNote

This PowerShell script adds a note to a ConnectWise ticket.

Parameters

    ticketId - string value of numeric ticket number
    text - text of note to add
    internal - boolean indicating whether not should be internal only

JSON Structure

    {
        "ticketId": "123456",
        "text": "This is a note",
        "internal": true
    }

#>

using namespace System.Net

param($Request, $TriggerMetadata)

function Add-ConnectWiseNote {
    param (
        [string]$ConnectWiseUrl,
        [string]$PublicKey,
        [string]$PrivateKey,
        [string]$ClientId,
        [string]$TicketId,
        [string]$Text,
        [boolean]$Internal = $false
    )

    # Construct the API endpoint for adding a note
    $apiUrl = "$ConnectWiseUrl/v4_6_release/apis/3.0/service/tickets/$TicketId/notes"

    # Create the note serviceObject
    $notePayload = @{
        ticketId = $TicketId
        text = $Text
        detailDescriptionFlag = $true
        internalAnalysisFlag = $Internal
        #resolutionFlag 
        #customerUpdatedFlag
    } | ConvertTo-Json
    
    # Set up the authentication headers
    $headers = @{
        "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${PublicKey}:${PrivateKey}"))
        "Content-Type" = "application/json"
        "clientId" = $ClientId
    }

    # Make the API request to add the note
    $result = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $notePayload
    Write-Host $result
    return $result
}

$ticketId = $Request.Body.ticketId
$text = $Request.Body.text
$internal = $Request.Body.internal

if (-Not $ticketId) {
    Write-Host "Missing ticket number"
    break;
}
if (-Not $text) {
    Write-Host "Missing ticket text"
    break;
}
if (-Not $internal) {
    $internal = $false
}

Write-Host "TicketId: $ticketId"
Write-Host "Text: $text"
Write-Host "Internal: $internal"

$result = Add-ConnectWiseNote -ConnectWiseUrl $env:ConnectWisePsa_ApiBaseUrl `
    -PublicKey "$env:ConnectWisePsa_ApiCompanyId+$env:ConnectWisePsa_ApiPublicKey" `
    -PrivateKey $env:ConnectWisePsa_ApiPrivateKey `
    -ClientId $env:ConnectWisePsa_ApiClientId `
    -TicketId $ticketId `
    -Text $text `
    -Internal $internal

Write-Host $result.Message

$body = @{
    response = $result | ConvertTo-Json;
} 

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "application/json"
})
