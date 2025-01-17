#powershell -command "& { . \\ubuntu64\sys$\script\powershell\done\ready.ps1; Get-PCUptime }"
#=========================================================================
#========================Declare variables================================
$OStype = (gwmi win32_ComputerSystem).SystemType
$pc_name = (gwmi Win32_ComputerSystem).Name
$workgroup = (gwmi Win32_ComputerSystem).Domain
$user_name = ((gwmi win32_Computersystem).UserName).Split("\")[1]
$OSname = (gwmi Win32_OperatingSystem).Caption
$ServicePack = (gwmi Win32_OperatingSystem).CSDVersion
$ip_address = gwmi Win32_NetworkAdapterConfiguration | Where { $_.IPAddress } | Select -Expand IPAddress | Where { $_ -like '192.168.*' }
$mac_address = gwmi win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true } | Foreach-Object { $_.MACAddress }
$date = Get-Date -format G


#==========================End of declaring===============================
#=========================================================================

function FindConnector {
if( $OStype -match "X86") {
    #Write-Host "32 bit operating system"
    $win32 = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall -ErrorAction SilentlyContinue | foreach-object {Get-ItemProperty $_.PsPath} | select DisplayName | select-string -pattern "MySQL Connector"
    if($win32 -match "@{DisplayName=MySQL Connector Net 6.5.4}") {
        "Software found"
        } else {
        "installing"
        $msbuild = "\\ubuntu64\sys$\mysql-connector-net-6.5.4.msi"
        $args = "/passive"
        $process = [System.Diagnostics.Process]::Start($msbuild, $args).WaitForExit()
        }
    } else {
    #Write-Host "64 bit operating system"
    $win64 = Get-ChildItem "HKLM:SOFTWARE\Wow6432Node\MySQL AB" -ErrorAction SilentlyContinue | foreach-object {Get-ItemProperty $_.PsPath} | select PSChildName | select-string -pattern "MySQL Connector/Net"
    if($win64 -match "@{PSChildName=MySQL Connector/Net}") {
        "Software found"
        } else {
        "installing"
        $msbuild = "\\ubuntu64\sys$\mysql-connector-net-6.5.4.msi"
        $args = "/passive"
        $process = [System.Diagnostics.Process]::Start($msbuild, $args).WaitForExit()
        }
    }
}
#=========================================================================
#------------------------- Connecting to database ------------------------

[void][system.reflection.assembly]::LoadWithPartialName("MySql.Data")
$dbconnect = New-Object -TypeName MySql.Data.MySqlClient.MySqlConnection
$dbconnect.ConnectionString = (“server=ubuntu64;user id=estellog;password=123;database=estelstatistic;pooling=false")
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect

#------------------------- End of database connection --------------------
#=========================================================================


#=========================================================================
#======================== Uptime calculation =============================
function WMIDateStringToDate($Bootup)
{[System.Management.ManagementDateTimeconverter]::ToDateTime($Bootup)}
$Computer = “."
$computers = Get-WMIObject -class Win32_OperatingSystem -computer $computer
foreach ($system in $computers) {
$Bootup = $system.LastBootUpTime
$LastBootUpTime = WMIDateStringToDate($Bootup)
$dateUp = Get-Date
$uptime = $dateUp – $lastBootUpTime
$uptime_days = $uptime.Days
$uptime_hours = $uptime.Hours
$uptime_minutes = $uptime.Minutes
$uptime_seconds= $uptime.Seconds
$uptime_total_hours = $uptime.TotalHours
}
#============================= Uptime end ================================
#=========================================================================


#========================================================================#
function software {
    $sql.CommandText = "select pc_name from tarkvara WHERE pc_name = '$pc_name'"
    $read_pc = $sql.ExecuteReader()

    while ($read_pc.Read()) {
        for ($j= 0; $j -lt $read_pc.FieldCount; $j++) {
            $sqlread_pc = $read_pc.GetValue($j).ToString()
        }
    }
    if($sqlread_pc -eq $null) {
        Write-Host "No data for $pc_name found. Soft Exit"
        $dbconnect.Close()
        } else {
        $dbconnect.Close()
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "select status from tarkvara WHERE pc_name = '$pc_name'"
        $read_status = $sql.ExecuteReader()

        while ($read_status.Read()) {
            for ($i= 0; $i -lt $read_status.FieldCount; $i++) {
            $status = $read_status.GetValue($i).ToString()
            }
        }
        if($status -eq "DONE") {
        #Write-Host "SOFT DO NOTHING. Status is $STATUS"
        $dbconnect.Close()
        } else {
        #Write-Host "Starting software..."
#---------------------------------read software------------------------------------#
        $dbconnect.Close()
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "select software from tarkvara WHERE pc_name = '$pc_name'"
        $software = $sql.ExecuteReader()
        
        while ($software.Read()) {
            for ($h= 0; $h -lt $software.FieldCount; $h++) {
            $soft = $software.GetValue($h).ToString()
                }
            }
        $dbconnect.Close()
#---------------------------------read args ------------------------------------#
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        
        $sql.CommandText = "select argument from tarkvara WHERE pc_name = '$pc_name'"
        $argument = $sql.ExecuteReader()
        
        while ($argument.Read()) {
        for ($h= 0; $h -lt $argument.FieldCount; $h++) {
            $argumentsql = $argument.GetValue($h).ToString()
                    }
                }
        $dbconnect.Close()
#---------------------------------read action------------------------------------#
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "select action from tarkvara WHERE pc_name = '$pc_name'"
        $sqlSoftAction = $sql.ExecuteReader()
        
        while ($sqlSoftAction.Read()) {
        for ($h= 0; $h -lt $sqlSoftAction.FieldCount; $h++) {
            $softaction = $sqlSoftAction.GetValue($h).ToString()
                    }
                }
        $dbconnect.Close()
#--------------------------------- read end ------------------------------------#
        if($softaction -eq "install") {
        #"Installing $soft"
        (gwmi -ComputerName . -List | Where-Object -FilterScript {$_.Name -eq "Win32_Product"}).Install("$soft")
        } elseif($softaction -eq "remove") {
        #"Removing $soft with GUID $soft"
        (gwmi Win32_Product -Filter "IdentifyingNumber='$soft'" -ComputerName . ).Uninstall()
        } elseif($softaction -eq "run"){
        #"Running $soft with arguments $argumentsql"
        $process = [System.Diagnostics.Process]::Start($soft, $argumentsql).WaitForExit()
        } elseif($softaction -eq "cmd") {
        #"Command prompt is $soft"
        cmd /c $soft
        } else {
        }
                $dbconnect.Open()
                $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
                $sql.Connection = $dbconnect
                $sql.CommandText = "UPDATE tarkvara SET status = 'DONE' WHERE pc_name = '$pc_name'"
                $sql.ExecuteNonQuery()
                $dbconnect.Close()
        }
    }
}
#=========================================================================#
#-------------------------kasutaja haldamine------------------------------#

function users {

$dbconnect.Close()
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = "select pc_name from kasutajad WHERE pc_name = '$pc_name'"
$read_pcusers = $sql.ExecuteReader()

    while ($read_pcusers.Read()) {
        for ($j= 0; $j -lt $read_pcusers.FieldCount; $j++) {
            $sqlread_pcusers = $read_pcusers.GetValue($j).ToString()
        }
    }
    
    if($sqlread_pcusers -eq $null) {
        #Write-Host "No data for $pc_name found. Users Exit"
        $dbconnect.Close()
    } else {
        $dbconnect.Close()
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "select status from kasutajad WHERE pc_name = '$pc_name'"
        $read_userstatus = $sql.ExecuteReader()

    while ($read_userstatus.Read()) {
        for ($s= 0; $s -lt $read_userstatus.FieldCount; $s++) {
            $userstatus = $read_userstatus.GetValue($s).ToString()
        }
    }
        if($userstatus -ceq "DONE") {
        #Write-Host "USERS DO NOTHING. Status is DONE"
        $dbconnect.Close()
        } else {
        $dbconnect.Close()
#-------------------------- read action-- --------------------------------#
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "select action from kasutajad WHERE pc_name = '$pc_name'"
        $readaction = $sql.ExecuteReader()
        
    while ($readaction.Read()) {
        for ($a= 0; $a -lt $readaction.FieldCount; $a++) {
            $sqluseraction = $readaction.GetValue($a).ToString()
            }
    }
        $dbconnect.Close()
#--------------------------read username-----------------------------------#
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "select username from kasutajad WHERE pc_name = '$pc_name'"
        $username = $sql.ExecuteReader()
        
    while ($username.Read()) {
        for ($l= 0; $l -lt $username.FieldCount; $l++) {
            $sqluserstatus = $username.GetValue($l).ToString()
        }
    }
        $dbconnect.Close()
#-------------------------- read password----------------------------------#
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "select password from kasutajad WHERE pc_name = '$pc_name'"
        $readpassword = $sql.ExecuteReader()
        
    while ($readpassword.Read()) {
        for ($p= 0; $p -lt $readpassword.FieldCount; $p++) {
            $sqlreadpassword = $readpassword.GetValue($p).ToString()
        }
    }
        $dbconnect.Close()
#--------------------------read usegroup ----------------------------------#
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "select usergroup from kasutajad WHERE pc_name = '$pc_name'"
        $readgroup = $sql.ExecuteReader()
        
    while ($readgroup.Read()) {
        for ($d= 0; $d -lt $readgroup.FieldCount; $d++) {
            $sqlreadgroup = $readgroup.GetValue($d).ToString()
        }
    }
        $dbconnect.Close()
#-------------------------- read description -------------------------------#
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "select description from kasutajad WHERE pc_name = '$pc_name'"
        $readdescription = $sql.ExecuteReader()
        
    while ($readdescription.Read()) {
        for ($d= 0; $d -lt $readdescription.FieldCount; $d++) {
            $sqlreaddescription = $readdescription.GetValue($d).ToString()
        }
    }
        $dbconnect.Close()
#-------------------------- end of reading--- ------------------------------#
                #Write-Host "Action = $sqluseraction, user = $sqluserstatus, password = $sqlreadpassword, group = $sqlreadgroup , description = $sqlreaddescription "
                if ($sqluseraction -cmatch "create") {
                #Write-Host "Equals useradd"
                $computer = [adsi]"WinNT://$pc_name,computer"
                $user = $computer.Create("user", $sqluserstatus)
                $user.SetPassword($sqlreadpassword)
                $user.SetInfo()
                $user.Description = [String] $sqlreaddescription
                $user.SetInfo()
                $computer = [adsi]"WinNT://$pc_name,computer"
                $computer.Create("user", $sqluserstatus)
                [string]$computerName = "$pc_name"         
                $LocalGroup = [adsi]"WinNT://$computerName/$sqlreadgroup,group"
                $LocalGroup.Add("WinNT://$pc_name/$sqluserstatus")
                } elseif ($sqluseraction -ceq "userdel") {
                #Write-Host "Equals DELETE"
                [string]$ConnectionString = "WinNT://$pc_name"
                 $ADSI = [adsi]$ConnectionString
                 $ADSI.Delete("user",$sqluserstatus)
                } elseif ($sqluseraction -ceq "changepw") {
                #Write-Host "Equals CHANGE"
                [string]$ConnectionString = "WinNT://" + $pc_name + "/" + $sqluserstatus + ",user"
                 $Account = [adsi]$ConnectionString
                 $Account.psbase.invoke("SetPassword", $sqlreadpassword)
                } else {
                #Write-Host "Equals NOTHING"
                }
                $dbconnect.Open()
                $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
                $sql.Connection = $dbconnect
                $sql.CommandText = "UPDATE kasutajad SET status = 'DONE' WHERE pc_name = '$pc_name'"
                $sql.ExecuteNonQuery()
                $dbconnect.Close()
        }
    }
}
#------------------------kasutaja haldamine end----------------------------#
#===========================================================================

#=============================================================================#
#============================== Funktsioonid =================================#
#users

function callfunctions {

$dbconnect.Close()
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = "select pc_name from funktsioonid WHERE pc_name = '$pc_name'"

    $read_functionusers = $sql.ExecuteReader()

    while ($read_functionusers.Read()) {
        for ($j= 0; $j -lt $read_functionusers.FieldCount; $j++) {
        $sqlread_functionusers = $read_functionusers.GetValue($j).ToString()
        }
    }
    
        if($sqlread_functionusers -eq $null) {
        #Write-Host "Puuduvad andmed. Funktsioon loppeb"
        $dbconnect.Close()
        } else {
        $dbconnect.Close()
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect

        $sql.CommandText = "select status from funktsioonid WHERE pc_name = '$pc_name'"
        $read_functionstatus = $sql.ExecuteReader()

    while ($read_functionstatus.Read()) {
        for ($s= 0; $s -lt $read_functionstatus.FieldCount; $s++) {
        $sql_functionstatus = $read_functionstatus.GetValue($s).ToString()
        }
    }
        if($sql_functionstatus -eq "DONE") {
        #Write-Host "Funktsiooni kutsumine loppeb. Status on DONE"
        $dbconnect.Close()
        } else {
        $dbconnect.Close()
#-------------------------- read action-- --------------------------------#
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "select function from funktsioonid WHERE pc_name = '$pc_name'"
        $readfunction_name = $sql.ExecuteReader()
        
        while ($readfunction_name.Read()) {
            for ($a= 0; $a -lt $readfunction_name.FieldCount; $a++) {
            $sql_readfunction_name = $readfunction_name.GetValue($a).ToString()
            }
        }
        $dbconnect.Close()
        #"Hakkan kutsuma funktsiooni $sql_readfunction_name toojaamas $pc_name"
        Invoke-Expression $sql_readfunction_name
        
                $dbconnect.Close()
        $dbconnect.Open()
        $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
        $sql.Connection = $dbconnect
        $sql.CommandText = "UPDATE funktsioonid SET status = 'DONE' WHERE pc_name = '$pc_name'"
        $sql.ExecuteNonQuery()
        $dbconnect.Close()
                
            }
        }
}


#==========================================================================#
#============================== Kasutajad =================================#
function log_in {
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = “INSERT INTO statistika (pc_name, user_name, ip_address, date, uptime_days, uptime_hours, uptime_minutes, uptime_seconds, action) VALUES ('$pc_name','$user_name','$ip_address','$date','$uptime_days','$uptime_hours','$uptime_minutes','$uptime_seconds','LOGON')"
$sql.ExecuteNonQuery()
$dbconnect.Close()
}

function log_out {
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = “INSERT INTO statistika (pc_name, user_name, ip_address, date, uptime_days, uptime_hours, uptime_minutes, uptime_seconds, action) VALUES ('$pc_name','$user_name','$ip_address','$date','$uptime_days','$uptime_hours','$uptime_minutes','$uptime_seconds','LOGOUT')"
$sql.ExecuteNonQuery()
$dbconnect.Close()
}

function start_up {

<#
foreach ($sec in Get-Process) {
if ($sec.ProcessName -eq "fsav32") {
"Found FSAV32. Exit."
} else {
"Could not find FSAV32. Continue.."
$GetFile = gc "\\ubuntu64\sys$\pcinfo\fsecure.txt"
if ($getFile -match "$pc_name") {
"PC name is in the list. Continue..."
$GetFile_done = gc "\\ubuntu64\sys$\pcinfo\fsec_done.txt"
if($getFile_done -match "$pc_name") {
"Function already run. Exit "
} else {
if ($OSName -match "XP") {
"Windows XP. Running MSEinstall.exe"
cmd /c \\ubuntu64\sys$\utils\mseinstall_xp.exe /s /q /runwgacheck
"$pc_name" | Out-File -append "\\ubuntu64\sys$\pcinfo\fsec_done.txt"
} else {
"Windows 7 or Vista. Running MSEinstall.exe"
cmd /c \\ubuntu64\sys$\utils\mseinstall_7.exe /s /q /runwgacheck
"$pc_name" | Out-File -append "\\ubuntu64\sys$\pcinfo\fsec_done.txt"
}
}
} else {
"Pc name is not in the list. Exit"
}
break
}
}
#>

$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = “INSERT INTO statistika (pc_name, user_name, ip_address, date, uptime_days, uptime_hours, uptime_minutes, uptime_seconds, action) VALUES ('$pc_name','$user_name','$ip_address','$date','$uptime_days','$uptime_hours','$uptime_minutes','$uptime_seconds','STARTUP')"
$sql.ExecuteNonQuery()
$dbconnect.Close()
}

function schedule {
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = “INSERT INTO statistika (pc_name, user_name, ip_address, date, uptime_days, uptime_hours, uptime_minutes, uptime_seconds, action) VALUES ('$pc_name','$user_name','$ip_address','$date','$uptime_days','$uptime_hours','$uptime_minutes','$uptime_seconds','SCHEDULE')"
$sql.ExecuteNonQuery()
$dbconnect.Close()
}

function shut_down {
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = “INSERT INTO statistika (pc_name, user_name, ip_address, date, uptime_days, uptime_hours, uptime_minutes, uptime_seconds, action) VALUES ('$pc_name','$user_name','$ip_address','$date','$uptime_days','$uptime_hours','$uptime_minutes','$uptime_seconds','SHUTDOWN')"
$sql.ExecuteNonQuery()
$dbconnect.Close()
}
#============================= Functions end =============================#
#=========================================================================#



#============================= Custom functions ================================#
#-------------------------------------------------------------------------------#
function FindUserFiles {

$dbconnect.Close()
$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select computer from andmete_mahud"
$myreader = $mycommand.ExecuteReader()
$readpc_name_fromandmete = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

if ($readpc_name_fromandmete -eq $pc_name) {
"This computer already exists."
} else { #else1 start
if ($OSName -eq "Microsoft Windows XP Professional") {
"OS name is Windows XP ($OSname)"
$findprofile = Get-childItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | % {Get-ItemProperty $_.pspath }
foreach ($userpro in $findprofile) { #foreach1
$lol1 = $userpro | Where-Object {$_.ProfileImagePath -ne "C:\WINDOWS\system32\config\systemprofile"}
$lol2 = $lol1 | Where-Object {$_.ProfileImagePath -ne "C:\Documents and Settings\LocalService"}
$lol3 = $lol2 | Where-Object {$_.ProfileImagePath -ne "C:\Documents and Settings\NetworkService"}
$lol4 = $lol3 | Where-Object {$_.ProfileImagePath -notlike "*Administrator*"}
$lol5 = $lol4 | Where-Object {$_.ProfileImagePath -notlike "*Guest*"}
$newprofile = $lol5.ProfileImagePath

foreach ($lastprofile in $newprofile) { #foreach2

$Desktop_loc = $lastprofile + "\Desktop"
$MyDocs_loc = $lastprofile + "\My Documents"
$MyDocs_loc7 = $lastprofile + "\Documents"
$Pictures_loc = $lastprofile + "\Pictures"
$Downloads_loc = $lastprofile + "\Downloads"
if ($lastprofile -eq $null) { #if3
"profile empty"
} else {
"Checking profile $lastprofile..."
"looking for outlook...."
$outlook = (Get-ChildItem -Path C:\ -Recurse -Filter "*.pst" -force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
$outlook_sum = "{0:N3}" -f ($outlook.sum / 1GB) + " GB"
"done! Outlook is $outlook_sum"
"Searching my documents..."
$mydocs = (Get-ChildItem -Path $MyDocs_loc -Recurse -force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
$mydocs_sum = "{0:N3}" -f ($mydocs.sum / 1GB) + " GB"
"done! Mydocuments is $mydocs_sum"
"Searching Desktop..."
$desktop = (Get-ChildItem -Path $Desktop_loc -Recurse -force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
$desktop_sum = "{0:N3}" -f ($desktop.sum / 1GB) + " GB"
"done! Desktop is $desktop_sum"
$total = "{0:N3}" -f (($outlook.sum + $mydocs.sum + $desktop.sum) / 1073741824) + " GB"
"Total size is $total"
$newlastprofile = $lastprofile.replace("\","\\")
$dbconnect.Close()
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = “INSERT INTO andmete_mahud (username, computer, outlook, mydocs, desktop, total) VALUES ('$newlastprofile','$pc_name','$outlook_sum','$mydocs_sum', '$desktop_sum','$total')"
    $sql.ExecuteNonQuery()
    $dbconnect.Close()
            }#if3
        }
    }
    
    } else {
    "Not winxp"
    }
    }
 "---------------------------------------------"

    if ($readpc_name_fromandmete -eq $pc_name) {
    "This computer already exists."
    } else {
#--------------------------------------------------------------------------#
    if ($OSName -match "7") {
    "OS name is 7"
    $findprofile = Get-childItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | % {Get-ItemProperty $_.pspath }
    foreach ($userpro in $findprofile) {

    $lol1 = $userpro | Where-Object {$_.ProfileImagePath -ne "C:\Windows\system32\config\systemprofile"}
    $lol2 = $lol1 | Where-Object {$_.ProfileImagePath -ne "C:\Windows\ServiceProfiles\LocalService"}
    $lol3 = $lol2 | Where-Object {$_.ProfileImagePath -ne "C:\Windows\ServiceProfiles\NetworkService"}
    $lol4 = $lol3 | Where-Object {$_.ProfileImagePath -ne "C:\Users\UpdatusUser"}
    $lol5 = $lol4 | Where-Object {$_.ProfileImagePath -notlike "*Administrator*"}
    $lol6 = $lol5 | Where-Object {$_.ProfileImagePath -notlike "*Classic*"}
    $lol7 = $lol6 | Where-Object {$_.ProfileImagePath -notlike "*Default*"}

    $newprofile = $lol7.ProfileImagePath
    foreach ($lastprofile in $newprofile) {

    $Desktop_loc = $lastprofile + "\Desktop"
    $MyDocs_loc = $lastprofile + "\My Documents"
    $MyDocs_loc7 = $lastprofile + "\Documents"
    $Pictures_loc = $lastprofile + "\Pictures"
    $Downloads_loc = $lastprofile + "\Downloads"
    
    if ($lastprofile -eq $null) {
    "profile empty"
    } else {
    "Checking profile $lastprofile..."
    "looking for outlook...."
    $outlook = (Get-ChildItem -Path C:\ -Recurse -Filter "*.pst" -force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
    $outlook_sum = "{0:N3}" -f ($outlook.sum / 1GB) + " GB"
    "done! Outlook is $outlook_sum"
    "Searching my documents..."
    $mydocs = (Get-ChildItem -Path $MyDocs_loc7 -Recurse -force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
    $mydocs_sum = "{0:N3}" -f ($mydocs.sum / 1GB) + " GB"
    "done! My documents is $mydocs_sum"
    "Searching Desktop..."
    $desktop = (Get-ChildItem -Path $Desktop_loc -Recurse -force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
    $desktop_sum = "{0:N3}" -f ($desktop.sum / 1GB) + " GB"
    "done! Desktop is $desktop_sum"
    $downloads = (Get-ChildItem -Path $Downloads_loc -Recurse -force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
    $downloads_sum = "{0:N3}" -f ($downloads.sum / 1GB) + " GB"
    "done! Donwloads is $downloads_sum"
    "Searching Desktop..."
    $pictures = (Get-ChildItem -Path $Pictures_loc -Recurse -force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
    $pictures_sum = "{0:N3}" -f ($pictures.sum / 1GB) + " GB"
    "done! Pictures is $pictures_sum"
    $total = "{0:N3}" -f (($outlook.sum + $mydocs.sum + $desktop.sum + $downloads.sum + $pictures.sum) / 1073741824) + " GB"
    "Total size is $total"
    
    $newlastprofile = $lastprofile.replace("\","\\")
    
    $dbconnect.Close()
    $dbconnect.Open()
    $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
    $sql.Connection = $dbconnect
    $sql.CommandText = “INSERT INTO andmete_mahud (username, computer, outlook, mydocs, desktop, downloads, pictures, total) VALUES ('$newlastprofile','$pc_name','$outlook_sum','$mydocs_sum', '$desktop_sum','$downloads_sum','$pictures_sum','$total')"
$sql.ExecuteNonQuery()
$dbconnect.Close()
}#if3
}
}
} else {
"not win7"
}
}
}
#Copy-Item -Path C:\ -Recurse -Filter "*.pst" -force -ErrorAction SilentlyContinue -Destination c:\new\
#FindUserFiles
function FindUsers {

$FindUsers_fileName = "$pc_name.txt"
$FindUsers_filePath = "\\ubuntu64\sys$\pcinfo\users\" + $FindUsers_fileName
$sql_FindUsers_filePath = "\\\\ubuntu64\\sys$\\pcinfo\\users\\" + $FindUsers_fileName

if(!(test-path $sql_FindUsers_filePath)) {
"file not found"
gwmi Win32_UserAccount -filter "domain='$pc_name'" |
select -expand name |
Out-File "$FindUsers_filePath"
$dbconnect.Close()
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = "UPDATE funktsioonid SET log_location = '$sql_FindUsers_filePath' WHERE function = '$sql_readfunction_name' AND pc_name = '$pc_name'"
$sql.ExecuteNonQuery()

} else {
"found"
}
}

function FindSoftware {

$FindSoftware_fileName = "$pc_name.txt"
$FindSoftware_filePath = "\\ubuntu64\sys$\pcinfo\software\" + $FindSoftware_fileName
$sql_FindSoftware_filePath = "\\\\ubuntu64\\sys$\\pcinfo\\software\\" + $FindSoftware_fileName

if (!([Diagnostics.Process]::GetCurrentProcess().Path -match '\\syswow64\\')) {
$unistallPath = "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
$unistallWow6432Path = "\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
@(
if (Test-Path "HKLM:$unistallWow6432Path" ) { Get-ChildItem "HKLM:$unistallWow6432Path"}
if (Test-Path "HKLM:$unistallPath" ) { Get-ChildItem "HKLM:$unistallPath" }
) |
ForEach-Object {Get-ItemProperty $_.PSPath } |
Where-Object {$_.DisplayName -and !$_.SystemComponent -and !$_.ReleaseType -and !$_.ParentKeyName -and ($_.UninstallString -or $_.NoRemove) } |
Sort-Object DisplayName | Select-Object DisplayName, UninstallString, EstimatedSize | Format-table -autosize | Out-String -Width 4096 | Out-File $FindSoftware_filePath
} else {
"Viga. Vale PowerShelli versioon."
}
$dbconnect.Close()
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = "UPDATE funktsioonid SET log_location = '$sql_FindSoftware_filePath' WHERE function = '$sql_readfunction_name' AND pc_name = '$pc_name'"
$sql.ExecuteNonQuery()
$dbconnect.Close()
}


function Monitoring {
"starting to monitor..."
#******************************************************************
#******************************************************************
#******************************************************************
#
# Monitoring system - HOWTO
# new paramter? add new row to db. Fix INSERTs
#
# 1) Create variable
# 2) Add variable (new) to STATS
# 3) Add variable (database) from OLD STATS
# 4) Add variable: compare DATABASE with NEW
# 5) Add compare to CHECK MAIL IF
#
#
#
#******************************************************************
#******************************************************************
#******************************************************************
#--------------------CPU and MOTHERBOARD--------------------------#
#******************************************************************
$CPUname = (gwmi Win32_Processor).Name -replace (" ","")
$mother_name = (gwmi Win32_BaseBoard).Product
#--------------------TOTAL MEMORY--------------------------------#
$mem = Get-WmiObject -Class Win32_ComputerSystem
$TotalMemory = $mem.TotalPhysicalMemory/1mb
$NewTotalMemory = [Math]::Round($TotalMemory, 0)
#------------------Database uptime-------------------------------#
$NewTotalhours = [Math]::Round($uptime_total_hours, 0)
#------------------OS install date-------------------------------#
$OS_istall_date = ([WMI]'').ConvertToDateTime((Get-WmiObject Win32_OperatingSystem).InstallDate).ToString("yyyy-MM-dd")
function Search-RegistryKeyValues {
param(
[string]$path,
[string]$valueName
)
Get-ChildItem $path -recurse -ea SilentlyContinue |
% {
if ((Get-ItemProperty -Path $_.PsPath -ea SilentlyContinue) -match $valueName)
{
$_.PsPath
}
}
}
# find registry key that has value "digitalproductid"
# 32-bit versions
$key = Search-RegistryKeyValues "hklm:\software\microsoft\office" "digitalproductid"
if ($key -eq $null) {
# 64-bit versions
$key = Search-RegistryKeyValues "hklm:\software\Wow6432Node\microsoft\office" "digitalproductid"
if ($key -eq $null) {Write-Host "MS Office is not installed."}
}

$valueData = (Get-ItemProperty $key).digitalproductid[52..66]

# decrypt base24 encoded binary data
$productKey = ""
$chars = "BCDFGHJKMPQRTVWXY2346789"
for ($i = 24; $i -ge 0; $i--) {
$r = 0
for ($j = 14; $j -ge $winproductkey0; $j--) {
$r = ($r * 256) -bxor $valueData[$j]
$valueData[$j] = [math]::Truncate($r / 24)
$r = $r % 24
}
$productKey = $chars[$r] + $productKey
if (($i % 5) -eq 0 -and $i -ne 0) {
$productKey = "-" + $productKey
}
}


function Get-SerialNumber {
$regVal = Get-ItemProperty $regDir.PSPath
$arrVal = $regVal.DigitalProductId
$arrBin = $arrVal[52..66]
$arrChr = "B", "C", "D", "F", "G", "H", "J", "K", "M", "P", "Q", "R", `
"T", "V", "W", "X", "Y", "2", "3", "4", "6", "7", "8", "9"
for ($i = 24; $i -ge 0; $i--) {
$k = 0;
for ($j = 14; $j -ge 0; $j--) {
$k = $k * 256 -bxor $arrBin[$j]
$arrBin[$j] = [math]::truncate($k / 24)
$k = $k % 24
}
$strKey = $arrChr[$k] + $strKey
if (($i % 5 -eq 0) -and ($i -ne 0)) {
$strKey = "-" + $strKey
}
}
$strKey
}

$regDir = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$winproductkey = Get-SerialNumber

<#
if(!(test-path C:\aida64\aida64.exe)) {
$productkey = "no aida"
$winproductkey = "no aida"
} else {
"found"
#Stop-Process -processname Inventor
#[void][System.Reflection.Assembly]::LoadWithPartialName(‘Microsoft.VisualBasic’)
#$result = [Microsoft.VisualBasic.Interaction]::MsgBox(“MSGBOX CONTENT.", ‘OKOnly,Critical’, “MSGBOX TITLE")
Stop-Process -processname aida64
Stop-Process -processname aida_rcs.dll
cmd /c C:\aida64\aida64.exe /R $Desktop_loc\$pc_name.ini /custom \\ubuntu64\sys$\office.rpf /INI /SILENT
Start-Sleep -s 5
$read_office = cat "$Desktop_loc\$pc_name.ini" | select-string -pattern "Microsoft Office Standard 2010" | foreach{$_.tostring().split("=")}
$productkey = $read_office[3]
#"office is $productkey"
$read_windows= cat "$Desktop_loc\$pc_name.ini" | select-string -pattern "Windows" | foreach{$_.tostring().split("=")[1]}
$winproductkey = $read_windows[2]
#"windows is $winproductkey"
Remove-Item "$Desktop_loc\$pc_name.ini"
$msbuild = "c:\aida64\aida64.exe"
$args = "/silent /acceptbg /inifile \\ubuntu64\sys$\aida64business2000\aida64.ini"
start-process $msbuild $args
Start-Sleep -s 5
}
#>

if ($OSName -eq "Microsoft Windows XP Professional") {

$mon_name = @()
$mon_manu = @()
$mon_seri = @()
$mon_code = @()

$ErrorActionPreference_Backup = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$keytype=[Microsoft.Win32.RegistryHive]::LocalMachine

if($reg=[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($keytype,$compname)) {

"Os is XP"

$montable = New-Object system.Data.DataTable "Monitor Info"

$moncol1 = New-Object system.Data.DataColumn Name,([string])
$moncol2 = New-Object system.Data.DataColumn Serial,([string])
$moncol3 = New-Object system.Data.DataColumn Ascii,([string])
$moncol4 = New-Object system.data.DataColumn FullName,([string])
$moncol4 = New-Object system.data.DataColumn Manufacter,([string])

$montable.columns.add($moncol1)
$montable.columns.add($moncol2)
$montable.columns.add($moncol3)
$montable.columns.add($moncol4)
$montable.columns.add($moncol5)

$regKey= $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Enum\DISPLAY" )
$HID = $regkey.GetSubKeyNames()
foreach($HID_KEY_NAME in $HID){
$regKey= $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Enum\\DISPLAY\\$HID_KEY_NAME" )
$DID = $regkey.GetSubKeyNames()
foreach($DID_KEY_NAME in $DID){
$find_control = Get-ChildItem HKLM:\"SYSTEM\CurrentControlSet\Enum\DISPLAY\$HID_KEY_NAME\$DID_KEY_NAME\"
foreach ($x in $find_control) {
if ($x.Name -like"*\Control*") {
$full_name = ($x.Name).Split("\")[5]
$regKey= $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Enum\\DISPLAY\\$HID_KEY_NAME\\$DID_KEY_NAME\\Device Parameters" )
$EDID = $regKey.GetValue("EDID")
foreach($int in $EDID){
$EDID_String = $EDID_String+([char]$int)
}

$monrow=$montable.NewRow()
$checkstring = [char]0x00 + [char]0x00 + [char]0x00 + [char]0xFC + [char]0x00
$matchfound = $EDID_String -match "$checkstring([\w ]+)"
#$checkstring
$monitor_manufacter = $full_name.Substring(0,3)
$monitor_codeid = $full_name.Substring(3,4)

#$monrow.FullName = [string]$monitor_manufacter
if($matchfound) {
$monrow.Name = [string]$matches[1]
} else {
$monrow.Name = '-'
}
$checkstring = [char]0x00 + [char]0x00 + [char]0x00 + [char]0xFF + [char]0x00
$matchfound = $EDID_String -match "$checkstring(\S+)"

if($matchfound) {
$monrow.Serial = [string]$matches[1]
} else {
$monrow.Serial = '-'
}
$checkstring = [char]0x00 + [char]0x00 + [char]0x00 + [char]0xFE + [char]0x00
$matchfound = $EDID_String -match "$checkstring([\w ]+)"


if($matchfound) {
$monrow.Ascii = [string]$matches[1]
} else {
$monrow.Ascii = '-'
}
$EDID_String = ''
$montable.Rows.Add($monrow)
#$full_name
$mon_name += $monrow.Name
$mon_manu += $monitor_manufacter
$mon_seri += $monrow.Serial
$mon_code += $monitor_codeid
#"---------"

}
}
}
}
}
$mon_name = $mon_name -join ','
$mon_manu = $mon_manu -join ','
$mon_seri = $mon_seri -join ','
$mon_code = $mon_code -join ','
$mon_week = "XP no week"
$mon_year = "XP no year"

} else {
"Windows 7"

$search_monitor = Get-WmiObject -Namespace root/wmi -Class WmiMonitorID -ComputerName .

$mon_name = @()
$mon_manu = @()
$mon_seri = @()
$mon_code = @()
$mon_week = @()
$mon_year = @()

foreach ($mon in $search_monitor) {
$monitor_name = [Text.Encoding]::ASCII.GetString(($mon).UserFriendlyName).Trim()
$monitor_manufacter = [Text.Encoding]::ASCII.GetString(($mon).ManufacturerName ).Trim()
$monitor_serial = [Text.Encoding]::ASCII.GetString(($mon).SerialNumberID).Trim()
$monitor_codeID = [Text.Encoding]::ASCII.GetString(($mon).ProductCodeID).Trim()
$monitor_week = ($mon).WeekOfManufacture
$monitor_year = ($mon).YearOfManufacture
$mon_name += $monitor_name
$mon_manu += $monitor_manufacter
$mon_seri += $monitor_serial
$mon_code += $monitor_codeID
$mon_week += $monitor_week
$mon_year += $monitor_year
"---------------------------------------------------------------------"
}
$mon_name = $mon_name -join ','
$mon_manu = $mon_manu -join ','
$mon_seri = $mon_seri -join ','
$mon_code = $mon_code -join ','
$mon_week = $mon_week -join ','
$mon_year = $mon_year -join ','
}




function Get-InstalledAppReg ([string]$ComputerName) {
if(!(test-path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")) {
"registry not found. Exit."
} else {
$RegPath32 = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$BaseKey32 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $ComputerName)
$OpenSubKey32 = $BaseKey32.OpenSubKey($RegPath32)
$OpenSubKey32.GetSubKeyNames() | ForEach {
$Path32 = "$RegPath32\$_"
$BaseKey32.OpenSubKey($Path32).GetValue("DisplayName")
}
}
if(!(test-path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")) {
"registry not found. Exit."
} else {
$RegPath64 = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
$BaseKey64 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $ComputerName)
$OpenSubKey64 = $BaseKey64.OpenSubKey($RegPath64)
$OpenSubKey64.GetSubKeyNames() | ForEach {
$Path64 = "$RegPath64\$_"
$BaseKey64.OpenSubKey($Path64).GetValue("DisplayName")
}
}
}

$officeversionTemp = Get-InstalledAppReg | Select-String "microsoft office 20"

if ($officeversionTemp -match "2010") {
$officeversion1 = "2010"
} else {
$officeversion1 = ""
}

if ($officeversionTemp -match "2007") {
$officeversion2 = "2007"
} else {
$officeversion2 = ""
}

if ($officeversionTemp -match "2003") {
$officeversion3 = "2003"
} else {
$officeversion3 = ""
}

if ($officeversionTemp -match "2000") {
$officeversion4 = "2000"
} else {
$officeversion4 = ""
}

if ($officeversionTemp -notmatch "2000" -and $officeversionTemp -notmatch "2003" -and $officeversionTemp -notmatch "2007" -and $officeversionTemp -notmatch "2010") {
$officeversion5 = "Unknown"
} else {
$officeversion5 = ""
}

$officeversion = @()

if ($officeversion1.length -eq 0) {
} else {
$officeversion_1 = $officeversion1
$officeversion += $officeversion_1
}

if ($officeversion2.length -eq 0) {
} else {
$officeversion_2 = $officeversion2
$officeversion += $officeversion_2
}

if ($officeversion3.length -eq 0) {
} else {
$officeversion_3 = $officeversion3
$officeversion += $officeversion_3
}

if ($officeversion4.length -eq 0) {
} else {
$officeversion_4 = $officeversion4
$officeversion += $officeversion_4
}
if ($officeversion1.length -eq 0) {
} else {
$officeversion_5 = $officeversion5
$officeversion += $officeversion_5
}

$check_aidaexe = Get-Process aida64 -ErrorAction SilentlyContinue
$check_aidadll = Get-Process aida_rcs.dll -ErrorAction SilentlyContinue
if ($check_aidaexe -eq $null -or $check_aidadll -eq $null ) {
$aida = "OFFLINE"
}
else {
$aida = "ONLINE"
}

#------------------------------------------------------------
$CheckFire = ($CheckFirewall = netsh firewall show opmode)[8]
if ($CheckFire -match "Disable")
{
$FirewallStatus = "OFFLINE"
}
else
{
$FirewallStatus = "ONLINE"
}
$dbconnect.Close()
$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select pc_name from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_pcname = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select IP_address from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_IP = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select MAC from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_MAC = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select workgroup from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_workgroup = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select uptime from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_uptime = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select CPU from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_CPU = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select motherboard from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_motherboard = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select RAM from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_RAM = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select OS_name from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_OSname = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select OS_install_date from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_OSinstalldate = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select OS_key from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_OSkey = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select bluescreen from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$read_pcname = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select OS_SP from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_OSsp = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select office from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_office = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select office_ver from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_officever = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select office_key from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_officekey = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select aida from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_aida = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select firewall from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_firewall = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select monitor_name from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_mon_name = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select monitor_manufacter from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_mon_manu = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select monitor_serial from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_mon_serial = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select monitor_codeID from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_mon_code = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select monitor_week from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_mon_week = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()

$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select monitor_year from stats WHERE pc_name = '$pc_name'"
$myreader = $mycommand.ExecuteReader()
$sqlread_mon_year = while($myreader.Read()) { $myreader.GetString(0) }
$dbconnect.Close()


#------------------------------------------------------------#
#-----------------------COMPARE STUFF------------------------#
#------------------------------------------------------------#

if ($sqlread_IP -ne $ip_address) {
$error1 = "$pc_name;IP_Address;$sqlread_IP;$ip_address"
} else {
$error1 = $null
}
#------------------------------------------------------------#
if ($sqlread_MAC -ne $mac_address) {
$error2 = "$pc_name;MAC;$sqlread_MAC;$MAC_address"
} else {
$error2 = $null
}
#------------------------------------------------------------#
if ($sqlread_workgroup -ne $workgroup) {
$error3 = "$pc_name;workgroup;$sqlread_workgroup;$workgroup"
} else {
$error3 = $null
}
#------------------------------------------------------------#
if ($sqlread_CPU -ne $CPUname) {
$error4 = "$pc_name;CPU;$sqlread_CPU;$CPUname"
} else {
$error4 = $null
}
#------------------------------------------------------------#
if ($sqlread_motherboard -ne $mother_name) {
$error5 = "$pc_name;mother;$sqlread_motherboard;$mother_name"
} else {
$error5 = $null
}
#------------------------------------------------------------#
if ($sqlread_OSname -ne $OSname) {
$error6 = "$pc_name;OS;$sqlread_OSname;$OSname"
} else {
$error6 = $null
}
#------------------------------------------------------------#
#if ($sqlread_OSinstalldate -ne $OS_istall_date) {
#$error7 = "$pc_name;OS install date;$sqlread_OSinstalldate;"
#} else {
#$error7 = $null
#}
#------------------------------------------------------------#
if ($sqlread_OSkey -ne $WinProductKey) {
$error8 = "$pc_name;Windows_key;$sqlread_OSkey;$WinProductKey"
} else {
$error8 = $null
}
#------------------------------------------------------------#
if ($sqlread_OSsp -ne $ServicePack) {
$error9 = "$pc_name;win_servicepack;$sqlread_OSsp;$ServicePack"
} else {
$error9 = $null
}
#------------------------------------------------------------#
if ($sqlread_officever -ne $OfficeVersion) {
$error10 = "$pc_name;office_vers;$sqlread_office;$OfficeVersion"
} else {
$error10 = $null
}
#------------------------------------------------------------#
if ($sqlread_officekey -ne $productKey) {
$error11 = "$pc_name;officekey;$sqlread_officekey;$productKey"
} else {
$error11 = $null
}
#------------------------------------------------------------#
if ($sqlread_aida -ne $aida) {
$error12 = "$pc_name;aida;$sqlread_aida;$aida"
} else {
$error12 = $null
}
#------------------------------------------------------------#
if ($sqlread_firewall -ne $FirewallStatus) {
$error13 = "$pc_name;firewall;$sqlread_firewall;$FirewallStatus"
} else {
$error13 = $null
}
#------------------------------------------------------------#
if ($sqlread_mon_name -ne $mon_name) {
$error14 = "$pc_name;monitor_name;$sqlread_mon_name;$mon_name"
} else {
$error14 = $null
}#------------------------------------------------------------#
if ($sqlread_mon_manu -ne $mon_manu) {
$error15 = "$pc_name;mon_manu;$sqlread_mon_manu;$mon_manu"
} else {
$error15 = $null
}#------------------------------------------------------------#
if ($sqlread_mon_serial -ne $mon_seri) {
$error16 = "$pc_name;mon_seri;$sqlread_mon_serial;$mon_seri"
} else {
$error16 = $null
}#------------------------------------------------------------#
if ($sqlread_mon_code -ne $mon_code) {
$error17 = "$pc_name;mon_code;$sqlread_mon_code;$mon_code"
} else {
$error17 = $null
}#------------------------------------------------------------#
#if ($sqlread_mon_week -ne $mon_week) {
#$error18 = "$pc_name;mon_week;$sqlread_mon_week;$mon_week"
#} else {
#$error18 = $null
#}#------------------------------------------------------------#
#if ($sqlread_mon_year -ne $mon_year) {
#$error19 = "$pc_name;mon_year;$sqlread_mon_year;$mon_year"
#} else {
#$error19 = $null
#}
#-------------------------------------------------------------#

$NewSendErrors = "$error1;$error2;$error3;$error4;$error5;$error6;$error7;$error8;$error9;$error10;$error11;$error12;$error13;$error14;$error15;$error16;$error17;"

#-------------------------GENERATE REPORT--------------------#
if(
$sqlread_IP -ne $ip_address -or $sqlread_MAC -ne $MAC_address -or $sqlread_workgroup -ne $workgroup -or
$sqlread_CPU -ne $CPUname -or $sqlread_motherboard -ne $mother_name -or
$sqlread_RAM -ne $NewTotalMemory -or $sqlread_OSname -ne $OSname -or
<#$sqlread_OSinstalldate -ne $OS_istall_date -or#> $sqlread_OSkey -ne $WinProductKey -or
$sqlread_OSsp -ne $ServicePack -or $sqlread_officever -ne $OfficeVersion -or
$sqlread_officekey -ne $productKey -or $sqlread_aida -ne $aida -or
$sqlread_firewall -ne $FirewallStatus -or $sqlread_mon_name -ne $mon_name -or
$sqlread_mon_manu -ne $mon_manu -or $sqlread_mon_serial -ne $mon_seri -or
$sqlread_mon_code -ne $mon_code <#-or $sqlread_mon_week -ne $mon_week -or $sqlread_mon_year -ne $mon_year#>
)
{
#Write-Host "Sending Email"
#SMTP server name
$smtpServer = "mail.neti.ee"
#Creating a Mail object
$msg = new-object Net.Mail.MailMessage
#Creating SMTP server object
$smtp = new-object Net.Mail.SmtpClient($smtpServer)

#Email structure
$msg.From = "powershell@estel.ee"
$msg.ReplyTo = "it@estel.ee"
$msg.To.Add("it@estel.ee")
$msg.subject = "Monitoring $date"
$msg.body = "$NewSendErrors"
$NewSendErrors | Out-File -append "\\ubuntu64\sys$\pcinfo\changes.txt"
#Sending email
#$smtp.Send($msg)
}
else
{
"no errors"
}

#Calling function
$dbconnect.Close()
$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select pc_name from stats"
$myreader = $mycommand.ExecuteReader()
$read_pcname_stats = while($myreader.Read()) { $myreader.GetString(0) }

if ($read_pcname_stats -contains "$pc_name") {
} else {
"name doesn't exist. starting to populate db..."
$dbconnect.Close()
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = “INSERT INTO stats (pc_name, user_name, IP_address, MAC, workgroup, uptime, CPU, motherboard, RAM, OS_name, OS_install_date, OS_key, OS_SP, office_ver, office_key, aida, firewall, monitor_name, monitor_manufacter, monitor_serial, monitor_codeID, monitor_week, monitor_year) VALUES ('$pc_name', '$user_name', '$ip_address', '$MAC_address','$workgroup', '$NewTotalhours', '$CPUname', '$mother_name', '$NewTotalMemory', '$OSname','$OS_istall_date', '$winproductkey', '$ServicePack', '$OfficeVersion', '$productKey', '$aida', '$FirewallStatus' , '$mon_name', '$mon_manu', '$mon_seri', '$mon_code', '$mon_week', '$mon_year' )"
$sql.ExecuteNonQuery()
$dbconnect.Close()
}
$dbconnect.Close()
$dbconnect.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $dbconnect
$mycommand.CommandText = "select pc_name from changes"
$myreader = $mycommand.ExecuteReader()
$read_pcname_changes = while($myreader.Read()) { $myreader.GetString(0) }
if ($read_pcname_changes -notcontains "$pc_name" -or $sqlread_IP -ne $ip_address -or $sqlread_MAC -ne $MAC_address -or $sqlread_workgroup -ne $workgroup -or
$sqlread_CPU -ne $CPUname -or $sqlread_motherboard -ne $mother_name -or
$sqlread_RAM -ne $NewTotalMemory -or $sqlread_OSname -ne $OSname -or
<#$sqlread_OSinstalldate -ne $OS_istall_date -or #>$sqlread_OSkey -ne $WinProductKey -or
$sqlread_OSsp -ne $ServicePack -or $sqlread_officever -ne $OfficeVersion -or
$sqlread_officekey -ne $productKey -or $sqlread_aida -ne $aida -or
$sqlread_firewall -ne $FirewallStatus -or $sqlread_mon_name -ne $mon_name -or
$sqlread_mon_manu -ne $mon_manu -or $sqlread_mon_serial -ne $mon_seri -or
$sqlread_mon_code -ne $mon_code <#-or $sqlread_mon_week -ne $mon_week -or $sqlread_mon_year -ne $mon_year#>
) {
"CHANGEs name doesn't exist or error. starting to populate db..."
$dbconnect.Close()
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = “INSERT INTO changes (pc_name, user_name, IP_address, MAC, workgroup, uptime, CPU, motherboard, RAM, OS_name, OS_install_date, OS_key, OS_SP, office_ver, office_key, aida, firewall, monitor_name, monitor_manufacter, monitor_serial, monitor_codeID, monitor_week, monitor_year) VALUES ('$pc_name', '$user_name', '$ip_address', '$MAC_address','$workgroup', '$NewTotalhours', '$CPUname', '$mother_name', '$NewTotalMemory', '$OSname','$OS_istall_date', '$winproductkey', '$ServicePack', '$OfficeVersion', '$productKey', '$aida', '$FirewallStatus' , '$mon_name', '$mon_manu', '$mon_seri', '$mon_code', '$mon_week', '$mon_year' )"
    $sql.ExecuteNonQuery()
    $dbconnect.Close()
    }
    else {
    "tables changes: nothing"
    }
}


function EnableRemote {

copy \\ubuntu64\sys$\script\powershell\done\EnableRemote.ps1 C:\EnableRemote.ps1
sleep 3
schtasks /CREATE /TN "Enable Remoting" /SC WEEKLY /RU "Administrator" /RP "" /TR "powershell C:\EnableRemote.ps1"
sleep 3
schtasks /RUN /TN "Enable Remoting"
sleep 3
schtasks /DELETE /TN "Enable Remoting" /F
sleep 5
del C:\EnableRemote.ps1

}

#if ($pc_name -eq "kbdell") {
#EnableRemote
    #"$pc_name - $ip_address - done" | Out-File -append "\\ubuntu64\sys$\pcinfo\changes.txt"
    #$find_wirrm = (Get-Service | where {$_.Name -eq "winrm"}).Status
    #"$pc_name $find_wirrm" | Out-File -append "\\ubuntu64\sys$\pcinfo\changes.txt"
    #start-process \\ubuntu64\sys$\script\powershell\done\remove_fescure.bat
#} else {
# "Not kb5"

#}

function EnableRemote_db {

    $sqlread_pc = ""
    $pc_name = (gwmi Win32_ComputerSystem).Name
    [void][system.reflection.assembly]::LoadWithPartialName("MySql.Data")
    $dbconnect = New-Object -TypeName MySql.Data.MySqlClient.MySqlConnection
    $dbconnect.ConnectionString = (“server=ubuntu64;user id=estellog;password=123;database=estelstatistic;pooling=false")
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect

$sql.CommandText = "select status from completed WHERE pc_name = '$pc_name' AND function = 'EnablePSRemote'"
$read_pc = $sql.ExecuteReader()
while ($read_pc.Read())
{
for ($j= 0; $j -lt $read_pc.FieldCount; $j++)
{
$sqlread_pc = $read_pc.GetValue($j).ToString()
}
}

if($sqlread_pc -eq "DONE") {
Write-Host "Already exists"
} else {
Write-Host "Installing..."
copy \\ubuntu64\sys$\script\powershell\done\EnableRemote.ps1 C:\EnableRemote.ps1
sleep 3
schtasks /CREATE /TN "Enable Remoting" /SC WEEKLY /RU "Administrator" /RP "" /TR "powershell C:\EnableRemote.bat"
sleep 3
schtasks /RUN /TN "Enable Remoting"
sleep 3
schtasks /DELETE /TN "Enable Remoting" /f
Start-Service winrm
$dbconnect.Close()
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = “INSERT INTO completed (pc_name, ip_address, function, status) VALUES ('$pc_name','$ip_address','EnablePSRemote','DONE')"
        $sql.ExecuteNonQuery()
        $dbconnect.Close()
        }
}


function ReplaceCobian {

if(!(test-path C:\Estel)) {
    "registry not found. Exit."
  } else {

$sqlread_pc = ""
$pc_name = (gwmi Win32_ComputerSystem).Name
[void][system.reflection.assembly]::LoadWithPartialName("MySql.Data")
$dbconnect = New-Object -TypeName MySql.Data.MySqlClient.MySqlConnection
$dbconnect.ConnectionString = (“server=ubuntu64;user id=estellog;password=123;database=estelstatistic;pooling=false")
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect

$sql.CommandText = "select status from completed WHERE pc_name = '$pc_name' AND function = 'ReplaceCobian'"
$read_pc = $sql.ExecuteReader()
while ($read_pc.Read())
{
for ($j= 0; $j -lt $read_pc.FieldCount; $j++)
{
$sqlread_pc = $read_pc.GetValue($j).ToString()
}
}

if($sqlread_pc -eq "DONE") {
Write-Host "Already exists"
} else {
copy-Item "\\ubuntu64\sys$\script\cobian\cobianbackup.ps1" "C:\Estel\cobian\bat\"

$dbconnect.Close()
$dbconnect.Open()
$sql = New-Object MySql.Data.MySqlClient.MySqlCommand
$sql.Connection = $dbconnect
$sql.CommandText = “INSERT INTO completed (pc_name, ip_address, function, status) VALUES ('$pc_name','$ip_address','ReplaceCobian','DONE')"
        $sql.ExecuteNonQuery()
        $dbconnect.Close()
        }
   }

}

function InstallCobian {

    schtasks /CREATE /TN "InstallCobian" /SC WEEKLY /RU "Administrator" /RP "" /TR 'powershell -command "\\ubuntu64\sys$\script\cobian\cobianbackup.ps1"'
    sleep 3
    schtasks /RUN /TN "InstallCobian"
    sleep 3
    schtasks /DELETE /TN "InstallCobian" /f

}

function Remove-FSecure {

    foreach ($sec in Get-Process) {
        if ($sec.ProcessName -eq "fsav32") {
        "Found FSAV32"
            if ($OSName -match "XP") {
            "Windows XP. Running MSEinstall.exe"
            cmd /c \\ubuntu64\sys$\script\powershell\done\remove_fescure.bat
            #"$pc_name" | Out-File -append "\\ubuntu64\sys$\pcinfo\fsec_done.txt"
            } else {
             "Windows 7 or Vista. Running MSEinstall.exe"
            cmd /c \\ubuntu64\sys$\script\powershell\done\remove_fescure_7.bat
            #"$pc_name" | Out-File -append "\\ubuntu64\sys$\pcinfo\fsec_done.txt"
            }
        break
        } else {
        "Could not find FSAV32"
        }
    }
}


function Find-Fsecure {

    foreach ($sec in Get-Process) {
    
        if ($sec.ProcessName -eq "fsav32") {
        "Found FSAV32"
        $GetFile_new = gc "\\ubuntu64\sys$\pcinfo\fsecure_new.txt"
            if ($getFile_new -match "$pc_name") {
            "Already exists"
            } else {
            "$pc_name" | Out-File -append "\\ubuntu64\sys$\pcinfo\fsecure_new.txt"
            }

        } else {
        "Could not find FSAV32"
        }
        
    }
}


function InstallPowershell_v2 {
    cmd /c "\\ubuntu64\sys$\powershell\Powershell2.exe /quiet"
}

function Get-PCUptime {

$lastboottime = (Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime
$sysuptime = (Get-Date) – [System.Management.ManagementDateTimeconverter]::ToDateTime($lastboottime)
Write-Host "System is Uptime since : " $sysuptime.days "days" $sysuptime.hours "hours" $sysuptime.minutes "minutes" $sysuptime.seconds "seconds"

}

$stuffs = Get-WmiObject Win32_Product

foreach ($p in $stuffs) {

    if ($p.Name -eq "Microsoft Office Professional Plus 2010" ) {
        "This $pc_name has PROFESSIONAL" | Out-File -append "\\ubuntu64\sys$\pcinfo\office.txt"
    } else {
        #"No professional"
    }

}

#if ($pc_name -match "B4") {
# "Hello world" | Out-File "C:\Documents and Settings\Administrator\Desktop\test.txt"
#} else {
# "Not B4"
#}


function FindPCPrinters {
$find_pc_in_list = gc \\ubuntu64\sys$\script\reports\printers.txt
if ($find_pc_in_list -match $pc_name) {
    "Already exists"
} else {
    "Adding printers to text file"
    $Printers = Get-WMIObject Win32_Printer
    "PC name: $pc_name" | Out-file -append \\ubuntu64\sys$\script\reports\printers.txt
    foreach ($Printer in $Printers) {
        $Printer.Name | Out-file -append \\ubuntu64\sys$\script\reports\printers.txt
        $Printer.Location | Out-file -append \\ubuntu64\sys$\script\reports\printers.txt
        $Printer.Comment | Out-file -append \\ubuntu64\sys$\script\reports\printers.txt
    }
    "====================================================" | Out-file -append \\ubuntu64\sys$\script\reports\printers.txt
}

}

function video_card {
    $find_pc_in_list = gc \\ubuntu64\sys$\script\reports\video.txt
    if ($find_pc_in_list -match $pc_name) {
        "Already exists"
    } else {
        "Adding printers to text file"
        $Printers = (Get-WmiObject -Class win32_videocontroller).Name
        "$pc_name | $Printers" | Out-file -append \\ubuntu64\sys$\script\reports\video.txt
        "====================================================" | Out-file -append \\ubuntu64\sys$\script\reports\video.txt
    }

}


