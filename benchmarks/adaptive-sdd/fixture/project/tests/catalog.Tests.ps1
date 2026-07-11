$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/search.ps1')

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Expected -cne $Actual) {
        throw "$Message Expected '$Expected', found '$Actual'."
    }
}

$items = @(Get-CatalogItems)
Assert-Equal -Expected 4 -Actual $items.Count -Message 'Catalog item count differs.'
Assert-Equal -Expected 4 -Actual @($items.Id | Sort-Object -Unique).Count -Message 'Catalog IDs are not unique.'

$tea = @(Search-Catalog -Query 'TEA')
Assert-Equal -Expected 1 -Actual $tea.Count -Message 'Name search result count differs.'
Assert-Equal -Expected 'beverage-tea' -Actual $tea[0].Id -Message 'Name search returned the wrong item.'

$tools = @(Search-Catalog -Query 'hand-tool' -Category 'tools')
Assert-Equal -Expected 2 -Actual $tools.Count -Message 'Tag and category search result count differs.'
Assert-Equal -Expected 'tool-hammer,tool-tape' -Actual ($tools.Id -join ',') -Message 'Search result order differs.'

$excluded = @(Search-Catalog -Query 'drink' -Category 'tools')
Assert-Equal -Expected 0 -Actual $excluded.Count -Message 'Category filtering included unrelated items.'

Write-Output 'PASS: catalog fixture behavior is valid.'
