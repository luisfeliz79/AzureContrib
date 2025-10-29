$TableName = "routes"
$WorkspaceResourceId = "/subscriptions/<subscription_id>/resourcegroups/<resource_group_name>/providers/microsoft.operationalinsights/workspaces/<workspace_name>"

# Tablename must end with _CL
if ($TableName -notmatch "_CL") {
    $TableName = "$($TableName)_CL"
}

# Create a powershell object instead then convert to JSON
$tableParams = [PSCustomObject]@{
    properties = @{
        schema = @{
            name = $TableName
            columns = @(
                @{ name = "TimeGenerated"; type = "datetime"; description = "The time at which the data was ingested." },
                @{ name = "RouteType"; type = "string"; description = "The type of log entry" },
                @{ name = "RouteServerName"; type = "string"; description = "The name of the route server." },
                @{ name = "ResourceGroupName"; type = "string"; description = "The name of the resource group." },
                @{ name = "PeerName"; type = "string"; description = "The name of the peer." },
                @{ name = "PeerASN"; type = "string"; description = "The ASN of the peer." },
                @{ name = "RSInstance"; type = "string"; description = "The instance of the route server." },
                @{ name = "Network"; type = "string"; description = "The network associated with the route." },
                @{ name = "NextHop"; type = "string"; description = "The next hop for the route." },
                @{ name = "Origin"; type = "string"; description = "The origin of the route." },
                @{ name = "SourcePeer"; type = "string"; description = "The source peer for the route." },
                @{ name = "AsPath"; type = "string"; description = "The AS path for the route." },
                @{ name = "Weight"; type = "int"; description = "" },
                @{ name = "RunId"; type = "string"; description = "The run ID for the operation." }
            )
        }
    }
} | ConvertTo-Json -Depth 10

$tableParams

Invoke-AzRestMethod -Path "$WorkspaceResourceId/tables/$($TableName)?api-version=2021-12-01-preview" -Method PUT -payload $tableParams

