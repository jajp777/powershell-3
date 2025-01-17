$startDTM = (Get-Date)

Clear-Host
$wc=New-Object net.webclient 
$wc.downloadstring("http://www.molten-wow.com") | Out-File c:\temp.txt 
$Contents = [io.file]::ReadAllText('c:\temp.txt')                                                         
$Index = $Contents.IndexOf('<span style="padding-left:4px;">')                                                                           
$new = $Contents.Substring($index)
$d = (($new | foreach{$_.tostring().split("<")}) -replace ('span style="padding-left:4px;">', "") -replace ('/span>', "")`
-replace ('div class="counter" style="width:118px;text-align:center;">', '') -replace ('div class="players">', '') -replace ('div id="ri6" class="realmInfo" style="display:none;">', '') -replace ('div class="infoR">', '')`
-replace ('span>', '') -replace ('span class="infoL">', '') -replace ('/div>', '') -replace ('br />', '')`
-replace ('div class="sep">', '') -replace ('div class="realmBg" id="rb4" style="z-index:9999999;">', '') -replace ('p>', '') -replace ('/', '')`
-replace (' ', '') -replace ('playersonline', '') -replace ('Uptime:', '') -replace ('p>', '')`
-replace ('Rates:', '') -replace ('imgsrc="resourcemoltenimagesmainmw_swrath.png"border="0">', '') -replace ('divid="ri4"class="realmInfo"style="display:none;">', '') -replace ('divclass="realmBg"id="rb1"style="z-index:9999999;">', '')`
-replace ('divid="ri1"class="realmInfo"style="display:none;">', '') -replace ('divclass="realmBg"id="rb2"style="z-index:9999999;">', '') -replace ('divid="ri3"class="realmInfo"style="display:none;">', '') -replace ('divclass="realmBg"id="rb7"style="z-index:9999999;">', '')`
-replace ('divid="ri2"class="realmInfo"style="display:none;">', '') -replace ('divclass="realmBg"id="rb3"style="z-index:9999999;">', '') -replace ('imgsrc="resourcemoltenimagesmainmw_scata.png"border="0">', '') -replace ('divid="ri5"class="realmInfo"style="display:none;">', '')`
-replace ('divid="ri7"class="realmInfo"style="display:none;">', '') -replace ('divclass="realmBg"id="rb5"style="z-index:9999999;">', '') -replace ('divclass="realmBg"id="rb9"style="z-index:9999999;">', '') -replace ('divid="ri9"class="realmInfo"style="display:none;">', '')`
-replace ('divclass="realmBg"id="rb8"style="z-index:9999999;">', '') -replace ('divid="ri8"class="realmInfo"style="display:none;">', '') -replace ('divclass="bottom">', '') `
-replace ('scripttype="textjavascript">', '') | where {$_ -ne ""})
#$d
"LORDAERON: "
"Online: " + $d[1]
"Uptime: " + $d[2]
"Rates:  " + $d[3]
"-----------------"
"FROSTWOLF"
"Online: " + $d[5]
"Uptime: " + $d[6]
"Rates:  " + $d[7]
"-----------------"
"NELTHARION"
"Online: " + $d[9]
"Uptime: " + $d[10]
"Rates:  " + $d[11]
"-----------------"
"DEATHWING"
"Online: " + $d[13]
"Uptime: " + $d[14]
"Rates:  " + $d[15]
"-----------------"
"SARGERAS"
"Online: " + $d[17]
"Uptime: " + $d[18]
"Rates:  " + $d[19]
"-----------------"
"RAGNAROS"
"Online: " + $d[21]
"Uptime: " + $d[22]
"Rates:  " + $d[23]
"-----------------"
"WARSONG"
"Online: " + $d[25]
"Uptime: " + $d[26]
"Rates:  " + $d[27]

# Get End Time
$endDTM = (Get-Date)
 
# Echo Time elapsed
"Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"