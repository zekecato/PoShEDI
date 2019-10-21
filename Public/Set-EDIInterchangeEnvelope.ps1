function Set-EDIInterchangeEnvelope {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Document,
        [ValidateLength(1,15)]
        [string]$SenderCode = $ModuleConfig.EDIOUT.SenderCode,
        [ValidateLength(2,2)]
        [string]$SenderCodeQualifier = $ModuleConfig.EDIOUT.SenderCodeQualifier,
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,15)]
        [string]$ReceiverCode,
        [Parameter(Mandatory = $true)]
        [ValidateLength(2,2)]
        [string]$ReceiverCodeQualifier,
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,9)]
        [string]$ISAControlNumber,
        [switch]$Production,
        [string]$ES = $ModuleConfig.EDIOUT.ElementSeparator
    )

    #This counts on the PO document being preserved as an array of strings
    
    #Strings in this header need to be padded to a fixed length
    $SenderCode = $SenderCode.PadRight(15,' ')
    $ReceiverCode = $ReceiverCode.PadRight(15,' ')
    $ISAControlNumber = $ISAControlNumber.PadLeft(9,'0')
    
    if($Production.IsPresent){
        $SendType = 'P'
    }else{
        $SendType = 'T'
    }
    $Strings = @()
    $Strings += @('ISA','00',(' '*10),'00',(' '*10),$SenderCodeQualifier,$SenderCode,$ReceiverCodeQualifier,$ReceiverCode,(Get-Date -Format yyMMdd),(Get-Date -Format HHmm),'_','00501',$ISAControlNumber,0,$SendType,$ModuleConfig.EDIOUT.CompositeElementSeparator) -join $ES

    $Document = $Strings + $Document

    $Document += @('IEA',($Document | Where-Object {$_.StartsWith('GS')}).Count,$ISAControlNumber) -join $ES

    return $Document
}
