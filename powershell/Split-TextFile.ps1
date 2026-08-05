#作成者：胡
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$InputFile,

    [Parameter(Position = 1)]
    [ValidateRange(1, 1000000000)]
    [int]$LinesPerFile = 5,

    [Parameter(Position = 2)]
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

$inputPath = (Resolve-Path -LiteralPath $InputFile).Path
$inputInfo = Get-Item -LiteralPath $inputPath

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $inputInfo.DirectoryName ($inputInfo.BaseName + '_split')
}

$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($outputPath) | Out-Null

# First pass: count all lines without loading the file into memory.
$lineCount = 0L
$reader = [System.IO.StreamReader]::new($inputPath, $true)
try {
    while ($null -ne $reader.ReadLine()) {
        $lineCount++
    }
}
finally {
    $reader.Dispose()
}

$numberOfFiles = [long][Math]::Ceiling($lineCount / $LinesPerFile)
$digits = [Math]::Max(2, $numberOfFiles.ToString().Length)
$extension = $inputInfo.Extension

# Write output as UTF-8 without BOM.
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$reader = [System.IO.StreamReader]::new($inputPath, $true)

try {
    for ($fileNumber = 1; $fileNumber -le $numberOfFiles; $fileNumber++) {
        $partName = '{0}_part{1}{2}' -f $inputInfo.BaseName, $fileNumber.ToString("D$digits"), $extension
        $partPath = Join-Path $outputPath $partName
        $writer = [System.IO.StreamWriter]::new($partPath, $false, $utf8NoBom)
        $writtenLines = 0L

        try {
            for ($lineNumber = 0L; $lineNumber -lt $LinesPerFile; $lineNumber++) {
                $line = $reader.ReadLine()
                if ($null -eq $line) {
                    break
                }
                $writer.WriteLine($line)
                $writtenLines++
            }
        }
        finally {
            $writer.Dispose()
        }

        Write-Host ("Created: {0} ({1} lines)" -f $partPath, $writtenLines)
    }
}
finally {
    $reader.Dispose()
}

Write-Host ("Done: split {0} lines into {1} files ({2} lines maximum per file)." -f $lineCount, $numberOfFiles, $LinesPerFile)
#作成者：胡