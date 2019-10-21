function Parse-SPS997Acknowledgement {
    param(
        [Parameter(Mandatory = $true,ParameterSetName='File')]
        [ValidateScript({Test-Path $_})]
        [string] $Path,

        [Parameter(Mandatory = $true,ParameterSetName='Content')]
        [string[]] $Content,

        [switch]$RemoveEnvelopes,

        [string] $ES = '*'

    )

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

    $Acknowledgement = @{
        FGroupCtrlNum = $null
        Accepted = 0
        Error = 0
    }

    switch($RawDocument){
        {$_.StartsWith('AK1')}{
            $LineSplit = $_.split($ES)
            $Acknowledgement.FGroupCtrlNum = $LineSplit[2]
        }

        {$_.StartsWith('AK9')}{
            $LineSplit = $_.split($ES)
            switch($LineSplit[1]){
                {$_ -in @('A','E')} {$Acknowledgement.Accepted = 1}
                {$_ -ne 'A'}{$Acknowledgement.Error = 1}
            }
        }
    }

    return $Acknowledgement

}