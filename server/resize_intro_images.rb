# frozen_string_literal: true

require "fileutils"

puts "================================================="
puts "📐 Redimensionnement automatique en 512x384 pixels"
puts "================================================="

ps_script_path = "server/do_resize.ps1"

ps_code = <<~'POWERSHELL'
Add-Type -AssemblyName System.Drawing

$targetWidth = 512
$targetHeight = 384

$searchFolders = @("Graphics/Pictures", "INTRO")

foreach ($dir in $searchFolders) {
    if (Test-Path $dir) {
        $files = Get-ChildItem -Path $dir -Include "introbg*.png","Gemini_*.png" -Recurse
        foreach ($file in $files) {
            try {
                $imgPath = $file.FullName
                $img = [System.Drawing.Image]::FromFile($imgPath)
                
                # Check if resize is needed
                if ($img.Width -eq $targetWidth -and $img.Height -eq $targetHeight) {
                    $img.Dispose()
                    continue
                }

                $bmp = New-Object System.Drawing.Bitmap $targetWidth, $targetHeight
                $g = [System.Drawing.Graphics]::FromImage($bmp)
                
                $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                
                $g.DrawImage($img, 0, 0, $targetWidth, $targetHeight)
                
                $img.Dispose()
                $g.Dispose()
                
                $tmpPath = "$imgPath.tmp.png"
                $bmp.Save($tmpPath, [System.Drawing.Imaging.ImageFormat]::Png)
                $bmp.Dispose()
                
                Remove-Item $imgPath -Force
                Rename-Item $tmpPath $file.Name
                Write-Host "✅ Redimensionné en 512x384 : $($file.Name)"
            } catch {
                Write-Host "❌ Erreur sur $($file.Name) : $_"
            }
        }
    }
}
POWERSHELL

File.write(ps_script_path, ps_code)

system("powershell -ExecutionPolicy Bypass -File #{ps_script_path}")

puts "================================================="
puts "✨ Toutes les images d'intro sont désormais exactement en 512x384 !"
puts "================================================="

