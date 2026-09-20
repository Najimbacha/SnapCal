# Runs with mocked gcloud/HTTP only. No account, network, or cloud mutations.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$global:snapcalTestCalls = [System.Collections.Generic.List[object]]::new()
$global:snapcalTestMaxInstances = 3
$global:snapcalTestBudgetExists = $false
$global:snapcalTestChannel = 'projects/snapcal-ef333/notificationChannels/123'
function Assert-True($Condition, [string]$Message) { if (!$Condition) { throw $Message } }
function gcloud {
    $a = @($args)
    $global:snapcalTestCalls.Add($a)
    $global:LASTEXITCODE = 0
    $result = switch ($a[0] + ' ' + $a[1]) {
        'billing projects' { @{ billingEnabled=$true; billingAccountName='billingAccounts/TEST' }; break }
        'services list' { @('run','cloudbuild','artifactregistry','secretmanager','firestore') | ForEach-Object { @{ config=@{ name="$_.googleapis.com" } } }; break }
        'firestore databases' { @{ locationId='nam5' }; break }
        'iam service-accounts' { @{ disabled=$false }; break }
        'secrets versions' { @{ state='ENABLED' }; break }
        'projects describe' { @{ projectNumber='123456' }; break }
        'auth print-access-token' { return 'mock-access-token' }
        'run deploy' { return }
        'billing budgets' {
            if ($a[2] -in @('create','update')) { $global:snapcalTestBudgetExists=$true; return }
            if (!$global:snapcalTestBudgetExists) { return '[]' }
            @(@{ name='billingAccounts/TEST/budgets/test-budget'; displayName='SnapCal project monthly USD25';
                amount=@{specifiedAmount=@{currencyCode='USD'; units='25'}};
                budgetFilter=@{projects=@('projects/123456')};
                thresholdRules=@(@{thresholdPercent=0.5},@{thresholdPercent=0.8},@{thresholdPercent=1.0});
                allUpdatesRule=@{monitoringNotificationChannels=@($global:snapcalTestChannel)} })
            break
        }
        default { throw "Unexpected gcloud command $($a -join ' ')" }
    }
    ConvertTo-Json -InputObject $result -Depth 12 -Compress
}
function Invoke-RestMethod {
    param($Uri, $Headers, $TimeoutSec)
    if ($Uri -like '*monitoring.googleapis.com*') { return [pscustomobject]@{ type='email'; enabled=$true } }
    if ($Uri -like '*/startup') { return [pscustomobject]@{status='started'} }
    if ($Uri -like '*/health') { return [pscustomobject]@{ status='ok'; scan=@{costControls=@{sharedCacheReady=$true}}; billing=@{webhookConfigured=$true;restVerificationConfigured=$true} } }
    $template = Get-Content (Join-Path $global:snapcalTestBackend 'deploy/cloud-run.example.json') -Raw | ConvertFrom-Json
    $environment = @($template.env.PSObject.Properties | ForEach-Object { @{name=$_.Name; value=$_.Value} })
    $environment += @($template.secrets.PSObject.Properties | ForEach-Object {
        $parts=$_.Value.Split(':'); @{name=$_.Name; valueSource=@{secretKeyRef=@{secret=$parts[0];version=$parts[1]}}}
    })
    return [pscustomobject]@{ uri='https://mock.example'; scaling=@{ minInstanceCount=1;maxInstanceCount=$global:snapcalTestMaxInstances };
        template=@{ maxInstanceRequestConcurrency=20;timeout='120s';serviceAccount='snapcal-run@snapcal-ef333.iam.gserviceaccount.com';
            containers=@(@{ env=$environment; resources=@{limits=@{cpu='1';memory='1Gi'};cpuIdle=$true} }) } }
}
$backend = Split-Path $PSScriptRoot -Parent
$global:snapcalTestBackend = $backend
$configPath = Join-Path ([System.IO.Path]::GetTempPath()) ("snapcal-script-test-" + [guid]::NewGuid() + '.json')
try {
    $config = Get-Content (Join-Path $backend 'deploy/cloud-run.example.json') -Raw | ConvertFrom-Json
    $config.region='us-central1'; $config.firestoreLocation='nam5'
    [System.IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 10))
    $deploy = Join-Path $backend 'deploy/deploy-cloud-run.ps1'
    & $deploy -ConfigPath $configPath
    Assert-True (@($global:snapcalTestCalls | Where-Object { $_[0] -eq 'run' }).Count -eq 0) 'Preflight must not deploy.'
    & $deploy -ConfigPath $configPath -Action Deploy
    $call = @($global:snapcalTestCalls | Where-Object { $_[0] -eq 'run' -and $_[1] -eq 'deploy' })[0]
    foreach ($flag in @('--min=1','--max=3','--cpu=1','--memory=1Gi','--concurrency=20','--timeout=120s','--cpu-throttling','--allow-unauthenticated')) {
        Assert-True ($flag -in $call) "Missing deployment flag $flag"
    }
    Assert-True (!(@($call | Where-Object { $_ -like '--max-instances*' }).Count)) 'Must use service-level maximum.'
    $envIndex = [array]::IndexOf($call, '--env-vars-file')
    Assert-True (!(Test-Path -LiteralPath $call[$envIndex+1])) 'Temporary settings file must be removed.'
    $global:snapcalTestMaxInstances=30
    $caught=$false
    try { & $deploy -ConfigPath $configPath -Action Verify } catch { $caught=$_.Exception.Message -like '*approved cost settings*' }
    Assert-True $caught 'Verification must reject an excessive maximum.'
    $config.region='europe-west1'
    [System.IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 10))
    $caught=$false
    try { & $deploy -ConfigPath $configPath } catch { $caught=$_.Exception.Message -like '*Use region us-central1*' }
    Assert-True $caught 'Preflight must reject the wrong Firestore region.'

    $budget = Join-Path $backend 'deploy/set-budget.ps1'
    & $budget -BillingAccount TEST -OwnerEmailChannel $global:snapcalTestChannel
    Assert-True (!$global:snapcalTestBudgetExists) 'Budget preflight must not create a budget.'
    & $budget -BillingAccount TEST -OwnerEmailChannel $global:snapcalTestChannel -Apply
    & $budget -BillingAccount TEST -OwnerEmailChannel $global:snapcalTestChannel -Apply
    $creates = @($global:snapcalTestCalls | Where-Object { $_[0] -eq 'billing' -and $_[1] -eq 'budgets' -and $_[2] -eq 'create' })
    $updates = @($global:snapcalTestCalls | Where-Object { $_[0] -eq 'billing' -and $_[1] -eq 'budgets' -and $_[2] -eq 'update' })
    Assert-True ($creates.Count -eq 1 -and $updates.Count -eq 1) 'Repeated budget setup must update, not duplicate.'
    Assert-True ('--clear-threshold-rules' -in $updates[0]) 'Budget update must replace threshold rules.'
    Assert-True ('--add-threshold-rule=percent=0.8,basis=current-spend' -in $updates[0]) 'Budget update must use supported update flags.'
    Write-Host 'PASS: deployment preflight, settings, mismatch rejection, cleanup, budget create/update and safe defaults.'
} finally { if (Test-Path -LiteralPath $configPath) { Remove-Item -LiteralPath $configPath } }
