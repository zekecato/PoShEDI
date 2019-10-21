function New-EDI850Header {
    [CmdletBinding(DefaultParameterSetName = 'SpecAll')]
    param(
        #[Parameter(Mandatory=$True)]
        #[ValidateLength(1,9)]
        #[string]$ControlNum,
        [Parameter(Mandatory=$True)]
        [ValidateLength(1,22)]
        [string]$PONum,
        [datetime]$Date,
        [ValidateLength(0,50)]
        [string]$VendorID,
        [ValidateLength(0,4096)]
        [string]$Memo,

        [Parameter(Mandatory=$True)]
        [ValidateLength(1,60)]
        [string]$BTName,
        [ValidateLength(2,80)]
        [string]$BTAccountNumber,
        [Parameter(Mandatory=$True)]
        [ValidateLength(1,55)]
        [string]$BTAddress,
        [Parameter(Mandatory=$True)]
        [ValidateLength(2,30)]
        [string]$BTCity,
        [Parameter(Mandatory=$True)]
        [ValidateLength(2,2)]
        [string]$BTState,
        [Parameter(Mandatory=$True)]
        [ValidateLength(3,15)]
        [string]$BTZip,

        [Parameter(Mandatory=$True, ParameterSetName = 'SpecAll')]
        [ValidateLength(1,60)]
        [string]$STName,
        [Parameter(Mandatory=$True, ParameterSetName = 'SpecAll')]
        [ValidateLength(1,55)]
        [string]$STAddress,
        [Parameter(Mandatory=$True, ParameterSetName = 'SpecAll')]
        [ValidateLength(2,30)]
        [string]$STCity,
        [Parameter(Mandatory=$True, ParameterSetName = 'SpecAll')]
        [ValidateLength(2,2)]
        [string]$STState,
        [Parameter(Mandatory=$True, ParameterSetName = 'SpecAll')]
        [ValidateLength(3,15)]
        [string]$STZip,
        [string]$STLocationID,

        [ValidateLength(1,60)]
        [string]$BuyerName,
        [ValidateLength(1,256)]
        [string]$BuyerEmail,
        [ValidateLength(1,256)]
        [string]$BuyerPhone,

        [Parameter(ParameterSetName = 'ShipToIsBillTo')]
        [switch]$ShipToIsBillTo
    )

    $SqlArgs = @{
        ServerInstance = $ModuleConfig.SQL.ServerInstance
    }

    $ControlNum = (Invoke-Sqlcmd @SqlArgs -Query "SELECT NEXT VALUE FOR $($ModuleConfig.SQL.EDIDBSchema +'.'+ $ModuleConfig.SQL.TxnControlNum) as ctrl" | Select-Object -ExpandProperty ctrl).ToString().PadLeft(4,'0')

    if($ShipToIsBillTo.IsPresent){
        $STName = $BTName
        $STAddress = $BTAddress
        $STCity = $BTCity
        $STState = $BTState
        $STZip = $BTZip
    }

    $Header = [EDI850Header]::new()

    switch(($Header | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name)){
        'BuyerName' {if($BuyerName){$Header.$_ = Get-Variable -Name $_ -ValueOnly}}
        'BuyerEmail' {if($BuyerEmail){$Header.$_ = Get-Variable -Name $_ -ValueOnly}}
        'BuyerPhone' {if($BuyerPhone){$Header.$_ = Get-Variable -Name $_ -ValueOnly}}
        'BTAccountNumber'{if($BTAccountNumber){$Header.$_ = Get-Variable -Name $_ -ValueOnly}}
        'Date' {if($Date){$Header.$_ = Get-Variable -Name $_ -ValueOnly}}
        default {$Header.$_ = Get-Variable -Name $_ -ValueOnly}
    }

    return $Header
}
