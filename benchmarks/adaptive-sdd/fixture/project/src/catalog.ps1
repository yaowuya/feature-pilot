Set-StrictMode -Version Latest

function Get-CatalogItems {
    [CmdletBinding()]
    param()

    @(
        [pscustomobject]@{ Id = 'beverage-coffee'; Name = 'Ground Coffee'; Category = 'pantry'; Tags = @('drink', 'roasted') }
        [pscustomobject]@{ Id = 'beverage-tea'; Name = 'Green Tea'; Category = 'pantry'; Tags = @('drink', 'leaf') }
        [pscustomobject]@{ Id = 'tool-hammer'; Name = 'Claw Hammer'; Category = 'tools'; Tags = @('steel', 'hand-tool') }
        [pscustomobject]@{ Id = 'tool-tape'; Name = 'Tape Measure'; Category = 'tools'; Tags = @('measurement', 'hand-tool') }
    )
}
