param(
  [string]$AssetRoot = (Join-Path (Join-Path $PSScriptRoot '..\..\..') 'private-image-assets-saver')
)

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path $AssetRoot 'originals/source-images/demon-maid-sd-pixel-source.png'
$framesPath = Join-Path $AssetRoot 'subproject-assets/pixel-motion-studio/demon-maid-idle-heart-v4/frames'
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
  $outline = New-ColorBrush '#9F3156'
  $pink = New-ColorBrush '#F35D82'
  $light = New-ColorBrush '#FFA0B6'
  $shine = New-ColorBrush '#FFF7F5'

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

  $graphics.FillRectangle($shine, 15, 10, 10, 5)
  $graphics.FillRectangle($shine, 20, 15, 5, 5)
  $outline.Dispose(); $pink.Dispose(); $light.Dispose(); $shine.Dispose()
  $graphics.Dispose()
  return $bitmap
}

function New-RotatedHeart($heart, [double]$angle) {
  $side = [int][Math]::Ceiling([Math]::Sqrt(($heart.Width * $heart.Width) + ($heart.Height * $heart.Height))) + 8
  $rotated = [System.Drawing.Bitmap]::new($side, $side, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($rotated)
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $graphics.TranslateTransform($side / 2, $side / 2)
  $graphics.RotateTransform([single]$angle)
  $rect = [System.Drawing.Rectangle]::new(-[int][Math]::Floor($heart.Width / 2), -[int][Math]::Floor($heart.Height / 2), $heart.Width, $heart.Height)
  $graphics.DrawImage($heart, $rect)
  $graphics.Dispose()
  return $rotated
}

function Draw-HeartParticle($graphics, $heart, [double]$centerX, [double]$centerY, [double]$scale, [double]$angle, [double]$squashX = 1, [double]$squashY = 1) {
  if ($scale -le 0) { return }
  $rotated = New-RotatedHeart $heart $angle
  try {
    $width = [Math]::Max(1, [int][Math]::Round($rotated.Width * $scale * $squashX))
    $height = [Math]::Max(1, [int][Math]::Round($rotated.Height * $scale * $squashY))
    $x = [int][Math]::Round($centerX - $width / 2)
    $y = [int][Math]::Round($centerY - $height / 2)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.DrawImage($rotated, [System.Drawing.Rectangle]::new($x, $y, $width, $height))
  }
  finally {
    $rotated.Dispose()
  }
}

$heart = New-PinkHeart
$bobY = @(0,2,4,2,0,2,4,2)
$bobX = @(0,0,1,1,0,0,-1,-1)
$mainScale = @(0,0,0,0,0.22,0.48,0.78,1,1.08,1.02,0.84,0.62,0.4,0.22,0,0)
$mainX = @(330,330,330,330,325,305,282,260,240,228,218,210,204,198,198,198)
$mainY = @(500,500,500,500,520,500,475,450,430,415,400,385,374,366,366,366)
$mainAngle = @(0,0,0,0,-20,-14,-8,-2,8,15,12,2,-8,-18,-18,-18)
$squashX = @(1,1,1,1,0.88,0.95,1.04,1.08,1.12,1.02,0.96,0.9,0.86,0.8,1,1)
$squashY = @(1,1,1,1,1.12,1.05,0.98,0.94,0.9,0.98,1.04,1.1,1.12,1.15,1,1)
$satelliteOneScale = @(0,0,0,0,0,0,0.18,0.34,0.4,0.34,0.24,0.12,0,0,0,0)
$satelliteTwoScale = @(0,0,0,0,0,0,0,0,0.16,0.28,0.34,0.24,0.12,0,0,0)

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

    # Hearts appear just outside the character's viewer-left cheek and float diagonally up-left.
    if ($satelliteOneScale[$i] -gt 0) {
      $x = $mainX[$i] + 54 - [Math]::Max(0, $i - 6) * 3
      $y = $mainY[$i] + 22 - [Math]::Max(0, $i - 6) * 9
      Draw-HeartParticle $graphics $heart $x $y $satelliteOneScale[$i] -12 1 1
    }
    if ($satelliteTwoScale[$i] -gt 0) {
      $x = $mainX[$i] + 94 - [Math]::Max(0, $i - 8) * 4
      $y = $mainY[$i] + 38 - [Math]::Max(0, $i - 8) * 10
      Draw-HeartParticle $graphics $heart $x $y $satelliteTwoScale[$i] 16 0.92 1.08
    }
    if ($mainScale[$i] -gt 0) {
      Draw-HeartParticle $graphics $heart $mainX[$i] $mainY[$i] $mainScale[$i] $mainAngle[$i] $squashX[$i] $squashY[$i]
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
