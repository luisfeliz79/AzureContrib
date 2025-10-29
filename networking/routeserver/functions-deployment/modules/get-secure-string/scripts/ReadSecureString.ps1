
         [PSCustomObject]@{
             value = "SunnySide1219!"
         } | ConvertTo-Json 

# param(
#     [Parameter(Mandatory=$true)]
#     [string]$File_Path

# )

# if (-not (Test-Path $File_Path)) {

#     Write-Error "Could not find $File_Path"
#     break

# } else {

#     $EncPass = Get-Content $File_Path

#     if ($EncPass -ne "" -and $EncPass -ne $null) {
#         Write-Warning "Returning the decrypted password"

#         $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($EncPass | ConvertTo-SecureString))
#         $pass= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

#         [PSCustomObject]@{
#             value = $pass
#         } | ConvertTo-Json 
        
#     } else {
        
#          Write-Error "$File_path is empty"
#     }

# }
