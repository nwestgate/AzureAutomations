using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
# Define variables

function Add-ConnectWiseInternalNote {
    param (
        [string]$ConnectWiseUrl,
        [string]$PublicKey,
        [string]$PrivateKey,
        [string]$TicketNumber,
        [string]$NoteContent,
        [string]$NoteType = "Internal"
    )

    # Construct the API endpoint for adding a note
    $apiUrl = "$ConnectWiseUrl/v4_6_release/apis/3.0/service/tickets/$TicketNumber/notes"

    # Create the note payload
    $notePayload = @{
        ticketId = $TicketNumber
        text = $NoteContent
        detailDescriptionFlag = $true
        internalAnalysisFlag = $false
    }

    $bodyJson = $notePayload | ConvertTo-Json

    Write-Host $bodyJson

 #   try {
        # Set up the authentication headers
        $headers = @{
            'Authorization' = 'Basic YnViYmxlbGlmZV9mK1ZWZTc3bFhaazZTSGhSajc6QkNLaEpyd2lOaUNYNWcyQg==' # "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${PublicKey}:${PrivateKey}"))
            'Content-Type' = 'application/json'
            'clientId' = 'be9644bd-c71a-4e94-91fc-792177756a4c'
        }

Write-host $apiUrl

        # Make the API request to add the note
     $result =   Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $bodyJson

     Write-Host $result

        Write-Host "Internal note added successfully to ticket $TicketNumber."
#    }
#    catch {
#        Write-Host "Error adding internal note: $($_.Exception.Message)"
#    }
}

# Example usage:
$connectWiseUrl = $env:ConnectWisePsa_ApiBaseUrl
$publicKey = "$env:ConnectWisePsa_ApiCompanyId+$env:ConnectWisePsa_ApiPublicKey"
$privateKey = $env:ConnectWisePsa_ApiPrivateKey
$ticketNumber = '' #Request.Body.TicketNumber
$noteContent = '' #Request.Body.Text
$noteType = '' #Request.Body.NoteType

Write-Host $connectWiseUrl

Write-Host $publicKey
Write-Host $privateKey

if (-Not $ticketNumber) {
 $ticketNumber = "7765"
}
if (-Not $noteContent) {
    $noteContent = "This is a sample note for ticket $ticketNumber."   
}

Add-ConnectWiseInternalNote -ConnectWiseUrl $connectWiseUrl -PublicKey $publicKey -PrivateKey $privateKey -TicketNumber $ticketNumber -NoteContent $noteContent


#$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

#if ($name) {
#    $body = "Hello, $name. This HTTP triggered function executed successfully."
#}

# Associate values to output bindings by calling 'Push-OutputBinding'.
#Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
#    StatusCode = [HttpStatusCode]::OK
#    Body = $body
#})
