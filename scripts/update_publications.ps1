# =====================================================================
# Script: update_publications.ps1
# Description: Fetches all works from Dr. Mohamed Elsenety's ORCID
#              (0000-0001-5107-5959) and updates assets/data/publications.json
# =====================================================================

Write-Host "Connecting to ORCID Public API for Dr. Mohamed Elsenety (0000-0001-5107-5959)..." -ForegroundColor Cyan

$orcidId = "0000-0001-5107-5959"
$url = "https://pub.orcid.org/v3.0/$orcidId/works"

try {
    $res = Invoke-RestMethod -Uri $url -Headers @{ 'Accept'='application/json' }
} catch {
    Write-Error "Failed to connect to ORCID API: $_"
    exit 1
}

$list = @()
foreach ($g in $res.group) {
    $w = $g.'work-summary'[0]
    if (-not $w) { continue }

    $title = if ($w.title.title.value) { $w.title.title.value.Trim() } else { "Untitled" }
    $year = if ($w.'publication-date'.year.value) { [int]$w.'publication-date'.year.value } else { 0 }
    $month = if ($w.'publication-date'.month.value) { [int]$w.'publication-date'.month.value } else { 0 }
    $day = if ($w.'publication-date'.day.value) { [int]$w.'publication-date'.day.value } else { 0 }
    $journal = if ($w.'journal-title'.value) { $w.'journal-title'.value.Trim() } else { "" }
    $type = if ($w.type) { $w.type } else { "journal-article" }
    
    $doi = ""
    $workUrl = if ($w.url.value) { $w.url.value.Trim() } else { "" }
    if ($w.'external-ids'.'external-id') {
        $d = $w.'external-ids'.'external-id' | Where-Object { $_.'external-id-type' -eq 'doi' } | Select-Object -First 1
        if ($d) { 
            $doi = $d.'external-id-value'.Trim()
            if (-not $workUrl) { $workUrl = "https://doi.org/$doi" }
        }
    }

    # Infer smart research topics
    $topics = @()
    $tLower = ($title + " " + $journal).ToLower()
    if ($tLower -match "perovskite|solar|photovoltaic|dssc|dye-sensitized|dye sensitized") { $topics += "Solar Energy & Perovskites" }
    if ($tLower -match "dft|density functional|molecular dynamics|computational|castep|gaussian|quantum|docking|vibrational") { $topics += "DFT & Computational" }
    if ($tLower -match "machine learning|deep learning|ann|artificial neural|mlp|predict|fingerprint|knn") { $topics += "Machine Learning & AI" }
    if ($tLower -match "photocataly|cataly|hydrogen evolution|sensor|ph|water treatment|adsorption|degradation|pollutant") { $topics += "Photocatalysis & Sensors" }
    if ($tLower -match "polymer|waste|recycl|composite|biogenic|keratin|chitosan|nanocomposite") { $topics += "Polymers & Circular Economy" }
    if ($topics.Count -eq 0) { $topics += "Materials Chemistry" }

    $list += [PSCustomObject]@{
        id = $w.'put-code'
        title = $title
        journal = $journal
        year = $year
        month = $month
        day = $day
        type = $type
        doi = $doi
        url = $workUrl
        topics = $topics
    }
}

# Sort newest first
$list = $list | Sort-Object -Property @{Expression="year"; Descending=$true}, @{Expression="month"; Descending=$true}, @{Expression="day"; Descending=$true}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$targetDir = Join-Path $projectRoot "assets\data"
if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
$targetFile = Join-Path $targetDir "publications.json"

$data = [PSCustomObject]@{
    author = "Dr. Mohamed Elsenety"
    orcid = $orcidId
    scholar = "https://scholar.google.com/citations?user=fvLZ67wAAAAJ"
    scopus = "57188750324"
    last_updated = (Get-Date).ToString("yyyy-MM-dd")
    total_count = $list.Count
    publications = $list
}

$data | ConvertTo-Json -Depth 10 | Set-Content -Path $targetFile -Encoding UTF8
Write-Host "Success! Synced $($list.Count) publications up to today ($(Get-Date -Format 'yyyy-MM-dd'))." -ForegroundColor Green
Write-Host "Saved to: $targetFile" -ForegroundColor Yellow
