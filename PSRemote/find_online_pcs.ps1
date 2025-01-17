for ($i = 11; $i -lt 255; $i++) {
$pc_names = @("192.168.60." + $i)
foreach ($pc_name in $pc_names) {  
    
        try {
        $ServiceListError = Test-WSMan -ComputerName $pc_name -ErrorVariable SeviceListError
        if ($ServiceListError) {
            Invoke-Command -ComputerName $pc_name -ScriptBlock {
            
            $ip_address     = gwmi Win32_NetworkAdapterConfiguration | Where { $_.IPAddress } | Select -Expand IPAddress | Where { $_ -like '192.168.*' }
            $pc_name        = (gwmi Win32_ComputerSystem).Name
            "$ip_address ($pc_name) is online"
            }
        } else {
        }
        } catch {
        "$pc_name offline"
        }
    }
}