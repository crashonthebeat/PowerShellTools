<#
    .SYNOPSIS
    Convert-RGBToAnsi Takes 3 ints representing an RGB value, and returns the 8-bit ANSI Color code.

    .PARAMETER ShowCalc
    Shows the full calculation steps to get the ANSI code, does not return a value.

    .PARAMETER RGB
    3 Integers from 0-255 representing Red, Green, and Blue in Order
#>
function Convert-RGBToAnsi {
    param (
        [switch]$ShowCalc,
        [Parameter(ValueFromRemainingArguments)]
        [int[]] $RGB
        )
    
    $dRGB = $RGB | Foreach-Object { 
        [Math]::Floor(($_ * 6) / 256) 
        if ([Math]::Floor(($_ * 6) / 256) -gt 5) {
            Write-Host "ERROR: Value out of Range!" -ForegroundColor Red
            return $null
        }
    }
    $val = 16 + (36 * $dRGB[0]) + (6 * $dRGB[1]) + $dRGB[2]

    if ($ShowCalc) {
        Write-Host ("     `e[4m6*x`e[24m       `e[41m {0,3} `e[0m       `e[42m {1,3} `e[0m    `e[44m {2,3} `e[0m" -f $RGB[0],$RGB[1],$RGB[2])
        Write-Host  "     256 =     `e[41m   $($dRGB[0]) `e[0m       `e[42m   $($dRGB[1]) `e[0m    `e[44m   $($dRGB[2]) `e[0m"
        Write-Host  "`e[3mval`e[0m = 16 + ( 36 * $($dRGB[0]) ) + ( 6 * $($dRGB[1]) ) +    $($dRGB[2])"
        Write-Host ("`e[3mval`e[0m = 16 +     `e[41m {0,3} `e[0m  +    `e[42m {1,3} `e[0m  + `e[44m   {2} `e[0m = `e[48;5;${val};30m $val `e[0m" -f (36 * $dRGB[0]),(6 * $dRGB[1]),$dRGB[2])
    }

    if (!$ShowCalc) { return $val }
}

Export-ModuleMember -Function Convert-RGBToAnsi

<#
    .SYNOPSIS
    Show-AnsiCodes shows all console ansi codes to manipulate text and the cursor location. No switches shows all.

    .PARAMETER Language
    Shows the exact ANSI escape codes for a particular language, defaults to Powershell

    .PARAMETER Deco
    Shows Text Decoration ANSI Codes

    .PARAMETER Cursor
    Shows cursor manipulation ANSI codes

    .PARAMETER Color8Bit
    Shows 8 Bit Color usage and Calculation

    .PARAMETER Color4Bit,FG4Bit,BG4Bit
    Shows 4 Bit Color ANSI Codes
#>
function Show-AnsiCodes {
    param(
        [switch]$Deco, [switch]$Cursor, [switch]$Color8Bit,
        [switch]$Color4Bit, [switch]$FG4Bit, [switch]$BG4Bit,
        [Parameter(ValueFromRemainingArguments)]
        [Alias("Lang")][string]$Language
    )

    $esc = switch ($Language.ToLower()) {
        {@('c#', '.net', 'csharp') -contains $_} {'\x1b'}
        Default                                  {'  `e'}                  
    }
    
    # Defines Text Decoration
    $deco_defs = [ordered]@{
        "0m"  = "All Off"
        "3m"  = "Italics   (Off $esc[23m)"
        "4m"  = "Underline (Off $esc[24m)"
        "5m"  = "Blink     (Off $esc[25m)"
        "53m" = "Overlined (Off $esc[55m)"
    }

    Clear-Host
    if ($Deco) {
        Write-Host "`e[92m============`e[37m TEXT  DECORATION `e[92m============`e[0m"
        $deco_defs.Keys | Foreach-Object {
            $str = "{0,-8} `e[${_}$($deco_defs[$_])`e[0m" -f "$esc[$_"
            Write-Host $str
        }
    }
    

    $cursor_defs = [ordered]@{
        "2K      " = "Clear Line"
        "<l>;<c>f" = "Move to line `e[3ml`e[23m and column `e[3mc`e[23m"
        "<n>A    " = "Move up `e[3mn`e[23m lines"
        "<n>B    " = "Move down `e[3mn`e[23m lines"
        "<n>C    " = "Move forward `e[3mn`e[23m columns"
        "<n>D    " = "Move back `e[3mn`e[23m columns"
        "2J      " = "Clear Screen, go to (0,0)"
        "K       " = "Clear Screen to end of line"
        "s       " = "Save Cursor Position"
        "u       " = "Restore Cursor Position"
    }

    if ($Cursor) {
        if ($Deco) { Write-Host "`e[6A`e[44C" -NoNewline }
        Write-Host "`e[92m==========`e[37m CURSOR  MANIPULATION `e[92m==========`e[0m"
        $cursor_defs.Keys | Foreach-Object {
            $str = ($all -or $Deco) ? "`e[44C" : ""
            $str += "{0,-8} $($cursor_defs[$_])`e[0m" -f "$esc[$_"
            Write-Host $str
        }
    }

    $colors_4bit = @("Black`e[0m  ", "Red`e[0m    ", "Green`e[0m  ", "Yellow`e[0m ", "Blue`e[0m   ", "Magenta`e[0m", "Cyan`e[0m   ", "White`e[0m  ")

    if ($Color4Bit) {$FG4Bit = $true; $BG4Bit = $true}
    if ($FG4Bit) {Write-Host "`e[92m=============`e[37m 4-BIT FG COLOR `e[92m=============`e[0m  " -NoNewline}
    if ($BG4Bit) {Write-Host "`e[92m=============`e[37m 4-BIT BG COLOR `e[92m=============`e[0m"}
    else         {Write-Host "`n" -NoNewline}
    for ($i = 0; $i -lt 8; $i++) {
        $fgclr = ($colors_4bit[$i] -eq "Black`e[0m  ") ? "`e[47mBlack`e[0m  " : $colors_4bit[$i]
        $bgclr = ($colors_4bit[$i] -eq "White`e[0m  ") ? "`e[30mWhite`e[0m  " : $colors_4bit[$i]
        $fgstr = ($FG4Bit) ? "$esc[3${i}m `e[3${i}m$fgclr`e[0m  $esc[9${i}m `e[9${i}mBright $($colors_4bit[$i])`e[0m   " : ""
        $bgstr = ($BG4Bit) ? "$esc[4${i}m `e[4${i}m$bgclr`e[0m  $esc[10${i}m `e[10${i}m`e[30mBright $($colors_4bit[$i])`e[0m" : ""
        Write-Host "$fgstr$bgstr" -NoNewline
        if ($FG4Bit -or $BG4Bit) {Write-Host "`n" -NoNewline}
    }
    if ($FG4Bit) {Write-Host "$esc[39m Reset FG Color`e[21C" -NoNewline}
    if ($BG4Bit) {Write-Host "$esc[49m Reset BG Color"}
    #else         {Write-Host "`n" -NoNewline}


    if ($Color8Bit) {
        Write-Host "`e[92m====================================`e[37m 8-BIT COLORS `e[92m====================================`e[0m"
        Write-Host "1. Find the R, G, B Value of the color"
        if ($csharp) {Write-Host "2. Do 'RGB = Math.Floor((`e[3m[RGB]`e[0m*6)/256)"}
        else         {Write-Host "2. Do 'RGB = [Math]::Floor((`e[3m[RGB]`e[0m*6)/256)"}
        Write-Host "3. Calculate `e[3mval`e[0m = 16 + 36`e[3mr`e[0m + 6`e[3mg`e[0m + `e[3mb`e[0m"
        Write-Host "`e[3A`e[44CFG Escape code is $esc[38;5;`e[3mval`e[0m"
        Write-Host "`e[44CBG Escape code is $esc[48;5;`e[3mval`e[0m`n`n"
        Write-Host ("Ex: RGB 255,127,0 (Orange) > 'RGB 5,2,0 > ANSI 208 > `e[38;5;208m{0}`e[0m `e[48;5;208;30m{1}`e[0m" -f "$esc[38;5;208m","$esc[48;5;208m")
    }
}

Export-ModuleMember -Function Show-AnsiCodes
