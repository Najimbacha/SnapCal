[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BillingAccount,
    [Parameter(Mandatory)][string]$OwnerEmailChannel,
    [switch]$Apply
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($OwnerEmailChannel -notmatch '^projects/snapcal-ef333/notificationChannels/[0-9]+$') {
    throw 'Supply the verified owner email notification-channel resource from Cloud Monitoring.'
}
function Read-Gcloud([string[]]$Arguments) {
    $output = & gcloud @Arguments --format=json --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Budget preflight failed.' }
    return ($output -join "`n" | ConvertFrom-Json)
}
$project = Read-Gcloud @('projects','describe','snapcal-ef333')
$billing = Read-Gcloud @('billing','projects','describe','snapcal-ef333')
if (!$billing.billingEnabled -or $billing.billingAccountName -ne "billingAccounts/$BillingAccount") { throw 'Billing account does not match this project.' }
$token = (& gcloud auth print-access-token --quiet) -join ''
if ($LASTEXITCODE -ne 0) { throw 'Sign in to Google Cloud first.' }
try {
    $channel = Invoke-RestMethod -Uri "https://monitoring.googleapis.com/v3/$OwnerEmailChannel" -Headers @{Authorization="Bearer $token"}
} finally { $token = $null }
if ($channel.type -ne 'email' -or !$channel.enabled) { throw 'Budget recipient must be an enabled email channel.' }
$existing = @(Read-Gcloud @('billing','budgets','list',"--billing-account=$BillingAccount") | Where-Object { $_.displayName -eq 'SnapCal project monthly USD25' })
if ($existing.Count -gt 1) { throw 'Duplicate budgets exist. Resolve them in Billing before retrying.' }
$command = if ($existing.Count -eq 1) { @('billing','budgets','update',$existing[0].name.Split('/')[-1]) } else { @('billing','budgets','create') }
$arguments = $command + @("--billing-account=$BillingAccount",'--display-name=SnapCal project monthly USD25',
    '--budget-amount=25USD','--calendar-period=month',"--filter-projects=projects/$($project.projectNumber)",
    "--notifications-rule-monitoring-notification-channels=$OwnerEmailChannel")
if ($existing.Count -eq 1) {
    $arguments += @('--clear-threshold-rules', '--add-threshold-rule=percent=0.5,basis=current-spend',
        '--add-threshold-rule=percent=0.8,basis=current-spend','--add-threshold-rule=percent=1.0,basis=current-spend')
} else {
    $arguments += @('--threshold-rule=percent=0.5,basis=current-spend',
        '--threshold-rule=percent=0.8,basis=current-spend','--threshold-rule=percent=1.0,basis=current-spend')
}
Write-Host 'Project-wide monthly budget: USD25, alerts at USD12.50 / USD20 / USD25.'
Write-Host 'Alerts do not stop spending. External AI providers are billed separately.'
if (!$Apply) { Write-Host 'Preflight only. Use -Apply to create or update this named budget.'; return }
& gcloud @arguments --quiet
if ($LASTEXITCODE -ne 0) { throw 'Budget update failed. Verify billing-account currency supports USD.' }
$verified = @(Read-Gcloud @('billing','budgets','list',"--billing-account=$BillingAccount") | Where-Object { $_.displayName -eq 'SnapCal project monthly USD25' })
if ($verified.Count -ne 1) { throw 'Budget was not found after update.' }
$budget = $verified[0]
$thresholds = @($budget.thresholdRules | ForEach-Object { [double]$_.thresholdPercent } | Sort-Object)
$notificationRule = if ($budget.PSObject.Properties['notificationsRule']) {
    $budget.notificationsRule
} elseif ($budget.PSObject.Properties['allUpdatesRule']) {
    $budget.allUpdatesRule
} else {
    $null
}
if ($budget.amount.specifiedAmount.currencyCode -ne 'USD' -or $budget.amount.specifiedAmount.units -ne '25' -or
    ($thresholds -join ',') -ne '0.5,0.8,1' -or
    (@($budget.budgetFilter.projects) -join ',') -ne "projects/$($project.projectNumber)" -or
    !$notificationRule -or
    $OwnerEmailChannel -notin @($notificationRule.monitoringNotificationChannels)) { throw 'Budget verification failed.' }
foreach ($name in @('services','labels','subaccounts','resourceAncestors')) {
    $property = $budget.budgetFilter.PSObject.Properties[$name]
    if ($property -and $property.Value -and @($property.Value).Count -gt 0) { throw "Unexpected budget filter: $name. Budget must cover the whole project." }
}
Write-Host 'Budget and owner email destination verified. Confirm a test notification reaches the owner in Monitoring.'
