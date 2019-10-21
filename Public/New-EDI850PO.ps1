function New-EDI850PO {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [EDI850Header]$Header,
        [Parameter(Mandatory = $true)]
        [EDI850Detail[]]$Details,
        [string]$ES = $ModuleConfig.EDIOUT.ElementSeparator
    )

    $PO = New-Object -TypeName 'System.Collections.ArrayList'
    [void]$PO.Add(@('ST','850',$Header.ControlNum.PadLeft(4,'0')) -join $ES)
    [void]$PO.Add(@('BEG','00','SA',$Header.PONum,'',(Get-Date $Header.Date -Format yyyyMMdd)) -join $ES)
    if($Header.VendorID){
        [void]$PO.Add(@('REF','IA',$Header.VendorID) -join $ES)
    }
    if($Header.Memo){
        #replace the element separator in the memo with some other character
        [void]$PO.Add(@('N9','L1','','See attached note') -join $ES)
        [void]$PO.Add(@('MTX','GEN',($Header.Memo.Replace($ES,'_'))) -join $ES)
    }
    #N1 Party Identification - BillTo
    if($Header.BTAccountNumber){
        [void]$PO.Add(@('N1','BT',$Header.BTName,'91',$Header.BTAccountNumber) -join $ES)
    }else{
        [void]$PO.Add(@('N1','BT',$Header.BTName) -join $ES)
    }
    [void]$PO.Add(@('N3',$Header.BTAddress) -join $ES)
    [void]$PO.Add(@('N4',$Header.BTCity,$Header.BTState,$Header.BTZip) -join $ES)

    #N1 Party Identification - ShipTo
    if($Header.STLocationID){
        [void]$PO.Add(@('N1','ST',$Header.STName,'92',$Header.STLocationID) -join $ES)
    }else{
        [void]$PO.Add(@('N1','ST',$Header.STName) -join $ES)
    }
    [void]$PO.Add(@('N3',$Header.STAddress) -join $ES)
    [void]$PO.Add(@('N4',$Header.STCity,$Header.STState,$Header.STZip) -join $ES)
    if($Header.BuyerEmail -or $Header.BuyerName -or $Header.BuyerPhone){
        $String = @('PER','BD',"$($Header.BuyerName)")
        if($Header.BuyerEmail){
            $String += @('EM',$Header.BuyerEmail)
        }
        if($Header.BuyerPhone){
            $String += @('TE',$Header.BuyerPhone)
        }
        [void]$PO.Add($String -join $ES)
    }

    #Add details to order

    foreach($Detail in $Details){
        $Cost = ''
        if($Detail.cost){
            $Cost = [math]::Round($Detail.cost,2).ToString()
        }

        $String = @('PO1','',$Detail.Quantity,$Detail.UOM,$Cost,'UM')
        if($Detail.VendorCode){
            $String += @('VN',$Detail.VendorCode)
        }
        if($Detail.UPC){
            switch($Detail.UPC.Length){
                12 {$String += @('UP',$Detail.UPC)}
                13 {$String += @('EN',$Detail.UPC)}
                14 {$String += @('UK',$Detail.UPC)}
            }
        }
        [void]$PO.Add($String -join $ES)
        if($Detail.Description){
            [void]$PO.Add(@('PID','F','','','',$Detail.Description) -join $ES)
        }
        if($Detail.Note){
            [void]$PO.Add(@('N9','L1','',$Detail.Note) -join $ES)
        }
    }

    #Finish Order
    [void]$PO.Add(@('CTT',$Details.Length) -join $ES)
    [void]$PO.Add(@('SE',"$($PO.Count+1)",$Header.ControlNum.PadLeft(4,'0')) -join $ES)

    #Return array of strings
    return $PO
}
