$folders = Get-ChildItem \\backup\august

foreach ($folder in $folders) {
    $foldername = "\\192.168.60.202\estelbackup\august\" + $folder.name
    $folder_name = $folder.name
    $colItems = (Get-ChildItem $foldername -Recurse | Measure-Object -property length -sum)
    $folder_size = "{0:N4}" -f ($colItems.sum / 1GB)
    
    $myObject = New-Object System.Object
    $myObject | Add-Member -type NoteProperty -name folder_name -Value "$folder_name"
    $myObject | Add-Member -type NoteProperty -name folder_size -Value "$folder_size"
    $myObject
}