#Find all processes where uptime is greater than 500 seconds. If script is running more than
#10 seconds, terminate script.

function find_process_uptime {

if($startDTM)  {
    Remove-Variable startDTM -force
}

Set-Variable startDTM -option ReadOnly -value (Get-Date)

$endDTM = (Get-Date)   
if ($(($endDTM-$startDTM).totalseconds) -gt 10) {
    "Run time is more than 50. Programm exit!"
    exit

} else {
        #$processes"Run time is $(($endDTM-$startDTM).totalseconds)"
        foreach ($x in Get-Process) {

        if ($x.id -eq 0) {

        } else {
                $proc_uptime = (get-date).Subtract((Get-Process -id $x.Id).starttime).TotalSeconds
                #$x.id
                if ($proc_uptime -gt 500) {
                "Uptime of " + $x.ProcessName + " is more than 500 seconds: " + $proc_uptime
                } else {

                }
            }

        }
    }
}


