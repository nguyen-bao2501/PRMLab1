param([string]$ImagePath)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
try {
    if (-not $ImagePath) {
        Add-Type -AssemblyName System.Windows.Forms
        $picker = New-Object System.Windows.Forms.OpenFileDialog
        $picker.Filter = 'Schedule image|*.png;*.jpg;*.jpeg;*.bmp'
        $picker.Title = 'Choose teaching schedule image'
        if ($picker.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            '{"cancelled":true}'
            exit 0
        }
        $ImagePath = $picker.FileName
        $picker.Dispose()
    }
    $fileInfo = Get-Item -LiteralPath $ImagePath
    if ($fileInfo.Length -gt 10485760) { throw 'Image must be smaller than 10 MB.' }
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $null = [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime]
    $null = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType=WindowsRuntime]
    $null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType=WindowsRuntime]
    $null = [Windows.Graphics.Imaging.SoftwareBitmap, Windows.Graphics.Imaging, ContentType=WindowsRuntime]
    $null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType=WindowsRuntime]
    $null = [Windows.Media.Ocr.OcrResult, Windows.Foundation, ContentType=WindowsRuntime]
    $null = [Windows.Globalization.Language, Windows.Globalization, ContentType=WindowsRuntime]
    function Await-Result($Operation, $Type) {
        $method = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
            $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and
            $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
        } | Select-Object -First 1
        $task = $method.MakeGenericMethod($Type).Invoke($null, @($Operation))
        if (-not $task.Wait(60000)) { throw 'OCR timed out.' }
        return $task.Result
    }
    $file = Await-Result ([Windows.Storage.StorageFile]::GetFileFromPathAsync($fileInfo.FullName)) ([Windows.Storage.StorageFile])
    $stream = Await-Result ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
    $decoder = Await-Result ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
    $max = [Windows.Media.Ocr.OcrEngine]::MaxImageDimension
    if ($decoder.PixelWidth -gt $max -or $decoder.PixelHeight -gt $max) { throw "Image dimensions must be <= $max pixels. Resize the image and retry." }
    $bitmap = Await-Result ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
    $language = New-Object Windows.Globalization.Language('en-US')
    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($language)
    if (-not $engine) { throw 'Install English OCR in Windows Settings > Language > English > Language options.' }
    $result = Await-Result ($engine.RecognizeAsync($bitmap)) ([Windows.Media.Ocr.OcrResult])
    $words = @($result.Lines | ForEach-Object { $_.Words } | ForEach-Object {
        @{ text = $_.Text; x = $_.BoundingRect.X; y = $_.BoundingRect.Y; w = $_.BoundingRect.Width; h = $_.BoundingRect.Height }
    })
    @{ path = $fileInfo.FullName; width = $decoder.PixelWidth; height = $decoder.PixelHeight; words = $words } | ConvertTo-Json -Depth 5 -Compress
    $bitmap.Dispose()
    $stream.Dispose()
} catch {
    @{ error = $_.Exception.Message } | ConvertTo-Json -Compress
    exit 1
}
