<# 

Utility-SetFormattedEmail

This PowerShell script takes a message and renders an HTML formatted email

Parameters

    Message - text of message to place in email

JSON Structure

    {
        "Message": "This is the message"
    }

#>

using namespace System.Net

param($Request, $TriggerMetadata)

$body = @"

<p>The request you submitted has been processed.</p>
<p>$($Request.Body.Message)</p>
<p>If you have any questions on this request, please refer to ticket number # $($Request.Body.TicketId).</p>

"@

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "text/html"
})
