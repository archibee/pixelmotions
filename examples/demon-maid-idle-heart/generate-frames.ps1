param(
  [string]$AssetRoot = (Join-Path (Join-Path $PSScriptRoot '..\..\..') 'private-image-assets-saver')
)

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path $AssetRoot 'originals/source-images/demon-maid-sd-pixel-source.png'
$framesPath = Join-Path $AssetRoot 'subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v1/frames'
New-Item -ItemType Directory -Force -Path $framesPath | Out-Null
$source = [System.Drawing.Bitmap]::FromFile($sourcePath)
$canvasWidth = 1152
$canvasHeight = 1280
$cell = 5
$bubbleWidth = 64 * $cell
$bubbleHeight = 28 * $cell
$bubbleX = 820
$bubbleY = 210
$characterWidth = 900
$characterHeight = [int][Math]::Round($source.Height * ($characterWidth / $source.Width))

function New-ColorBrush([string]$hex) {
  return [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function Draw-Cell($graphics, $brush, [int]$x, [int]$y, [int]$size = 1) {
  $graphics.FillRectangle($brush, $x * $cell, $y * $cell, $size * $cell, $size * $cell)
}

function New-BubbleBitmap {
  $bitmap = [System.Drawing.Bitmap]::new($bubbleWidth, $bubbleHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
  $outline = New-ColorBrush '#3A2632'
  $shadow = New-ColorBrush '#F4A8B8'
  $fill = New-ColorBrush '#FFF5ED'
  $pink = New-ColorBrush '#FFCAD2'
  $ink = New-ColorBrush '#593744'
  $white = New-ColorBrush '#FFFFFF'

  # Pixelated shadow and rounded rectangular speech bubble.
  for ($y = 3; $y -le 22; $y++) {
    for ($x = 4; $x -le 60; $x++) {
      $inside = $true
      if (($x -lt 8 -or $x -gt 56) -and ($y -lt 7 -or $y -gt 18)) { $inside = $false }
      if ($inside) { Draw-Cell $graphics $shadow ($x + 1) ($y + 1) }
    }
  }
  for ($y = 2; $y -le 21; $y++) {
    for ($x = 3; $x -le 59; $x++) {
      $inside = $true
      if (($x -lt 7 -or $x -gt 55) -and ($y -lt 6 -or $y -gt 17)) { $inside = $false }
      if (-not $inside) { continue }
      $edge = $false
      foreach ($delta in @(@(0,-1),@(1,0),(0,1),(-1,0))) {
        $nx = $x + $delta[0]; $ny = $y + $delta[1]
        $neighborInside = ($nx -ge 3 -and $nx -le 59 -and $ny -ge 2 -and $ny -le 21)
        if (($nx -lt 7 -or $nx -gt 55) -and ($ny -lt 6 -or $ny -gt 17)) { $neighborInside = $false }
        if (-not $neighborInside) { $edge = $true }
      }
      Draw-Cell $graphics $(if ($edge) { $outline } else { $fill }) $x $y
    }
  }
  # Left-facing tail, layered behind the bubble.
  foreach ($point in @(@(8,20),@(9,21),@(10,22),@(11,23),@(12,22),@(13,21))) { Draw-Cell $graphics $outline $point[0] $point[1] }
  foreach ($point in @(@(9,20),@(10,21),@(11,22),@(12,21))) { Draw-Cell $graphics $fill $point[0] $point[1] }

  # Tiny 5x7 pixel font for a short greeting.
  $glyphs = @{
    H = @('10001','10001','10001','11111','10001','10001','10001')
    i = @('00100','00000','01100','00100','00100','00100','01110')
    exclamation = @('00100','00100','00100','00100','00100','00000','00100')
  }
  $cursor = 10
  foreach ($letter in @('H','i','exclamation')) {
    for ($gy = 0; $gy -lt 7; $gy++) {
      for ($gx = 0; $gx -lt 5; $gx++) {
        if ($glyphs[$letter][$gy][$gx] -eq '1') { Draw-Cell $graphics $ink ($cursor + $gx) (8 + $gy) 2 }
      }
    }
    $cursor += 11
  }
  # A few pixel highlights keep the message bubble soft and readable.
  Draw-Cell $graphics $pink 52 5 2
  Draw-Cell $graphics $white 15 5

  $outline.Dispose(); $shadow.Dispose(); $fill.Dispose(); $pink.Dispose(); $ink.Dispose(); $white.Dispose()
  $graphics.Dispose()
  return $bitmap
}

function New-HeartBitmap {
  $bitmap = [System.Drawing.Bitmap]::new(14 * $cell, 11 * $cell, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
  $outline = New-ColorBrush '#B63E5B'
  $red = New-ColorBrush '#FF6688'
  $light = New-ColorBrush '#FFB5C2'
  $white = New-ColorBrush '#FFF8F4'
  $pattern = @(
    '00111100111100',
    '01111111111110',
    '11111111111111',
    '11111111111111',
    '01111111111110',
    '00111111111100',
    '00011111111000',
    '00001111110000',
    '00000111100000',
    '00000011000000',
    '00000000000000'
  )
  for ($y = 0; $y -lt $pattern.Count - 1; $y++) {
    for ($x = 0; $x -lt $pattern[$y].Length; $x++) {
      if ($pattern[$y][$x] -ne '1') { continue }
      $edge = ($x -eq 0 -or $x -eq 13 -or $y -eq 0 -or $pattern[$y - 1][$x] -eq '0' -or $pattern[$y + 1][$x] -eq '0')
      if ($edge) { Draw-Cell $graphics $outline $x $y } else { Draw-Cell $graphics $red $x $y }
    }
  }
  Draw-Cell $graphics $light 3 2 2
  Draw-Cell $graphics $white 4 2
  $outline.Dispose(); $red.Dispose(); $light.Dispose(); $white.Dispose()
  $graphics.Dispose()
  return $bitmap
}

function Draw-ScaledNearest($graphics, $image, [int]$x, [int]$y, [double]$scale) {
  $width = [Math]::Max(1, [int][Math]::Round($image.Width * $scale))
  $height = [Math]::Max(1, [int][Math]::Round($image.Height * $scale))
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $graphics.DrawImage($image, [System.Drawing.Rectangle]::new($x, $y, $width, $height))
  return @($width, $height)
}

$bubble = New-BubbleBitmap
$heart = New-HeartBitmap
$frameCount = 16
$bobY = @(0,2,4,2,0,2,4,2)
$bobX = @(0,0,1,1,0,0,-1,-1)
$bubbleScales = @(0,0,0,0,0,0.48,0.78,1,1,1,0.78,0.45,0,0,0,0)
$heartScales = @(0,0,0,0,0,0,0.55,0.95,0.82,1.05,0.72,0.25,0,0,0,0)

try {
  for ($i = 0; $i -lt $frameCount; $i++) {
    $frame = [System.Drawing.Bitmap]::new($canvasWidth, $canvasHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($frame)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $characterX = 24 + $bobX[$i % 8]
    $characterY = 75 + $bobY[$i % 8]
    $graphics.DrawImage($source, [System.Drawing.Rectangle]::new($characterX, $characterY, $characterWidth, $characterHeight))

    $bubbleScale = $bubbleScales[$i]
    if ($bubbleScale -gt 0) {
      $bubbleLeft = $bubbleX + $bubbleWidth - [int][Math]::Round($bubbleWidth * $bubbleScale)
      $bubbleTop = $bubbleY + $bubbleHeight - [int][Math]::Round($bubbleHeight * $bubbleScale)
      Draw-ScaledNearest $graphics $bubble $bubbleLeft $bubbleTop $bubbleScale | Out-Null
      $heartScale = $heartScales[$i]
      if ($heartScale -gt 0) {
        $heartX = $bubbleLeft + [int][Math]::Round(230 * $bubbleScale)
        $heartY = $bubbleTop + [int][Math]::Round(8 * $bubbleScale)
        Draw-ScaledNearest $graphics $heart $heartX $heartY ($heartScale * $bubbleScale) | Out-Null
      }
    }
    $graphics.Dispose()
    $frame.Save((Join-Path $framesPath ('frame-{0:D2}.png' -f ($i + 1))), [System.Drawing.Imaging.ImageFormat]::Png)
    $frame.Dispose()
  }
}
finally {
  $source.Dispose()
  $bubble.Dispose()
  $heart.Dispose()
}

Write-Output "Created $frameCount transparent PNG frames ($canvasWidth x $canvasHeight) in $framesPath"
