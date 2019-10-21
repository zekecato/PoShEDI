function Parse-SPS810Invoice {
    param(
        [Parameter(Mandatory = $true,ParameterSetName='File')]
        [ValidateScript({Test-Path $_})]
        [string] $Path,

        [Parameter(Mandatory = $true,ParameterSetName='Content')]
        [string[]] $Content,

        [string]$SenderCode,
        [switch]$RemoveEnvelopes,

        [string] $ES = '*'

    )

#Load the file into memory for parsing
if($PSCmdlet.ParameterSetName -eq 'File'){
    $RawDocument = Get-Content $Path 
}else{
    if($Content.Count -eq 1){ #Then the document came through as a single string
        $RawDocument = $Content[0] -split "`r`n"
    }else{
        $RawDocument = $Content
    }
}
if($RemoveEnvelopes.IsPresent){
    $RawDocument = $RawDocument[2..($RawDocument.Count - 3)]
}
$InvoicesToUpload = New-Object System.Collections.ArrayList
$DetailsToUpload = New-Object System.Collections.ArrayList
$WorkingInvoice = $null
$WorkingDetail = $null

#This switch statement runs through each line in the invoice document and assembles header and detail objects.
Switch ($RawDocument) {
        
    {$_.startswith('BIG')}{
    Write-Verbose 'Initializing new Invoice'
    #Summary variable allows us to switch from item tax and service charge to invoice summary tax and servicve charge
    $Summary=$false
        if ($WorkingInvoice){
            Write-Verbose 'Adding previous invoice to list'
            [void]$InvoicesToUpload.Add($WorkingInvoice)
        }
        $WorkingInvoice = [SPSInvoiceHeader]::new()
        $WorkingInvoice.SenderCode = $SenderCode
        $ItemCounter = 0
        $LineArray = $_.split($ES)
        $WorkingInvoice.InvoiceDate = [datetime]::ParseExact($LineArray[1], 'yyyyMMdd', $null)
        $WorkingInvoice.InvoiceNumber = $LineArray[2]
        $WorkingInvoice.PODate = [datetime]::ParseExact($LineArray[3], 'yyyyMMdd', $null)
        $WorkingInvoice.PONumber = $LineArray[4]
        continue
    }

    {$_.startswith('REF')} {
        $LineArray = $_.split($ES)
        if($LineArray[1] -eq 'IA'){$WorkingInvoice.InternalVendorID = 71}
        continue
    }

    {$_.startswith('PER')} {
        $LineArray = $_.split($ES)
        if($LineArray[1] -eq 'BI'){
            $WorkingInvoice.BillingName = $LineArray[2]
            for($i=3;$i -lt ($LineArray.length);$i+=2){
                switch($LineArray[$i]){
                    'EM' {$WorkingInvoice.BillingEMail = $LineArray[($i+1)]}
                    'TE' {$WorkingInvoice.BillingPhone = $LineArray[($i+1)]}
                    'FX' {$WorkingInvoice.BillingFax = $LineArray[($i+1)]}
                }
            }
        }
        continue
    }

    {$_.startswith('N1')} {
        $LineArray = $_.split($ES)
        $N101 = $LineArray[1]
        switch($N101){
            'BT' {
                $WorkingInvoice.BillToName = $LineArray[2]
                $WorkingInvoice.BillToID = $LineArray[4]
            }
            'RI' {
                $WorkingInvoice.RemitToName = $LineArray[2]
                $WorkingInvoice.RemitToID = $LineArray[4]
            }
            'SF' {
                #I don't think we need the ship from information
            }
            'ST' {
                $WorkingInvoice.ShipToName = $LineArray[2]
                $WorkingInvoice.ShipToID = $LineArray[4]
            }
            'VN' {
                $WorkingInvoice.VendorName = $LineArray[2]
                if($LineArray[3] -eq '91'){
                    $WorkingInvoice.ExternalVendorID = $LineArray[4]
                }else{
                    $WorkingInvoice.InternalVendorID = $LineArray[4]
                }
            }
        }
        continue
    }

    {$_.startswith('N3')} {
        $LineArray = $_.split($ES)
        switch($N101){
            'BT' {
                $WorkingInvoice.BillToStreet = $LineArray[1]
            }
            'RI' {
                $WorkingInvoice.RemitToStreet = $LineArray[1]
            }
            'SF' {
                #I don't think we need the ship from information
            }
            'ST' {
                $WorkingInvoice.ShipToStreet = $LineArray[1]
            }
            'VN' {
                #Vendor address info should already be in our system
            }
        }
        continue
    }

    {$_.startswith('N4')} {
        $LineArray = $_.split($ES)
        switch($N101){
            'BT' {
                $WorkingInvoice.BillToCity = $LineArray[1]
                $WorkingInvoice.BillToState = $LineArray[2]
                $WorkingInvoice.BillToZip = $LineArray[3]
            }
            'RI' {
                $WorkingInvoice.RemitToCity = $LineArray[1]
                $WorkingInvoice.RemitToState = $LineArray[2]
                $WorkingInvoice.RemitToZip = $LineArray[3]
            }
            'SF' {
                #I don't think we need the ship from information
            }
            'ST' {
                $WorkingInvoice.ShipToCity = $LineArray[1]
                $WorkingInvoice.ShipToState = $LineArray[2]
                $WorkingInvoice.ShipToZip = $LineArray[3]
            }
            'VN' {
                #Vendor address info should already be in our system
            }
        }
        continue
    }

    {$_.startswith('ITD')} {
        $LineArray = $_.split($ES)
        if($LineArray[4] -ne ''){$WorkingInvoice.DiscountDueDate = $LineArray[4]}
        if($LineArray[6] -ne ''){$WorkingInvoice.InvoiceDueDate = $LineArray[6]}
        $WorkingInvoice.TermsDescription = $LineArray[12]
        continue
    }

    {$_.startswith('DTM')} {
        $LineArray = $_.split($ES)
        if($LineArray[1] -eq '011'){
            if($LineArray[2] -ne ''){$WorkingInvoice.ShipDate = $LineArray[2]}
        }
        continue
    }

    {$_.startswith('IT1')} {
        Write-Verbose 'Initializing new invoice detail'
        if ($WorkingDetail){
            Write-Verbose 'Adding previous detail to list'
            [void]$DetailsToUpload.Add($WorkingDetail)
        }
        $WorkingDetail = [SPSInvoiceDetail]::new()
        $WorkingDetail.SenderCode = $SenderCode
        $ItemCounter++
        $LineArray = $_.split($ES)
        $WorkingDetail.LineNumber = $LineArray[1]
        $WorkingDetail.Quantity = $LineArray[2]
        $WorkingDetail.UOM = $LineArray[3]
        $WorkingDetail.UnitPrice = $LineArray[4]
        if($LineArray[5] -eq 'PE'){
            $WorkingDetail.UnitPriceUnit = 'EA'
        }else{
            $WorkingDetail.UnitPriceUnit = $LineArray[3]
        }
        $WorkingDetail.InvoiceNumber = $WorkingInvoice.InvoiceNumber

        for($i=6;$i -lt $LineArray.length;$i+=2){
            switch($LineArray[$i]){
                'VN' {$WorkingDetail.VendorCode = $LineArray[($i+1)]}
                {$_ -in @('UP','UK','EN')} {$WorkingDetail.UPC}
            }
        }
        continue
    }

    {$_.startswith('TXI')} {
        if ($Summary -eq $false){
            $LineArray = $_.split($ES)
            $WorkingDetail.TaxAmount += $LineArray[2]
        }else{
            $WorkingInvoice.TaxTotal += $LineArray[2]
        }
    }

    {$_.startswith('PID')} {
        $LineArray = $_.split($ES)
        $WorkingDetail.ItemDescription = $LineArray[5]
        continue
    }

    {$_.startswith('TDS')} {
        Write-Verbose 'Writing Invoice Totals'
        $Summary = $true
        $LineArray = $_.split($ES)
        $WorkingInvoice.TotalCost = $LineArray[1]/100
        #$WorkingInvoice.TermsDiscountedValue = $LineArray[2]/100
        if ($LineArray[3]){
            $WorkingInvoice.TotalCostTermsDiscount = $LineArray[3]/100
        }else{
            $WorkingInvoice.TotalCostTermsDiscount = $WorkingInvoice.TotalCost
        }
        continue
    }

    {$_.startswith('SAC')} {
        Write-Verbose 'Writing invoice Charge/Allowance Detail'
        if ($WorkingDetail){
            Write-Verbose 'Adding previous detail to list'
            [void]$DetailsToUpload.Add($WorkingDetail)
        }
        $WorkingDetail = [SPSInvoiceDetail]::new()
        $LineArray = $_.split($ES)
        $WorkingDetail.Quantity = 1
        $WorkingDetail.InvoiceNumber = $WorkingInvoice.InvoiceNumber
        if($LineArray[1] -eq 'C'){
            $WorkingDetail.UnitPrice = $LineArray[5]/100
        }elseif($LineArray[1] -eq 'A'){
            $WorkingDetail.UnitPrice = -1*$LineArray[5]/100
        }
        $WorkingDetail.IsSAC = $true
        $WorkingDetail.SACCode = $LineArray[2]
        continue
    }

    {$_.startswith('CTT')} {
        Write-Verbose 'Confirming Item Count'
        $WorkingInvoice.IsComplete = ($_.split($ES) -eq $ItemCounter)
        continue
    }
        
    default {Write-Verbose "Unhandled line in EDI File.`n$_";continue} #if not match above, keep moving
        
}

#make sure lingering details and headers are put into the output
if ($WorkingDetail){
    Write-Verbose 'Adding lingering detail to output'
    [void]$DetailsToUpload.Add($WorkingDetail)
}
if ($WorkingInvoice){
    Write-Verbose 'Adding lingering header to output'
    [void]$InvoicesToUpload.Add($WorkingInvoice)
}

Write-Verbose "Invoices Found: $($InvoicesToUpload.count)"
Write-Verbose "Details Found: $($DetailsToUpload.count)"
$output = @{
    Invoice = $InvoicesToUpload
    Detail = $DetailsToUpload
}

return $output

}
