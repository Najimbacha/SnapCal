[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [ValidateSet('Preflight', 'Deploy', 'Verify')][string]$Action = 'Preflight'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-GcloudJson([string[]]$Arguments) {
    $result = & gcloud @Arguments --format=json --quiet
    if ($LASTEXITCODE -ne 0) { throw "gcloud failed: $($Arguments[0]) $($Arguments[1])" }
    return ($result -join "`n" | ConvertFrom-Json)
}
function Invoke-Gcloud([string[]]$Arguments) {
    & gcloud @Arguments --quiet
    if ($LASTEXITCODE -ne 0) { throw "gcloud failed: $($Arguments[0]) $($Arguments[1])" }
}

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
if ($config.project -ne 'snapcal-ef333' -or $config.service -ne 'snapcal-api') {
    throw 'This migration targets snapcal-ef333 / snapcal-api only.'
}
if (!$config.region -or !$config.firestoreLocation) { throw 'Set region and firestoreLocation after checking the live Firestore database.' }
if ($config.memory -notin @('512Mi', '1Gi')) { throw 'Only 512Mi or 1Gi is allowed.' }
if ($config.serviceAccount -ne 'snapcal-run@snapcal-ef333.iam.gserviceaccount.com') { throw 'Use the dedicated snapcal-run runtime identity.' }
$required = @{ NODE_ENV='production'; REQUIRE_APP_CHECK='true'; REQUIRE_SHARED_REDIS='true'; API_RATE_LIMIT='120'; SCAN_RATE_LIMIT='20'; WEBHOOK_RATE_LIMIT='120'; MAX_CONCURRENT_SCANS='10'; FREE_MONTHLY_SCANS='15'; SHUTDOWN_DRAIN_MS='0'; SHUTDOWN_TIMEOUT_MS='9000' }
foreach ($entry in $required.GetEnumerator()) {
    if ($config.env.($entry.Key) -cne $entry.Value) { throw "Required setting: $($entry.Key)=$($entry.Value)" }
}
foreach ($entry in $config.env.PSObject.Properties) {
    if ($entry.Name -match '(_KEYS?|_SECRET|_TOKEN|_PASSWORD|_CREDENTIALS?|_SERVICE_ACCOUNT|REDIS_URL)$') { throw "Move $($entry.Name) to Secret Manager." }
}
foreach ($name in @('DEEPSEEK_API_KEY','REVENUECAT_WEBHOOK_AUTH','REVENUECAT_SECRET_API_KEY','REDIS_URL','SCHEDULER_SECRET','METRICS_TOKEN')) {
    if (!$config.secrets.PSObject.Properties[$name]) { throw "Missing Secret Manager reference: $name" }
}
foreach ($entry in $config.secrets.PSObject.Properties) {
    if ($entry.Value -notmatch '^[A-Za-z0-9_-]+:[1-9][0-9]*$') { throw "Use a pinned secret version for $($entry.Name), e.g. secret-name:1." }
    if ($entry.Name -in @('FIREBASE_SERVICE_ACCOUNT','GOOGLE_APPLICATION_CREDENTIALS')) { throw 'Use the attached service account, not a Firebase private key.' }
}
if (!(Get-Command gcloud -ErrorAction SilentlyContinue)) { throw 'Install Google Cloud CLI, then run gcloud auth login. See CLOUD_RUN.md.' }
$projectArgs = @('--project', $config.project)
$billing = Invoke-GcloudJson (@('billing','projects','describe',$config.project))
if (!$billing.billingEnabled) { throw 'The owner must enable billing first.' }
$apis = Invoke-GcloudJson (@('services','list','--enabled') + $projectArgs)
foreach ($api in @('run.googleapis.com','cloudbuild.googleapis.com','artifactregistry.googleapis.com','secretmanager.googleapis.com','firestore.googleapis.com')) {
    if ($api -notin @($apis | ForEach-Object { $_.config.name })) { throw "Enable $api first; see CLOUD_RUN.md." }
}
$database = Invoke-GcloudJson (@('firestore','databases','describe','--database=(default)') + $projectArgs)
if ($database.locationId -ne $config.firestoreLocation) { throw 'Configured Firestore location differs from the live database.' }
$expectedRegion = switch ($database.locationId) { 'nam5' { 'us-central1' }; 'eur3' { 'europe-west1' }; default { $database.locationId } }
if ($config.region -ne $expectedRegion) { throw "Use region $expectedRegion beside the existing Firestore database." }
$null = Invoke-GcloudJson (@('iam','service-accounts','describe',$config.serviceAccount) + $projectArgs)
foreach ($entry in $config.secrets.PSObject.Properties) {
    $parts = $entry.Value.Split(':')
    $version = Invoke-GcloudJson (@('secrets','versions','describe',$parts[1],'--secret',$parts[0]) + $projectArgs)
    if ($version.state -ne 'ENABLED') { throw "Secret version for $($entry.Name) is not enabled." }
}
Write-Host 'Preflight passed: billing, APIs, region, runtime identity, configuration and secret versions.'
Write-Host 'Runtime IAM, Redis connectivity and real mobile tests remain mandatory deployment gates.'
if ($Action -eq 'Preflight') { return }

if ($Action -eq 'Deploy') {
    $backendDir = Split-Path $PSScriptRoot -Parent
    $envFile = Join-Path ([System.IO.Path]::GetTempPath()) ("snapcal-env-" + [guid]::NewGuid() + '.yaml')
    try {
        # JSON is valid YAML. Values here are public settings, never secrets.
        [System.IO.File]::WriteAllText($envFile, ($config.env | ConvertTo-Json), [System.Text.UTF8Encoding]::new($false))
        $secretRefs = ($config.secrets.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ','
        Invoke-Gcloud (@('run','deploy',$config.service,'--source',$backendDir,'--region',$config.region,
            '--service-account',$config.serviceAccount,'--execution-environment=gen2','--port=8080',
            '--min=1','--max=3','--cpu=1',"--memory=$($config.memory)",'--concurrency=20','--timeout=120s',
            '--cpu-throttling','--allow-unauthenticated','--ingress=all',
            '--startup-probe=httpGet.path=/startup,httpGet.port=8080,initialDelaySeconds=0,timeoutSeconds=2,periodSeconds=5,failureThreshold=12',
            '--env-vars-file',$envFile,'--set-secrets',$secretRefs) + $projectArgs)
    } finally { if (Test-Path -LiteralPath $envFile) { Remove-Item -LiteralPath $envFile } }
}

# Inspect the v2 API: service scaling and revision scaling are different fields.
$accessToken = (& gcloud auth print-access-token --quiet) -join ''
if ($LASTEXITCODE -ne 0) { throw 'Could not obtain an access token.' }
try {
    $service = Invoke-RestMethod -Uri "https://run.googleapis.com/v2/projects/$($config.project)/locations/$($config.region)/services/$($config.service)" -Headers @{ Authorization="Bearer $accessToken" }
} finally { $accessToken = $null }
$container = $service.template.containers[0]
if ($service.scaling.minInstanceCount -ne 1 -or $service.scaling.maxInstanceCount -ne 3 -or
    $service.template.maxInstanceRequestConcurrency -ne 20 -or $service.template.timeout -ne '120s' -or
    $service.template.serviceAccount -ne $config.serviceAccount -or
    $container.resources.limits.cpu -ne '1' -or $container.resources.limits.memory -ne $config.memory -or
    !$container.resources.cpuIdle) { throw 'Deployed service does not match the approved cost settings. Inspect before cutover.' }
foreach ($entry in $config.env.PSObject.Properties) {
    $actual = @($container.env | Where-Object { $_.name -eq $entry.Name })
    if ($actual.Count -ne 1 -or $actual[0].value -cne $entry.Value) { throw "Deployed environment mismatch: $($entry.Name). Do not switch users." }
}
foreach ($entry in $config.secrets.PSObject.Properties) {
    $parts = $entry.Value.Split(':')
    $actual = @($container.env | Where-Object { $_.name -eq $entry.Name })
    if ($actual.Count -ne 1 -or $actual[0].valueSource.secretKeyRef.secret.Split('/')[-1] -ne $parts[0] -or
        $actual[0].valueSource.secretKeyRef.version -ne $parts[1]) { throw "Deployed secret reference mismatch: $($entry.Name)." }
}
$probe = Invoke-RestMethod -Uri "$($service.uri)/startup" -TimeoutSec 15
if ($probe.status -ne 'started') { throw 'Process probe failed.' }
$health = Invoke-RestMethod -Uri "$($service.uri)/health" -TimeoutSec 15
if ($health.status -ne 'ok' -or !$health.scan.costControls.sharedCacheReady -or
    !$health.billing.webhookConfigured -or !$health.billing.restVerificationConfigured) { throw 'Health, Redis or RevenueCat configuration failed. Do not switch users.' }
Write-Host "Verified service settings and health: $($service.uri)"
Write-Host 'No Remote Config, RevenueCat webhook, Render, or Flutter fallback changes were made.'
