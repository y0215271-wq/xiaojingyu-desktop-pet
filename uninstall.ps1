$ErrorActionPreference = 'Stop'

$dst = Join-Path $env:LOCALAPPDATA 'XiaoJingYu'
$lnkPath = Join-Path ([Environment]::GetFolderPath('Desktop')) '小鲸鱼桌宠.lnk'

# 先让它自己关闭
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class PetCloser {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr FindWindow(string cls, string name);
    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
}
'@
$h = [PetCloser]::FindWindow($null, '鲸鱼正太')
if ($h -ne [IntPtr]::Zero) {
    [void][PetCloser]::PostMessage($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 800
}

if (Test-Path $lnkPath) { Remove-Item -LiteralPath $lnkPath -Force -ErrorAction SilentlyContinue }

if (Test-Path $dst) {
    try {
        Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction Stop
        Write-Host '  已卸载，文件已删除。' -ForegroundColor Green
    } catch {
        Write-Host '  文件被占用，删除失败。请先右键桌宠 → 退出，再运行一次本脚本。' -ForegroundColor Yellow
    }
} else {
    Write-Host '  没有找到安装目录，可能已经卸载过了。'
}
