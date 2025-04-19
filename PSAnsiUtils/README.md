# PSAnsiUtils

## Convert-RGBToAnsi

### Synopsis

Convert-RGBToAnsi Takes 3 ints representing an RGB value, and returns the 8-bit ANSI Color code.

### Parameters

| Parameter       | Description                                                                     |
| --------------- | ------------------------------------------------------------------------------- |
| switch ShowCalc | Shows the full calculation steps to get the ANSI code, does not return a value. |
| int[] RGB       | 3 Integers from 0-255 representing Red, Green, and Blue in order.               |

## Show-AnsiCodes

### Synopsis

Show-AnsiCodes shows all console ansi codes to manipulate text and the cursor location. No switches shows all.

### Parameters

| Parameter        | Description                                                                          |
| ---------------- | ------------------------------------------------------------------------------------ |
| string Language  | Shows the exact ANSI escape codes for a particular language, defaults to Powershell. |
| switch Deco      | Shows Text Decoration ANSI Codes                                                     |
| switch Cursor    | Shows cursor manipulation ANSI codes                                                 |
| switch Color8Bit | Shows 8 Bit Color usage and Calculation                                              |
| switch Color4Bit | Shows 4 Bit Color ANSI Codes (FG4Bit shows Foreground,BG4Bit shows background)       |
