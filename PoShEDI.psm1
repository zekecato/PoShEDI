    $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
    $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
    Foreach($import in @($Public + $Private))
    {
        Try
        {
            . $import.fullname
        }
        Catch
        {
            Write-Error -Message "Failed to import function $($import.fullname): $_"
        }
    }

Export-ModuleMember -Function $Public.Basename

$Script:ModuleConfig = @{
    EDIOUT = @{
        ElementSeparator = '*'
        CompositeElementSeparator = '>'
        #Default to DUNS Number
        SenderCode = ''
        SenderCodeQualifier = '01'
    }
    SQL = @{
        ServerInstance = ''
    }
}

#Load classes for EDI Document Creation
class EDI850Header {
    [ValidateLength(4,9)]
    [string]$ControlNum
    [ValidateLength(1,22)]
    [string]$PONum
    [datetime]$Date
    [ValidateLength(0,50)]
    [string]$VendorID
    [ValidateLength(0,4096)]
    [string]$Memo

    [ValidateLength(1,60)]
    [string]$BTName
    [ValidateLength(2,80)]
    [string]$BTAccountNumber
    [ValidateLength(1,55)]
    [string]$BTAddress
    [ValidateLength(2,30)]
    [string]$BTCity
    [ValidateLength(2,2)]
    [string]$BTState
    [ValidateLength(3,15)]
    [string]$BTZip

    [ValidateLength(1,60)]
    [string]$STName
    [string]$STLocationID
    [ValidateLength(1,55)]
    [string]$STAddress
    [ValidateLength(2,30)]
    [string]$STCity
    [ValidateLength(2,2)]
    [string]$STState
    [ValidateLength(3,15)]
    [string]$STZip
        
    [ValidateLength(1,60)]
    [string]$BuyerName
    [ValidateLength(1,256)]
    [string]$BuyerEmail
    [ValidateLength(1,256)]
    [string]$BuyerPhone

    EDI850Header (){
        $this.Date = Get-Date
    }
}

class EDI850Detail {
    [decimal]$Quantity
    [ValidateLength(2,2)]
    $UOM
    [ValidateLength(1,48)]
    [string]$UPC
    [ValidateLength(1,48)]
    [string]$VendorCode
    [nullable[decimal]]$Cost
    [ValidateLength(1,80)]
    [string]$Description
    [ValidateLength(1,45)]
    [string]$Note
}

class SPSInvoiceHeader {
    [datetime]$InvoiceDate
    [string]$InvoiceNumber
    [datetime]$PODate
    [string]$PONumber
<#
    [string]$BillingName
    [string]$BillingEMail
    [string]$BillingPhone
    [string]$BillingFax
#>    
    [string]$BillToName
    [string]$BillToStreet
    [string]$BillToCity
    [string]$BillToState
    [string]$BillToZip
    [string]$BillToID
<#    
    [string]$RemitToName
    [string]$RemitToStreet
    [string]$RemitToCity
    [string]$RemitToState
    [string]$RemitToZip
    [string]$RemitToID
#>
    [string]$ShipToName
    [string]$ShipToStreet
    [string]$ShipToCity
    [string]$ShipToState
    [string]$ShipToZip
    [string]$ShipToID
    
#    [string]$VendorName
    [string]$SenderCode
    [string]$ExternalVendorID
    [string]$InternalVendorID
    [nullable[datetime]]$DiscountDueDate
    [nullable[datetime]]$InvoiceDueDate
    [string]$TermsDescription

    [nullable[datetime]]$ShipDate
    [decimal]$TaxTotal
    
    [decimal]$TotalCost
    [nullable[decimal]]$TotalCostTermsDiscount

    [bool]$IsComplete
}

class SPSInvoiceDetail {
    [string]$InvoiceNumber
    [string]$SenderCode
    [nullable[int]]$LineNumber

    [decimal]$Quantity
    [string]$UOM

    [decimal]$UnitPrice
    [string]$UnitPriceUnit
    [nullable[decimal]]$TaxAmount

    [string]$UPC
    [string]$VendorCode

    [string]$ItemDescription

    [bool]$IsSAC = $false
    [string]$SACCode

}

#endregion