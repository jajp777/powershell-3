del C:\temp.html

'<table border="1" style="border-collapse: collapse">' | Out-File C:\temp.html -append
"<td>PC NAME</td><td>STATUS</td><td>LINK TO FILE</td><td>Total errors</td><td>LAST BACKUP</td>" | Out-File C:\temp.html -append

$month_number = (Get-Date).Month
$check_date_month = Get-Date -format "d."
$check_date_txt = (Get-Date).Day

$nofile_back = @()
$success_back = @()
$error_back = @()
$fail_back = @()

if ($month_number -eq "1") {
$month_location = "januar"
} elseif ($month_number -eq "2") {
$month_location = "februar"
} elseif ($month_number -eq "3") {
$month_location = "mart"
} elseif ($month_number -eq "4") {
$month_location = "aprel"
} elseif ($month_number -eq "5") {
$month_location = "mai"
} elseif ($month_number -eq "6") {
$month_location = "juuni"
} elseif ($month_number -eq "7") {
$month_location = "juuli"
} elseif ($month_number -eq "8") {
$month_location = "august"
} elseif ($month_number -eq "9") {
$month_location = "september"
} elseif ($month_number -eq "10") {
$month_location = "oktoober"
} elseif ($month_number -eq "11") {
$month_location = "november"
} elseif ($month_number -eq "12") {
$month_location = "detsember"
} else {
break;
}

$folders = dir \\192.168.60.5\backup\$month_location

foreach ($folder in $folders) {
    $folder_location = "\\192.168.60.202\backup\$month_location\$folder"
    $files_count = (Get-ChildItem $folder_location -Recurse | Where-Object {!$_.PSIsContainer} | Measure-Object).Count
    $files = dir $folder_location 
    $failed_pc_name = "$folder"
    
    if ($files.Count -eq $Null) {
        '<tr bgcolor="#F2F2F2"><td>' + "$failed_pc_name</td><td>No files</td><td></td><td></td><td></td></tr>" | Out-File C:\temp.html -append
        $nofile_back += 1

    } else {
        $files = $files | where {$_.extension -eq ".txt"} | where {$_.Name -match "error"} | sort -property LastWriteTime -Descending |  Select-Object -first 1
        $file_name = $files.Name
        $link_name = "\\192.168.60.202\backup\$month_location\$folder\$file_name"
        
        if(!(test-path $link_name)) {
        } else {
        $real_date = $files.LastWriteTime.tostring("d.MM.yyyy")
        
        if ($real_date -match $check_date_month) {
            $read_log_file = gc \\192.168.60.202\backup\$month_location\$folder\$files | Select-String -Pattern "ERR "
            $count_log_files = (gc \\192.168.60.202\backup\$month_location\$folder\$files | Select-String -Pattern "ERR ").Count
            
            if ($count_log_files -eq $null) {
            '<tr bgcolor="#A9F5A9"><td>' + "$failed_pc_name</td><td>Backup success</td><td></td><td></td><td></td></tr>" | Out-File C:\temp.html -append
            $success_back += 1

            } else {   
            '<tr bgcolor="#F2F5A9"><td>' + "$failed_pc_name</td><td>Backup with errors</td><td><a href=" + "\\diskstation\backup\$month_location\$folder\$files" + ">$link_name</a></td><td>$count_log_files</td><td></td></tr>" | Out-File C:\temp.html -append
            $error_back += 1

            }
            
        } else {
            $find_failed = dir $link_name | sort -property LastWriteTime -Descending | Select-Object -first 1
            $find_failed_lastfile = $find_failed.LastWriteTime.tostring("d.MM.yyyy")
            '<tr bgcolor="#F78181"><td>' + "$failed_pc_name</td><td>Backup fail</td><td></td><td></td><td>$find_failed_lastfile</td></tr>" | Out-File C:\temp.html -append
            $fail_back += 1

            }
        }
    }
}



$failed_backups = $fail_back.length
$errors_backups = $error_back.length
$success_backups = $success_back.length
$nofiles_backups = $nofile_back.length
$total_backups = $fail_back.length + $error_back.length + $success_back.length + $nofile_back.length

$backup_date = Get-Date -format "d. MMMM yyyy HH:mm:ss" 
"</table" | Out-File C:\temp.html -append
"<p><b>Backup result</b></p>"  | Out-File C:\temp.html -append
"<p>DATE: $backup_date</p>"| Out-File C:\temp.html -append
"<p>Failed: $failed_backups</p>"| Out-File C:\temp.html -append
"<p>With errors: $errors_backups </p>"| Out-File C:\temp.html -append
"<p>Success: $success_backups </p>"| Out-File C:\temp.html -append
"<p>No files: $nofiles_backups </p>"| Out-File C:\temp.html -append
"<p>Total computers: $total_backups</p>"| Out-File C:\temp.html -append

function sendMail {
    
     $mail_date = Get-Date -format "d MMM yyyy"

     $smtpServer = "mail.neti.ee"
     $msg = new-object Net.Mail.MailMessage
     $msg.IsBodyHTML = $true
     $smtp = new-object Net.Mail.SmtpClient($smtpServer)
     
     $msg.From = "BACKUP_REPORT@log.ee"
     $msg.To.Add("it@log.ee")
     $msg.subject = "BACKUP REPORT $mail_date"

     $msg_content = gc C:\temp.html 
     $msg.body = gc C:\temp.html 

     $smtp.Send($msg)
  
}
sendMail