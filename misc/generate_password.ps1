function Get-RandomPassword {
	param
        (
		$length = 1,
		$char1 = 'ABCDEFGHKLMNPRSTUVWXYZASASJKDHASKHDJASKLHDKJASHDKJASDAXXXFASDFRTYU',
        $char2 = 'abcdefghkmnprstuvwxyzqasdasdakmklmwedasasasdasdqwezxvbnmnbvckjhgfs',
        $char3 = '123456789012345678902312314567456782312412512512511234567809876543',
        $char4 = 'ABCDEFGHKLMNPRASKDLJSALKDNASKLNMMNZXQWKRQWJRPOASDASPDQJZZASTASRARX',
        $char5 = 'abcdefghkmnprstuvwxyzYYasdaaskjdmklasnmdlaDASdosqrqwasdfghsdfghjkk',
        $char6 = '123456789012312313456789024567833456789012345672345678999998764567'
	    )
	$randomchar1 = 1..$length | ForEach-Object { Get-Random -Maximum $char1.length }
    $randomchar2 = 1..$length | ForEach-Object { Get-Random -Maximum $char2.length }
    $randomchar3 = 1..$length | ForEach-Object { Get-Random -Maximum $char3.length }
    $randomchar4 = 1..$length | ForEach-Object { Get-Random -Maximum $char4.length }
    $randomchar5 = 1..$length | ForEach-Object { Get-Random -Maximum $char5.length }
    $randomchar6 = 1..$length | ForEach-Object { Get-Random -Maximum $char6.length }
	$Finalkey = [String]$char1[$randomchar1] + [String]$char2[$randomchar2] + [String]$char3[$randomchar3] + 
    [String]$char4[$randomchar4] + [String]$char5[$randomchar5] + [String]$char6[$randomchar6]
    #$password
    $alpha = [char[]]($Finalkey)
    $ofs = ''
    $newpw = [string]( $alpha | Get-Random -Count 6 )
    $newpw#+ $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw + $newpw
} 

#newline lol
$i = 1
do {
Get-RandomPassword  
$i++
}
while ($i -le 75)
#((gwmi win32_Computersystem).UserName).split("\")[1]