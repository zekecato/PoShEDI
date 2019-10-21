function Set-EDIFunctionalGroupEnvelope {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Document,
        [ValidateLength(2,15)]
        [string]$SenderCode = $ModuleConfig.EDIOUT.SenderCode,
        [Parameter(Mandatory = $true)]
        [ValidateLength(2,15)]
        [string]$ReceiverCode,
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,9)]
        [string]$GSControlNumber,
        [string]$ES = $ModuleConfig.EDIOUT.ElementSeparator
    )
    
    #This counts on the PO document being preserved as an array of strings
    #Read the first line of the document to determine the document type and set the functional group ID code
    $FID = $Document[0].split('*')[1]
    #Build the header line
    $Strings = @()
    $Strings += @('GS',$FID,$SenderCode,$ReceiverCode,(Get-Date -Format yyyyMMdd),(Get-Date -Format HHmmss),$GSControlNumber,'X','005010') -join $ES

    $Document = $Strings + $Document

    #Build the footer
    $Document += @('GE',($Document | Where-Object {$_.StartsWith('ST')}).Count,$GSControlNumber) -join $ES

    return $Document
}
