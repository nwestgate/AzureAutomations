# ConnectWise-AddTicketNote
# Parameters:
#  ticketId - string value of numeric ticket number
#  text - text of note to add
#  internal - boolean indicating whether not should be internal only

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
# Define variables

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
    $apiUrl = "$ConnectWiseUrl/v4_6_release/apis/3.0/service/tickets/$TicketNumber/notes"

    # Create the note serviceObject
    $notePayload = @{
        ticketId = $TicketId
        text = $Text
        detailDescriptionFlag = $true
        internalAnalysisFlag = $Internal
    } | ConvertTo-Json
    
    # Set up the authentication headers
    $headers = @{
        "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${PublicKey}:${PrivateKey}"))
        "Content-Type" = "application/json"
        "clientId" = $ClientId
    }

    try {
        # Make the API request to add the note
        $result =   Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $notePayload
        Write-Host $result
        return @{
            StatusCode = 200
            Message = "Note added successfully to ticket $TicketNumber."
        }
    }
    catch {
        return @{
            StatusCode = 500
            Message = "Error adding internal note: $($_.Exception.Message)"
        }
    } 
}

# Example usage:
$ticketId =  Request.Body.ticketId
$text = Request.Body.text
$internal = Request.Body.internal

if (-Not $ticketNumber) {
    Write-Host "Missing ticket number"
    break;
}
if (-Not $noteContent) {
    Write-Host "Missing ticket text"
    break;
}
if (-Not $internal) {
    $internal = $false
}

$result = Add-ConnectWiseNote -ConnectWiseUrl $env:ConnectWisePsa_ApiBaseUrl `
    -PublicKey "$env:ConnectWisePsa_ApiCompanyId+$env:ConnectWisePsa_ApiPublicKey" `
    -PrivateKey $env:ConnectWisePsa_ApiPrivateKey `
    -ClientId $env:ConnectWisePsa_ApiClientId `
    -TicketId $ticketId `
    -Text $text `
    -Internal

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $result
})
