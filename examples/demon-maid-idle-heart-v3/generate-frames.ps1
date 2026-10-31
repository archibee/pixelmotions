param(
  [string]$AssetRoot = (Join-Path (Join-Path $PSScriptRoot '..\..\..') 'private-image-assets-saver')
)

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path $AssetRoot 'originals/source-images/demon-maid-sd-pixel-source.png'
$framesPath = Join-Path $AssetRoot 'subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v3/frames'
New-Item -ItemType Directory -Force -Path $framesPath | Out-Null
$source = [System.Drawing.Bitmap]::FromFile($sourcePath)
$canvasWidth = 1152
$canvasHeight = 1280
$characterWidth = 900
$characterHeight = [int][Math]::Round($source.Height * ($characterWidth / $source.Width))

function New-ColorBrush([string]$hex) {
  return [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function New-PinkHeart {
  $cell = 5
  $pattern = @(
    '0011110000111100',
    '0111111001111110',
    '1111111111111111',
    '1111111111111111',
    '1111111111111111',
    '1111111111111111',
    '0111111111111110',
    '0011111111111100',
    '0001111111111000',
    '0000111111110000',
    '0000011111100000',
    '0000001111000000',
    '0000000110000000',
    '0000000000000000'
  )
  $bitmap = [System.Drawing.Bitmap]::new(16 * $cell, 14 * $cell, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
  $outline = New-ColorBrush '#A83257'
  $pink = New-ColorBrush '#F45D80'
  $light = New-ColorBrush '#FF9DB3'
  $shine = New-ColorBrush '#FFF6F4'

  for ($y = 0; $y -lt $pattern.Count - 1; $y++) {
    for ($x = 0; $x -lt $pattern[$y].Length; $x++) {
      if ($pattern[$y][$x] -ne '1') { continue }
      $edge = $pattern[[Math]::Max(0, $y - 1)][$x] -eq '0' -or
              $pattern[[Math]::Min($pattern.Count - 1, $y + 1)][$x] -eq '0' -or
              $x -eq 0 -or $pattern[$y][[Math]::Max(0, $x - 1)] -eq '0' -or
              $x -eq ($pattern[$y].Length - 1) -or $pattern[$y][[Math]::Min($pattern[$y].Length - 1, $x + 1)] -eq '0'
      $brush = if ($edge) { $outline } elseif ($y -lt 5 -or $x -lt 7) { $light } else { $pink }
      $graphics.FillRectangle($brush, $x * $cell, $y * $cell, $cell, $cell)
    }
  }

  # Two crisp highlight pixels keep the heart readable at native sprite size.
  $graphics.FillRectangle($shine, 15, 10, 10, 5)
  $graphics.FillRectangle($shine, 20, 15, 5, 5)
  $outline.Dispose(); $pink.Dispose(); $light.Dispose(); $shine.Dispose()
  $graphics.Dispose()
  return $bitmap
}

function Draw-Nearest($graphics, $image, [double]$centerX, [double]$centerY, [double]$scale) {
  $width = [Math]::Max(1, [int][Math]::Round($image.Width * $scale))
  $height = [Math]::Max(1, [int][Math]::Round($image.Height * $scale))
  $x = [int][Math]::Round($centerX - $width / 2)
  $y = [int][Math]::Round($centerY - $height / 2)
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $graphics.DrawImage($image, [System.Drawing.Rectangle]::new($x, $y, $width, $height))
}

$heart = New-PinkHeart
$bobY = @(0,2,4,2,0,2,4,2)
$bobX = @(0,0,1,1,0,0,-1,-1)
$mainScale = @(0,0,0,0,0.22,0.48,0.78,1,1.08,1,0.82,0.62,0.4,0.22,0,0)
$mainY = @(855,855,850,845,835,820,800,780,765,760,765,778,793,810,830,850)
$leftScale = @(0,0,0,0,0,0,0.22,0.38,0.3,0.16,0,0,0,0,0,0)
$rightScale = @(0,0,0,0,0,0,0,0,0.18,0.35,0.28,0.15,0,0,0,0)

try {
  for ($i = 0; $i -lt 16; $i++) {
    $frame = [System.Drawing.Bitmap]::new($canvasWidth, $canvasHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($frame)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

    $phase = $i % 8
    $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(24 + $bobX[$phase], 75 + $bobY[$phase], $characterWidth, $characterHeight))

    $mainX = 484 + [Math]::Sin($i * 0.7) * 3
    $mainCenterY = $mainY[$i]

    # Small satellite hearts puff up after the main heart, then quickly fade by shrinking away.
    if ($leftScale[$i] -gt 0) {
      $leftX = $mainX - 43 - [Math]::Max(0, $i - 6) * 3
      $leftY = $mainCenterY + 14 - [Math]::Max(0, $i - 6) * 11
      Draw-Nearest $graphics $heart $leftX $leftY $leftScale[$i]
    }
    if ($rightScale[$i] -gt 0) {
      $rightX = $mainX + 43 + [Math]::Max(0, $i - 8) * 3
      $rightY = $mainCenterY + 13 - [Math]::Max(0, $i - 8) * 12
      Draw-Nearest $graphics $heart $rightX $rightY $rightScale[$i]
    }
    if ($mainScale[$i] -gt 0) {
      Draw-Nearest $graphics $heart $mainX $mainCenterY $mainScale[$i]
    }

    $graphics.Dispose()
    $frame.Save((Join-Path $framesPath ('frame-{0:D2}.png' -f ($i + 1))), [System.Drawing.Imaging.ImageFormat]::Png)
    $frame.Dispose()
  }
}
finally {
  $source.Dispose()
  $heart.Dispose()
}

Write-Output "Created 16 transparent PNG frames ($canvasWidth x $canvasHeight) in $framesPath"
