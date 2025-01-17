cls
#Set-ExecutionPolicy -scope CurrentUser -Executionpolicy bypass -force
$path = "\\ubuntu64\sys$\contactEstel.utf8.csv"

$read_csv = gc $path|% {$_.split(";")}
$full_name = gc $path|% {$_.split(";")[0]}
$job_title = gc $path|% {$_.split(";")[1]}
$company = gc $path|% {$_.split(";")[2]}
$file_as = gc $path|% {$_.split(";")[3]}
$country_region = gc $path|% {$_.split(";")[4]}
$department = gc $path|% {$_.split(";")[5]}
$business_phone = gc $path|% {$_.split(";")[6]}
$business_fax  = gc $path|% {$_.split(";")[7]}
$home_phone  = gc $path|% {$_.split(";")[8]}
$mobile_phone  = gc $path|% {$_.split(";")[9]}
$e_mail = gc $path|% {$_.split(";")[10]}
$categories  = gc $path|% {$_.split(";")[11]}
$csv_len = (Import-Csv $path).Count

$oOutlook    = New-Object -ComObject Outlook.Application
$oNameSpace  = $oOutlook.GetNamespace("MAPI")
$oMAPIFolder = $oNameSpace.Session.GetDefaultFolder(10)
$find_estel = ($oMAPIFolder.Folders) | %{$_.Name -eq "Estel Contacts"}   
$Contacts = $oOutlook.session.getDefaultFolder(10) 
$estel_folder = $Contacts.Folders.Item("Estel Contacts")
$deletedItems = $oNameSpace.Session.GetDefaultFolder(3) # == olFolderDeletedItems

function DeleteItems {
    foreach ($x in $estel_folder.items) {
    $item_count = ($estel_folder.items).count
    if ($item_count -eq 0) {
    break
    break
    } else {
    
    "deleting...$item_count"
    $x.Delete()
            }
        }
}
$i = 1
do {
DeleteItems 
$i++
}
while ($i -le 100)
#==============================================================================
function EmptyJunk {
$deleted_count = ($deletedItems.Items | Where-Object {$_.Class -eq "40"}).Count
if ($deleted_count -eq 0 -or $deleted_count -eq $Null) {
    "No contact items left $deleted_count"
    break
} else {
    "Found contacts $deleted_count"
    foreach ($x in $deletedItems.Items) {
        #$x.LastModificationTime
        if ($x.Class -eq 40) {
            "Deleting contact $deleted_count"
            $x.Delete()
        } else {
            "This is not contact"
        }
    
      }  
   }
}
$i = 1
do {
EmptyJunk
$i++
}
while ($i -le 500)
#==============================================================================
if ($find_estel -eq "True") {
   "Estel contacts exists"
  
    for ($i=1; $i -le $csv_len; $i++) {
    "Adding contact $i"
    $newcontact = $estel_folder.Items.Add()
    $newcontact.FullName = $full_name[$i]
    $newcontact.JobTitle = $job_title[$i]
    $newcontact.CompanyName = $company[$i]
    $newcontact.BusinessTelephoneNumber = $business_phone[$i]
    $newcontact.BusinessFaxNumber = $business_fax[$i]
    $newcontact.MobileTelephoneNumber = $mobile_phone[$i]
    $newcontact.Email1Address = $e_mail[$i]
    $newcontact.Save()
    }
    
    
} else {
    $oMyMAPIFolder = $oMAPIFolder.Folders.Add("Estel contacts")
    $oMyMAPIFolder.ShowAsOutlookAB = "True"
    
    for ($i=1; $i -le $csv_len; $i++) {
    $newcontact = $oMyMAPIFolder.Items.Add()
    $newcontact.FullName = $full_name[$i]
    $newcontact.JobTitle = $job_title[$i]
    $newcontact.CompanyName = $company[$i]
    $newcontact.BusinessTelephoneNumber = $business_phone[$i]
    $newcontact.BusinessFaxNumber = $business_fax[$i]
    $newcontact.MobileTelephoneNumber = $mobile_phone[$i]
    $newcontact.Email1Address = $e_mail[$i]
    $newcontact.Save()
    }
}



