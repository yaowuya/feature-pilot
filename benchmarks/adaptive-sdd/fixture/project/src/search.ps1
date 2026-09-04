Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'catalog.ps1')

function Search-Catalog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Query,

        [string]$Category
    )

    Get-CatalogItems |
        Where-Object {
            $categoryMatches = -not $Category -or $_.Category -ieq $Category
            $queryMatches = -not $Query -or
                $_.Name.IndexOf($Query, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                ($_.Tags -join ' ').IndexOf($Query, [StringComparison]::OrdinalIgnoreCase) -ge 0
            $categoryMatches -and $queryMatches
        } |
        Sort-Object -Property Id
}
