$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot 'app'
$dst = Join-Path $env:LOCALAPPDATA 'XiaoJingYu'

if (-not (Test-Path $src)) {
    Write-Host '找不到 app 文件夹，请先把压缩包完整解压再运行。' -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item (Join-Path $src '*') $dst -Recurse -Force

# 桌面快捷方式
$lnkPath = Join-Path ([Environment]::GetFolderPath('Desktop')) '小鲸鱼桌宠.lnk'
$sh = New-Object -ComObject WScript.Shell
$lnk = $sh.CreateShortcut($lnkPath)
$lnk.TargetPath = Join-Path $env:SystemRoot 'System32\wscript.exe'
$lnk.Arguments = '"' + (Join-Path $dst 'pet.vbs') + '"'
$lnk.WorkingDirectory = $dst
$lnk.IconLocation = (Join-Path $dst 'pet.ico') + ',0'
$lnk.Description = '小鲸鱼桌宠'
$lnk.Save()

# 若已有实例在跑，就先结束它，避免多开
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class PetFinder {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr FindWindow(string cls, string name);
    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
}
'@
$h = [PetFinder]::FindWindow($null, '鲸鱼正太')
if ($h -ne [IntPtr]::Zero) {
    [void][PetFinder]::PostMessage($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 400
}

Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\wscript.exe') -ArgumentList ('"' + (Join-Path $dst 'pet.vbs') + '"')

Write-Host ''
Write-Host '  安装完成。' -ForegroundColor Green
Write-Host "  程序位置：$dst"
Write-Host '  桌面已生成「小鲸鱼桌宠」快捷方式，双击即可启动。'
Write-Host ''
Write-Host '  退出方式：右键桌宠 → 退出'
Write-Host '  卸载方式：运行压缩包里的 卸载.cmd'
Write-Host ''
