function New-EDI850Detail {
    [CmdletBinding(DefaultParameterSetName='UPC')]
    param(
        [Parameter(Mandatory=$true)]
        [decimal]$Quantity,
        [ValidateScript({$_ -in $UOMCode})]
        $UOM = 'EA',
        [Parameter(Mandatory=$true,ParameterSetName='UPC')]
        [Parameter(ParameterSetName='VCode')]
        [ValidateLength(1,48)]
        [string]$UPC,
        [Parameter(Mandatory=$true,ParameterSetName='VCode')]
        [Parameter(ParameterSetName='UPC')]
        [ValidateLength(1,48)]
        [string]$VendorCode,
        [nullable[decimal]]$Cost,
        [ValidateLength(1,80)]
        [string]$Description,
        [ValidateLength(1,45)]
        [string]$Note
    )

    $Detail = [EDI850Detail]::new()

    switch(($Detail | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name)){
        'UPC' {if($UPC){$Detail.$_ = Get-Variable -Name $_ -ValueOnly}}
        'VendorCode' {if($VendorCode){$Detail.$_ = Get-Variable -Name $_ -ValueOnly}}
        'Description' {if($Description){$Detail.$_ = Get-Variable -Name $_ -ValueOnly}}
        'Note' {if($Note){$Detail.$_ = Get-Variable -Name $_ -ValueOnly}}
        default {$Detail.$_ = Get-Variable -Name $_ -ValueOnly}
    }

    return $Detail

}
