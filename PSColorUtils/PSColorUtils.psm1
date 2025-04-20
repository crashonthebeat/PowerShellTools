using namespace System.Management.Automation.Host

function Write-Color {
    param(
        [string]$Text,
        [Alias("n")][switch]$NoNewLine
    )
}

Export-ModuleMember Write-Color

<#
    .SYNOPSIS
    Read-Console is a function that allows to set the exact prompt, where the prompt starts, the max length of the input, etc.

    .PARAMETER Prompt
    The text displayed before the input. Note: This command does not automatically input any characters between the prompt entered and the input area.

    .PARAMETER DefText
    The text already put in the input area.

    .PARAMETER PromptColorStr
    The ANSI Color String that defines the colors of the prompt

    .PARAMETER InputColorStr
    The ANSI Color String that defines the colors of the input

    .PARAMETER Row
    The Line at which the prompt/input should start

    .PARAMETER Col
    The column at which the prompt/input should start
    
    .PARAMETER InputWidth
    The max width of the input, defaults to console input

    .PARAMETER Multiline
    NOT IMPLEMENTED: Allows multiline input

    .PARAMETER NoWrapInput
    NOT IMPLEMENTED: Disallows text wrapping

    .PARAMETER InlinePrompt
    NOT IMPLEMENTED: Sets multiline input below the prompt to start at the same col as the prompt start.
#>
function Read-Console {
    param(
        [string]$Prompt,
        [string]$DefText = "",
        [Alias("PrClr")]       [string]$PromptColorStr = "",
        [Alias("InClr")]       [string]$InputColorStr = "",
        [Alias("L","Line","R")][int]$Row = $Host.UI.RawUI.CursorPosition.Y,
        [Alias("C","Column")]  [int]$Col = $Host.UI.RawUI.CursorPosition.X,
        [Alias("Width")]       [int]$InputWidth = 0,
        [Alias("Multi")]       [switch]$Multiline,
        [Alias("NoWrap")]      [switch]$NoWrapInput
    )

    if (!$InputWidth) { $InputWidth = $Host.UI.RawUI.WindowSize.Width - $Prompt.Length - $Col }
    
    $InputStr = $DefText
    $x = $DefText.Length
    
    while($true) {
        $i = $Col + $Prompt.Length + 1 + $x

        # TODO: Handle Long input lengths and also highlighting better
        
        if ($x -gt $InputWidth -and $InputStr.Length -gt $InputWidth) {
            $Buffer = "…" + $InputStr.Substring($x - $InputWidth - 1, $InputWidth - 1) + "…"
        }
        elseif ($InputStr.Length -gt $InputWidth) {
            $Buffer = $InputStr.Substring(0,$InputWidth - 1) + "…"
        }


        if ($null -ne $h -and $h -lt $x) {
            $Buffer = $Buffer.Insert($x, "`e[27m")
            $Buffer = $Buffer.Insert($h, "`e[7m")
        }
        elseif ($null -ne $h -and $x -lt $h) {
            $Buffer = $Buffer.Insert($h, "`e[27m")
            $Buffer = $Buffer.Insert($x, "`e[7m")
        }
        

        Write-Host "`e[${Row};${Col}f`e[2K${PromptColorStr}${Prompt}${InputColorStr}${Buffer}`e[${Row};${i}f" -NoNewline
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,AllowCtrlC")
        $ctrl = $key.ControlKeyState.ToString() -like "*CtrlPressed*"
        $shift = $key.ControlKeyState.ToString() -like "*ShiftPressed*"
        
        if ($key.VirtualKeyCode -eq 90 -and $ctrl) { $InputStr = $prev; $x = 0; continue }
        else { $prev = $InputStr }
        switch ($key.VirtualKeyCode) {
            # BACKSPACE - Remove character before index
            8 { if ($x -gt 0) { $InputStr = $InputStr.Remove($x - 1, 1); $x-- } }
            # ENTER/RETURN - Return current buffer
            13 { Write-Host "`n" -NoNewline; return $InputStr }
            # SHIFT
            16 { if (!$h) { $h = $x }; continue}
            # CTRL/ALT
            { $_ -in @(17,18) } { continue }
            # ESCAPE - Return default text/nothing
            27 { Write-Host "`n" -NoNewline; return "" }
            # SPACE - Add blank space at current index
            32 { $InputStr = $InputStr.Insert($x,$key.Character)}
            # END
            35 { $x = $InputStr.Length }
            # HOME
            36 { $x = 0 }
            # LEFT
            37 { $x -= ($x -gt 0) ? 1 : 0 }
            # RIGHT
            39 { $x += ($x -lt $InputStr.Length) ? 1 : 0 }
            # DELETE
            46 { 
                if ($null -ne $h -and $h -lt $x) { $InputStr = $InputStr.Remove($h, $x-$h); $x = $h }
                elseif ($null -ne $h -and $x -lt $h) { $InputStr = $InputStr.Remove($x, $h-$x) }
                elseif ($x -lt $InputStr.Length) { $InputStr = $InputStr.Remove($x, 1) } 
            }
            # C -- COPY
            {$_ -eq 67 -and $ctrl} { 
                Set-Clipboard -Value (($h -lt $x) ? $InputStr[$h..$x] -join '' : $InputStr[$x..$h] -join '')
            }
            # H -- HELP
            {$_ -eq 72 -and $ctrl} { continue }
            # V -- PASTE
            {$_ -eq 86 -and $ctrl} {
                $ins = (Get-Clipboard)
                $InputStr = $InputStr.Insert($x,$ins)
                $x += $ins.Length
            }
            # X -- CUT
            {$_ -eq 88 -and $ctrl} { 
                Set-Clipboard -Value (($h -lt $x) ? $InputStr[$h..$x] -join '' : $InputStr[$x..$h] -join '')
                if ($null -ne $h -and $h -lt $x)     { $InputStr = $InputStr.Remove($h, $x-$h); $x = $h }
                elseif ($null -ne $h -and $x -lt $h) { $InputStr = $InputStr.Remove($x, $h-$x) }
                $h = $null
            }
            default { $InputStr = $InputStr.Insert($x,$key.Character) }
        }
        if (($key.VirtualKeyCode -in 65..90 -or $key.VirtualKeyCode -eq 32) -and !$ctrl) { $x++ }
        if (!$shift -and !$ctrl) { $h = $null }
    }
}

Export-ModuleMember Read-Color
