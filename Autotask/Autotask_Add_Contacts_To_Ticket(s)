<#[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$TicketId,
    
    [Parameter(Mandatory=$true)]
    [string[]]$EmailAddresses,
    
    [Parameter(Mandatory=$false)]
    [string]$AutotaskCompanyId
)

<##
.SYNOPSIS
    Adds multiple email addresses as additional contacts to an Autotask ticket.
.DESCRIPTION
    Takes an array of email addresses, finds the corresponding contact IDs in Autotask, 
    and adds them as additional contacts to the specified ticket.
    Required environment variables:
        AutotaskApiUsername - Autotask API username
        AutotaskApiSecret - Autotask API secret
        AutotaskApiIntegrationCode - Autotask API integration code
.PARAMETER TicketId
    The Autotask ticket ID to add contacts to
.PARAMETER EmailAddresses
    Array of email addresses to add as additional contacts
.PARAMETER AutotaskCompanyId
    Optional: Limit contact search to specific company
.EXAMPLE
    .\Add-ContactsToTicket.ps1 -TicketId "12345" -EmailAddresses @("user1@company.com", "user2@company.com")
#>

# Variables
$AutotaskApiUsername = "$env:AutotaskApiUsername"
$AutotaskApiSecret = "$env:AutotaskApiSecret"
$AutotaskIntegrationCode = "$env:AutotaskApiIntegrationCode"

# Validate environment variables
if (-not $AutotaskApiUsername -or -not $AutotaskApiSecret -or -not $AutotaskIntegrationCode) {
    Write-Error "Required environment variables are missing. Please set AutotaskApiUsername, AutotaskApiSecret, and AutotaskApiIntegrationCode."
    exit 1
}

try {
    # Get the correct endpoint for your Autotask instance
    $discoveryUrl = "https://webservices.autotask.net/ATServicesRest/V1.0/zoneInformation?user=$AutotaskApiUsername"
    $discoveryResponse = Invoke-RestMethod -Uri $discoveryUrl -Method GET
    $autotaskBaseUrl = $discoveryResponse.url
    Write-Host "Using Autotask API URL: $autotaskBaseUrl"

    # Set up headers with proper authentication
    $headersAutotask = @{
        'ApiIntegrationCode' = "$AutotaskIntegrationCode"
        'UserName'           = "$AutotaskApiUsername"
        'Secret'             = "$AutotaskApiSecret"
        'Content-Type'       = 'application/json'
    }

    # Step 1: Get current ticket details
    Write-Host "Fetching current ticket details for ticket ID: $TicketId"
    $ticketUrl = "$autotaskBaseUrl/Tickets/$TicketId"
    $currentTicket = Invoke-RestMethod -Uri $ticketUrl -Headers $headersAutotask -Method Get
    
    if (-not $currentTicket.item) {
        Write-Error "Ticket $TicketId not found."
        exit 1
    }

    Write-Host "Found ticket: $($currentTicket.item.title)"

    # Step 2: Find contact IDs for the provided email addresses
    $contactIds = @()
    $notFoundEmails = @()

    foreach ($email in $EmailAddresses) {
        Write-Host "Searching for contact with email: $email"
        
        # Build query filter
        $filterItems = @(
            @{
                "op" = "eq"
                "field" = "emailAddress"
                "value" = $email
            },
            @{
                "op" = "eq"
                "field" = "isActive"
                "value" = "true"
            }
        )

        # Add company filter if specified
        if ($AutotaskCompanyId) {
            $filterItems += @{
                "op" = "eq"
                "field" = "companyID"
                "value" = $AutotaskCompanyId
            }
        }

        $contactQueryBody = @{
            "filter" = @(
                @{
                    "op" = "and"
                    "items" = $filterItems
                }
            )
        } | ConvertTo-Json -Depth 5

        $contactUrl = "$autotaskBaseUrl/Contacts/query"
        $contactResponse = Invoke-RestMethod -Uri $contactUrl -Headers $headersAutotask -Method Post -Body $contactQueryBody -ContentType "application/json"
        
        if ($contactResponse.items -and $contactResponse.items.Count -gt 0) {
            $contact = $contactResponse.items[0]
            $contactIds += $contact.id
            Write-Host "Found contact: $($contact.firstName) $($contact.lastName) (ID: $($contact.id))"
        } else {
            $notFoundEmails += $email
            Write-Warning "Contact not found for email: $email"
        }
    }

    if ($notFoundEmails.Count -gt 0) {
        Write-Warning "The following email addresses were not found in Autotask:"
        $notFoundEmails | ForEach-Object { Write-Warning "  - $_" }
    }

    if ($contactIds.Count -eq 0) {
        Write-Error "No valid contacts found to add to the ticket."
        exit 1
    }

    # Step 3: Get existing additional contacts from the ticket
    $existingAdditionalContacts = @()
    if ($currentTicket.item.additionalContacts) {
        $existingAdditionalContacts = $currentTicket.item.additionalContacts
    }

    # Step 4: Add new contact IDs to existing ones (avoid duplicates)
    $allContactIds = @($existingAdditionalContacts)
    foreach ($contactId in $contactIds) {
        if ($contactId -notin $allContactIds) {
            $allContactIds += $contactId
        } else {
            Write-Host "Contact ID $contactId is already an additional contact on this ticket."
        }
    }

    # Step 5: Update the ticket with the new additional contacts
    if ($allContactIds.Count -gt $existingAdditionalContacts.Count) {
        Write-Host "Updating ticket with additional contacts..."
        
        $updateBody = @{
            "id" = $TicketId
            "additionalContacts" = $allContactIds
        } | ConvertTo-Json -Depth 3

        $updateResponse = Invoke-RestMethod -Uri $ticketUrl -Headers $headersAutotask -Method Patch -Body $updateBody -ContentType "application/json"
        
        if ($updateResponse.item) {
            Write-Host "Successfully updated ticket $TicketId with additional contacts."
            Write-Host "Total additional contacts now: $($allContactIds.Count)"
        } else {
            Write-Error "Failed to update ticket. Response: $($updateResponse | ConvertTo-Json)"
        }
    } else {
        Write-Host "No new contacts to add - all specified contacts are already additional contacts on this ticket."
    }

} catch {
    Write-Error "Error processing request: $_"
    if ($_.Exception.Response) {
        Write-Error "Status Code: $($_.Exception.Response.StatusCode.value__)"
        Write-Error "Status Description: $($_.Exception.Response.StatusDescription)"
    }
    exit 1
}
