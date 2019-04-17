Function Get-UpdateCatalogLink {
    <#
        .SYNOPSIS
            Returns contents of a KB search from the Microsoft Update Catalog

        .NOTES
            Author: Aaron Parker
            Twitter: @stealthpuppy

        .PARAMETER KB
            Knowledgebase article string to search the catalog for.
    #>
    [CmdletBinding(DefaultParameterSetName="KB")]
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True, ParameterSetName = "KB")]
        [ValidateNotNullOrEmpty()]
        [String] $KB,

        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True, ParameterSetName = "SearchString")]
        [ValidateNotNullOrEmpty()]
        [String] $SearchString = "KB$KB"
    )

    try {
        $uri = "http://www.catalog.update.microsoft.com/Search.aspx?q=$SearchString"
        Write-Verbose -Message "Searching $uri."
        $kbPage = Invoke-WebRequest -Uri $uri -UseBasicParsing -ErrorAction SilentlyContinue
    }
    catch {
        # Write warnings if we can't read values
        If ($Null -eq $kbPage) { Write-Warning -Message "Page object is Null. Unable to read KB details from the Catalog." }
        If ($Null -eq $kbPage.InputFields) { Write-Warning -Message " Page input fields are Null. Unable to read button details from the Catalog KB page." }
        Throw $_
    }
    finally {
        Write-Output $kbPage
    }
}
