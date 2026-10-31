param(
  [string]$AssetRoot = (Join-Path (Join-Path $PSScriptRoot '..\..\..') 'private-image-assets-saver')
)

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path $AssetRoot 'originals/source-images/demon-maid-sd-pixel-source.png'
$framesPath = Join-Path $AssetRoot 'subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v2/frames'
New-Item -ItemType Directory -Force -Path $framesPath | Out-Null
$source = [System.Drawing.Bitmap]::FromFile($sourcePath)

# These dimensions keep 16 frames below Pixel Motion Studio's aggregate pixel limit.
$canvasWidth = 1152
$canvasHeight = 1280
$characterWidth = 900
$characterHeight = [int][Math]::Round($source.Height * ($characterWidth / $source.Width))
$cell = 4
$bubbleBodyCellsWide = 80
$bubbleBodyCellsHigh = 38
$bubbleCellsHigh = 52
$bubbleWidth = $bubbleBodyCellsWide * $cell
$bubbleHeight = $bubbleCellsHigh * $cell
$bubbleAnchorX = 650
$bubbleAnchorY = 520
$tailTipCellX = 6
$tailTipCellY = 52

function New-ColorBrush([string]$hex) {
  return [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function Draw-Cell($graphics, $brush, [int]$x, [int]$y, [int]$size = 1) {
  $graphics.FillRectangle($brush, $x * $cell, $y * $cell, $size * $cell, $size * $cell)
}

function Test-RoundedRectCell([int]$x, [int]$y, [int]$width, [int]$height, [int]$radius) {
  if ($x -lt 0 -or $y -lt 0 -or $x -ge $width -or $y -ge $height) { return $false }
  $cx = [Math]::Max($radius, [Math]::Min($width - $radius - 1, $x))
  $cy = [Math]::Max($radius, [Math]::Min($height - $radius - 1, $y))
  $dx = $x - $cx
  $dy = $y - $cy
  return ($dx * $dx + $dy * $dy) -le ($radius * $radius)
}

function Draw-GridPolygon($graphics, $brush, [int[][]]$points, [int]$offsetX = 0, [int]$offsetY = 0) {
  $nativePoints = [System.Drawing.Point[]]@(
    foreach ($point in $points) {
      [System.Drawing.Point]::new(($point[0] + $offsetX) * $cell, ($point[1] + $offsetY) * $cell)
    }
  )
  $graphics.FillPolygon($brush, $nativePoints)
}

function New-BubbleBitmap {
  $bitmap = [System.Drawing.Bitmap]::new($bubbleWidth, $bubbleHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
  $outline = New-ColorBrush '#352A3D'
  $shadow = New-ColorBrush '#E89CAF'
  $fill = New-ColorBrush '#FFF8F2'
  $inner = New-ColorBrush '#FFEAF0'

  $tailOuter = @(@(12,32),@(26,35),@(6,52))
  $tailInner = @(@(14,33),@(23,35),@(8,48))
  Draw-GridPolygon $graphics $shadow $tailOuter 2 2
  Draw-GridPolygon $graphics $outline $tailOuter
  Draw-GridPolygon $graphics $fill $tailInner

  # Pixel-stepped drop shadow behind a rounded bubble body.
  for ($y = 0; $y -lt $bubbleBodyCellsHigh; $y++) {
    for ($x = 0; $x -lt $bubbleBodyCellsWide; $x++) {
      if (Test-RoundedRectCell $x $y $bubbleBodyCellsWide $bubbleBodyCellsHigh 7) {
        Draw-Cell $graphics $shadow ($x + 2) ($y + 2)
      }
    }
  }

  for ($y = 0; $y -lt $bubbleBodyCellsHigh; $y++) {
    for ($x = 0; $x -lt $bubbleBodyCellsWide; $x++) {
      if (-not (Test-RoundedRectCell $x $y $bubbleBodyCellsWide $bubbleBodyCellsHigh 7)) { continue }
      $edge = -not (Test-RoundedRectCell ($x - 1) $y $bubbleBodyCellsWide $bubbleBodyCellsHigh 7) -or
              -not (Test-RoundedRectCell ($x + 1) $y $bubbleBodyCellsWide $bubbleBodyCellsHigh 7) -or
              -not (Test-RoundedRectCell $x ($y - 1) $bubbleBodyCellsWide $bubbleBodyCellsHigh 7) -or
              -not (Test-RoundedRectCell $x ($y + 1) $bubbleBodyCellsWide $bubbleBodyCellsHigh 7)
      if ($edge) { Draw-Cell $graphics $outline $x $y }
      elseif ($y -ge 34) { Draw-Cell $graphics $inner $x $y }
      else { Draw-Cell $graphics $fill $x $y }
    }
  }

  $outline.Dispose(); $shadow.Dispose(); $fill.Dispose(); $inner.Dispose()
  $graphics.Dispose()
  return $bitmap
}

function New-HeartBitmap {
  $heartCell = 6
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
  $bitmap = [System.Drawing.Bitmap]::new(16 * $heartCell, 14 * $heartCell, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
  $outline = New-ColorBrush '#A83257'
  $red = New-ColorBrush '#F45D80'
  $light = New-ColorBrush '#FF92A8'
  $shine = New-ColorBrush '#FFF7F3'
  for ($y = 0; $y -lt $pattern.Count - 1; $y++) {
    for ($x = 0; $x -lt $pattern[$y].Length; $x++) {
      if ($pattern[$y][$x] -ne '1') { continue }
      $edge = $pattern[[Math]::Max(0, $y - 1)][$x] -eq '0' -or
              $pattern[[Math]::Min($pattern.Count - 1, $y + 1)][$x] -eq '0' -or
              $x -eq 0 -or $pattern[$y][[Math]::Max(0, $x - 1)] -eq '0' -or
              $x -eq ($pattern[$y].Length - 1) -or $pattern[$y][[Math]::Min($pattern[$y].Length - 1, $x + 1)] -eq '0'
      $brush = if ($edge) { $outline } elseif ($y -lt 5 -or $x -lt 7) { $light } else { $red }
      $graphics.FillRectangle($brush, $x * $heartCell, $y * $heartCell, $heartCell, $heartCell)
    }
  }
  $graphics.FillRectangle($shine, 15, 10, 10, 5)
  $graphics.FillRectangle($shine, 20, 15, 5, 5)
  $outline.Dispose(); $red.Dispose(); $light.Dispose(); $shine.Dispose()
  $graphics.Dispose()
  return $bitmap
}

function Draw-ScaledNearest($graphics, $image, [int]$x, [int]$y, [double]$scale) {
  $width = [Math]::Max(1, [int][Math]::Round($image.Width * $scale))
  $height = [Math]::Max(1, [int][Math]::Round($image.Height * $scale))
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $graphics.DrawImage($image, [System.Drawing.Rectangle]::new($x, $y, $width, $height))
}

$bubble = New-BubbleBitmap
$heart = New-HeartBitmap
$bubbleScales = @(0,0,0,0,0.12,0.28,0.55,0.82,1,1,1,0.8,0.52,0.24,0,0)
$heartScales = @(0,0,0,0,0,0,0.35,0.8,1,0.9,1.05,0.85,0.6,0.2,0,0)
$bobY = @(0,2,4,2,0,2,4,2)
$bobX = @(0,0,1,1,0,0,-1,-1)

try {
  for ($i = 0; $i -lt 16; $i++) {
    $frame = [System.Drawing.Bitmap]::new($canvasWidth, $canvasHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($frame)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

    $phase = $i % 8
    $characterX = 24 + $bobX[$phase]
    $characterY = 75 + $bobY[$phase]
    $graphics.DrawImage($source, [System.Drawing.Rectangle]::new($characterX, $characterY, $characterWidth, $characterHeight))

    $bubbleScale = $bubbleScales[$i]
    if ($bubbleScale -gt 0) {
      # Keep the tail tip on the maid; the bubble grows away from that point.
      $left = $bubbleAnchorX - [int][Math]::Round($tailTipCellX * $cell * $bubbleScale)
      $top = $bubbleAnchorY - [int][Math]::Round($tailTipCellY * $cell * $bubbleScale)
      Draw-ScaledNearest $graphics $bubble $left $top $bubbleScale

      $heartScale = $heartScales[$i]
      if ($heartScale -gt 0) {
        $heartLocalX = [int][Math]::Round(($bubbleWidth - $heart.Width) / 2)
        $heartLocalY = [int][Math]::Round(($bubbleBodyCellsHigh * $cell - $heart.Height) / 2)
        $heartX = $left + [int][Math]::Round($heartLocalX * $bubbleScale)
        $heartY = $top + [int][Math]::Round($heartLocalY * $bubbleScale)
        Draw-ScaledNearest $graphics $heart $heartX $heartY ($heartScale * $bubbleScale)
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

Write-Output "Created 16 transparent PNG frames ($canvasWidth x $canvasHeight) in $framesPath"
