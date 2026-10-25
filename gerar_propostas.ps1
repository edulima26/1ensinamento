# Gera 10 propostas de layout (com ondas) para o post 1 em propostas\ e uma folha-resumo.
# Uso: powershell -ExecutionPolicy Bypass -File gerar_propostas.ps1
Add-Type -AssemblyName System.Drawing

$root = $PSScriptRoot
$cfg = Get-Content (Join-Path $root 'posts.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$outDir = Join-Path $root 'propostas'
New-Item -ItemType Directory -Force $outDir | Out-Null

$p = $cfg.posts[0]
$pil = $cfg.pilares.($p.pilar)
$W = 1080; $H = 1350
$cBg = [System.Drawing.ColorTranslator]::FromHtml($pil.cor)
$cAc = [System.Drawing.ColorTranslator]::FromHtml($pil.destaque)
$cInk = [System.Drawing.ColorTranslator]::FromHtml('#2A2330')
$cWhite = [System.Drawing.Color]::White
$cCream = [System.Drawing.ColorTranslator]::FromHtml('#FFFBF2')
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]92)

function Mix($c, $k) { return [System.Drawing.Color]::FromArgb(255, [int](255 - (255 - $c.R) * $k), [int](255 - (255 - $c.G) * $k), [int](255 - (255 - $c.B) * $k)) }
function Br($c, $a = 255) { return New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, $c)) }
$t50 = Mix $cAc 0.5
$t30 = Mix $cAc 0.3

$sfC = New-Object System.Drawing.StringFormat
$sfC.Alignment = 'Center'
$sfC.Trimming = 'None'

function Fit-Font($text, $family, $style, $maxSize, $minSize, $width, $maxH) {
    for ($s = $maxSize; $s -ge $minSize; $s -= 2) {
        $f = New-Object System.Drawing.Font($family, [single]$s, $style, [System.Drawing.GraphicsUnit]::Pixel)
        if ($script:g.MeasureString($text, $f, $width, $sfC).Height -le $maxH) { return $f }
        $f.Dispose()
    }
    return New-Object System.Drawing.Font($family, [single]$minSize, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

# texto centralizado em ($cx, $cy), ajustando o tamanho da fonte
function Put($text, $style, $max, $min, $w, $maxH, $cy, $color, $cx = 540) {
    $f = Fit-Font $text 'Segoe UI' $style $max $min $w $maxH
    $h = $script:g.MeasureString($text, $f, $w, $sfC).Height
    $rect = New-Object System.Drawing.RectangleF([single]($cx - $w / 2), [single]($cy - $h / 2), [single]$w, [single]($h + 10))
    $script:g.DrawString($text, $f, (Br $color), $rect, $sfC)
}

# onda horizontal; $above = pinta acima da linha, senao abaixo
function Wave($y, $amp, $above, $color, $alpha = 255) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddBezier(-10, $y, ($W * 0.28), ($y - $amp), ($W * 0.62), ($y + $amp), ($W + 10), $y)
    if ($above) { $path.AddLine($W + 10, $y, $W + 10, -10); $path.AddLine($W + 10, -10, -10, -10) }
    else { $path.AddLine($W + 10, $y, $W + 10, $H + 10); $path.AddLine($W + 10, $H + 10, -10, $H + 10) }
    $path.CloseFigure()
    $script:g.FillPath((Br $color $alpha), $path)
}

# onda diagonal de ($y0 na esquerda) ate ($y1 na direita)
function WaveD($y0, $y1, $amp, $above, $color, $alpha = 255) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddBezier(-10, $y0, ($W * 0.3), ($y0 + ($y1 - $y0) * 0.3 - $amp), ($W * 0.65), ($y0 + ($y1 - $y0) * 0.7 + $amp), ($W + 10), $y1)
    if ($above) { $path.AddLine($W + 10, $y1, $W + 10, -10); $path.AddLine($W + 10, -10, -10, -10) }
    else { $path.AddLine($W + 10, $y1, $W + 10, $H + 10); $path.AddLine($W + 10, $H + 10, -10, $H + 10) }
    $path.CloseFigure()
    $script:g.FillPath((Br $color $alpha), $path)
}

# faixa lateral ondulada (esquerda ou direita)
function Side($left, $w0, $shift, $color, $alpha = 255) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $a = $w0 + $shift
    if ($left) {
        $path.AddBezier($a, -10, ($a - 110), 450, ($a + 110), 900, ($a - 30), ($H + 10))
        $path.AddLine($a - 30, $H + 10, -10, $H + 10); $path.AddLine(-10, $H + 10, -10, -10)
    } else {
        $x = $W - $a
        $path.AddBezier($x, -10, ($x + 110), 450, ($x - 110), 900, ($x + 30), ($H + 10))
        $path.AddLine($x + 30, $H + 10, $W + 10, $H + 10); $path.AddLine($W + 10, $H + 10, $W + 10, -10)
    }
    $path.CloseFigure()
    $script:g.FillPath((Br $color $alpha), $path)
}

function Circle($cx, $cy, $r, $color, $alpha) { $script:g.FillEllipse((Br $color $alpha), ($cx - $r), ($cy - $r), (2 * $r), (2 * $r)) }

$B = [System.Drawing.FontStyle]::Bold
$R = [System.Drawing.FontStyle]::Regular
$names = @('Tres zonas', 'Faixas cheias', 'Circulo no titulo', 'Diagonais', 'Titulo limpo e onda grande', 'Faixa escura no topo', 'Fita ondulada', 'Modo escuro embaixo', 'Ondas laterais', 'Cortina e base')

for ($n = 1; $n -le 10; $n++) {
    $bmp = New-Object System.Drawing.Bitmap($W, $H)
    $script:g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.Clear($cBg)
    $footColor = $cInk

    switch ($n) {
        1 {
            Wave 650 -80 $true $cAc 130; Wave 600 90 $true $t50
            Circle 930 120 190 $cWhite 55; Circle 90 470 120 $cWhite 45
            Put $p.gancho $B 124 70 880 480 320 $cInk
            Put $p.texto $R 42 30 780 200 810 $cInk
            Wave 960 -70 $false $t50; Wave 1020 80 $false $cAc
            Put $p.chamada $B 50 34 800 160 1185 $cInk
        }
        2 {
            $g.Clear($t50)
            Circle 900 140 200 $cWhite 70; Circle 120 560 110 $cWhite 60
            Put $p.gancho $B 124 70 880 480 330 $cInk
            Wave 700 90 $false $cCream
            Wave 1030 -80 $false $cAc 150; Wave 1070 80 $false $cAc
            Put $p.texto $R 42 30 780 200 880 $cInk
            Put $p.chamada $B 50 34 800 160 1205 $cInk
        }
        3 {
            Circle 540 300 440 $cAc 90; Circle 540 300 400 $t50 255
            Circle 960 760 80 $cAc 70; Circle 100 700 55 $cAc 60
            Put $p.gancho $B 108 62 640 440 300 $cInk
            Put $p.texto $R 42 30 780 200 880 $cInk
            Wave 1000 70 $false $t50; Wave 1060 -60 $false $cAc
            Put $p.chamada $B 50 34 800 160 1205 $cInk
        }
        4 {
            WaveD 520 800 -70 $true $cAc 120; WaveD 470 760 60 $true $t50
            WaveD 1090 860 60 $false $t50; WaveD 1130 900 -60 $false $cAc
            Circle 940 110 150 $cWhite 55
            Put $p.gancho $B 124 70 880 400 270 $cInk
            Put $p.texto $R 40 30 640 200 830 $cInk
            Put $p.chamada $B 48 32 760 150 1210 $cInk
        }
        5 {
            Circle 960 90 130 $cAc 70; Circle 90 330 80 $cAc 55
            Put $p.gancho $B 112 62 940 330 235 $cInk
            Wave 440 -90 $false $cAc 120; Wave 480 80 $false $t50
            Put $p.texto $R 44 30 780 220 800 $cInk
            Wave 1020 70 $false $cAc
            Put $p.chamada $B 50 34 800 160 1195 $cInk
        }
        6 {
            Wave 720 -80 $true $cAc 160; Wave 660 90 $true $cInk
            Circle 940 90 150 $cWhite 22; Circle 110 520 100 $cWhite 18
            Put $p.gancho $B 124 70 880 480 330 $cCream
            Put $p.texto $R 42 30 780 200 850 $cInk
            Wave 1010 -60 $false $t50; Wave 1060 70 $false $cAc
            Put $p.chamada $B 50 34 800 160 1205 $cInk
        }
        7 {
            Circle 950 100 120 $cAc 70; Circle 110 130 70 $cAc 55
            Put $p.gancho $B 112 62 940 380 245 $cInk
            $path = New-Object System.Drawing.Drawing2D.GraphicsPath
            $path.AddBezier(-10, 540, 330, 430, 700, 670, 1090, 540)
            $path.AddLine(1090, 540, 1090, 840)
            $path.AddBezier(1090, 840, 700, 970, 330, 730, -10, 840)
            $path.CloseFigure()
            $mx = New-Object System.Drawing.Drawing2D.Matrix; $mx.Translate(0, 26); $sh = $path.Clone(); $sh.Transform($mx)
            $g.FillPath((Br $cAc 130), $sh); $g.FillPath((Br $t50), $path)
            Put $p.texto $R 42 30 720 210 700 $cInk
            Put $p.chamada $B 54 34 860 200 1070 $cInk
            Wave 1250 50 $false $cAc
        }
        8 {
            $g.Clear($cInk); $footColor = $cCream
            Wave 640 -80 $true $cAc 140; Wave 600 90 $true $t50
            Circle 930 110 170 $cWhite 50
            Put $p.gancho $B 124 70 880 460 320 $cInk
            Put $p.texto $R 42 30 780 200 840 $cCream
            Put $p.chamada $B 52 34 800 170 1070 $cAc
            Wave 1240 -40 $false $cAc 70; Wave 1270 40 $false $cAc 160
        }
        9 {
            Side $true 130 70 $cAc 110; Side $true 130 0 $t50
            Side $false 130 70 $cAc 110; Side $false 130 0 $t50
            Put $p.gancho $B 112 62 680 480 330 $cInk
            Put $p.texto $R 40 30 620 220 790 $cInk
            Put $p.chamada $B 50 34 640 220 1060 $cInk
        }
        10 {
            Wave 230 40 $true $t50; Wave 170 -45 $true $cAc 200; Wave 140 40 $true $cAc
            Wave 1110 -50 $false $t50; Wave 1170 50 $false $cAc
            Put $p.gancho $B 124 70 900 400 430 $cInk
            Put $p.texto $R 42 30 780 200 770 $cInk
            Put $p.chamada $B 52 34 800 170 985 $cInk
        }
    }

    $fF = New-Object System.Drawing.Font('Segoe UI', 26, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $g.DrawString($cfg.handle, $fF, (Br $footColor 150), (New-Object System.Drawing.RectangleF(0, 1296, $W, 40)), $sfC)
    $bmp.Save((Join-Path $outDir ('proposta_{0:00}.jpg' -f $n)), $jpeg, $encParams)
    $g.Dispose(); $bmp.Dispose()
}

# folha-resumo 5x2
$tw = 380; $th = 475; $gap = 20; $lab = 40
$sheet = New-Object System.Drawing.Bitmap(($gap + ($tw + $gap) * 5), ($gap + ($th + $lab + $gap) * 2))
$sg = [System.Drawing.Graphics]::FromImage($sheet)
$sg.Clear([System.Drawing.Color]::FromArgb(245, 243, 238))
$sg.InterpolationMode = 'HighQualityBicubic'
$sg.TextRenderingHint = 'AntiAliasGridFit'
$lf = New-Object System.Drawing.Font('Segoe UI', 22, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
for ($n = 1; $n -le 10; $n++) {
    $col = ($n - 1) % 5; $row = [math]::Floor(($n - 1) / 5)
    $x = $gap + $col * ($tw + $gap); $y = $gap + $row * ($th + $lab + $gap)
    $img = [System.Drawing.Image]::FromFile((Join-Path $outDir ('proposta_{0:00}.jpg' -f $n)))
    $sg.DrawImage($img, $x, ($y + $lab), $tw, $th)
    $img.Dispose()
    $sg.DrawString(('{0} - {1}' -f $n, $names[$n - 1]), $lf, [System.Drawing.Brushes]::Black, $x, ($y + 6))
}
$sheet.Save((Join-Path $outDir 'resumo.jpg'), $jpeg, $encParams)
$sg.Dispose(); $sheet.Dispose()
Write-Output "OK: 10 propostas em $outDir"
