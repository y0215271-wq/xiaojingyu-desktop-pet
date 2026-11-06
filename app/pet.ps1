$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$framesDir = Join-Path $here 'frames'
$script:log = Join-Path $here 'pet.log'
$script:debug = Test-Path (Join-Path $here 'debug.flag')

# 显示尺寸：改这一个数就行（宽，单位像素），高度按 640:900 自动算
$PET_WIDTH = 180

function Log([string]$m) {
    if ($script:debug) { "$(Get-Date -Format 'HH:mm:ss') $m" | Add-Content -Path $script:log -Encoding UTF8 }
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class PetWinApi {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr FindWindow(string cls, string name);
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@
if ([PetWinApi]::FindWindow($null, '鲸鱼正太') -ne [IntPtr]::Zero) { exit }

# 麦克风占用检测（WASAPI 会话状态）：任何程序在录音就返回 true
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class MicProbe
{
    [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    private class MMDeviceEnumerator { }

    private enum EDataFlow { eRender = 0, eCapture = 1, eAll = 2 }
    private enum ERole { eConsole = 0, eMultimedia = 1, eCommunications = 2 }

    [ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IMMDeviceEnumerator
    {
        int EnumAudioEndpoints(EDataFlow dataFlow, int stateMask, out IntPtr devices);
        int GetDefaultAudioEndpoint(EDataFlow dataFlow, ERole role, out IMMDevice endpoint);
        int GetDevice(string id, out IMMDevice device);
        int RegisterEndpointNotificationCallback(IntPtr client);
        int UnregisterEndpointNotificationCallback(IntPtr client);
    }

    [ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IMMDevice
    {
        int Activate(ref Guid iid, int clsCtx, IntPtr activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object iface);
        int OpenPropertyStore(int access, out IntPtr store);
        int GetId(out IntPtr id);
        int GetState(out int state);
    }

    [ComImport, Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IAudioSessionManager2
    {
        int GetAudioSessionControl(IntPtr guid, int flags, out IntPtr ctrl);
        int GetSimpleAudioVolume(IntPtr guid, int flags, out IntPtr vol);
        int GetSessionEnumerator(out IAudioSessionEnumerator enumerator);
        int RegisterSessionNotification(IntPtr n);
        int UnregisterSessionNotification(IntPtr n);
        int RegisterDuckNotification(string id, IntPtr n);
        int UnregisterDuckNotification(IntPtr n);
    }

    [ComImport, Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IAudioSessionEnumerator
    {
        int GetCount(out int count);
        int GetSession(int index, out IAudioSessionControl2 session);
    }

    [ComImport, Guid("BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IAudioSessionControl2
    {
        int GetState(out int state);
        int GetDisplayName(out IntPtr name);
        int SetDisplayName(string name, IntPtr guid);
        int GetIconPath(out IntPtr path);
        int SetIconPath(string path, IntPtr guid);
        int GetGroupingParam(out Guid g);
        int SetGroupingParam(ref Guid g, IntPtr ctx);
        int RegisterAudioSessionNotification(IntPtr n);
        int UnregisterAudioSessionNotification(IntPtr n);
        int GetSessionIdentifier(out IntPtr id);
        int GetSessionInstanceIdentifier(out IntPtr id);
        int GetProcessId(out uint pid);
        int IsSystemSoundsSession();
        int SetDuckingPreference(bool optOut);
    }

    public static bool AnyActive()
    {
        try
        {
            var en = (IMMDeviceEnumerator)(new MMDeviceEnumerator());
            IMMDevice dev;
            if (en.GetDefaultAudioEndpoint(EDataFlow.eCapture, ERole.eConsole, out dev) != 0) return false;
            Guid iid = typeof(IAudioSessionManager2).GUID;
            object mgrObj;
            if (dev.Activate(ref iid, 23, IntPtr.Zero, out mgrObj) != 0) return false;
            var mgr = (IAudioSessionManager2)mgrObj;
            IAudioSessionEnumerator list;
            if (mgr.GetSessionEnumerator(out list) != 0) return false;
            int count = 0;
            list.GetCount(out count);
            for (int i = 0; i < count; i++)
            {
                IAudioSessionControl2 c;
                if (list.GetSession(i, out c) != 0) continue;
                int st; c.GetState(out st);
                uint pid; c.GetProcessId(out pid);
                if (st == 1 && pid != 0) return true;
            }
            return false;
        }
        catch { return false; }
    }
}
'@

$lines = @(
    '哼！我超聪明的！',
    '再摸就要收费了……才怪。',
    '你们还不懂吧…',
    '其实我早就想到了。',
    '别、别摸头啦！',
    '才不是特意来陪你的呢。',
    '今天也要好好干活哦。',
    '困了…让我眯一会儿。',
    '摸鱼也是工作的一部分。'
)

$clickLines = @(
    '啊Σ( ° △ °|||)︴',
    '别点我了~',
    '再这样我要生气了(｡･ˇ_ˇ･｡:)'
)

$petXaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Width='300' Height='422' WindowStyle='None' AllowsTransparency='True'
        Background='Transparent' Topmost='True' ShowInTaskbar='False'
        ResizeMode='NoResize' Title='鲸鱼正太'>
  <Grid Background='Transparent'>
    <Image x:Name='PetImage' Stretch='Uniform' RenderTransformOrigin='0.5,1'
           RenderOptions.BitmapScalingMode='HighQuality'>
      <Image.RenderTransform>
        <TransformGroup>
          <ScaleTransform x:Name='Scaler' ScaleX='1' ScaleY='1'/>
        </TransformGroup>
      </Image.RenderTransform>
    </Image>
  </Grid>
</Window>
"@

$bubbleXaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        SizeToContent='WidthAndHeight' WindowStyle='None' AllowsTransparency='True'
        Background='Transparent' Topmost='True' ShowInTaskbar='False'
        ShowActivated='False' Focusable='False' Title='鲸鱼正太气泡'>
  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height='*'/>
      <RowDefinition Height='Auto'/>
    </Grid.RowDefinitions>
    <Border Grid.Row='0' Background='#F7FFFFFF' CornerRadius='14' Padding='13,9' BorderThickness='1'
            BorderBrush='#3390B4E8' Margin='12,0,12,0'>
      <Border.Effect>
        <DropShadowEffect BlurRadius='12' ShadowDepth='3' Opacity='0.22' Color='#1E2C4A'/>
      </Border.Effect>
      <TextBlock x:Name='BubbleText' TextWrapping='Wrap' MaxWidth='230' FontSize='13'
                 LineHeight='19' Foreground='#243A5E' FontFamily='Microsoft YaHei UI'/>
    </Border>
    <Path Grid.Row='1' Fill='#F7FFFFFF' Data='M 0,0 L 16,0 L 8,10 Z'
          HorizontalAlignment='Center' Margin='0,-1,0,6'/>
  </Grid>
</Window>
"@

$pet = [Windows.Markup.XamlReader]::Parse($petXaml)
$bubble = [Windows.Markup.XamlReader]::Parse($bubbleXaml)

$pet.Width = $PET_WIDTH
$pet.Height = [int]($PET_WIDTH * 900 / 640)

$img = $pet.FindName('PetImage')
$scaler = $pet.FindName('Scaler')
$bubbleText = $bubble.FindName('BubbleText')

$script:bitmaps = @{}
foreach ($k in @{ idle = '01_idle.png'; blink = '02_blink.png'; type = '06_type.png'; sit = '07_sit.png'; question = '08_question.png'; react = '09_react.png'; held = '13_held.png'; peek_left = 'peek_left.png'; peek_right = 'peek_right.png'; sleep = '10_sleep.png'; jump = '12_jump.png' }.GetEnumerator()) {
    $b = New-Object System.Windows.Media.Imaging.BitmapImage
    $b.BeginInit()
    $b.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $b.UriSource = [Uri](Join-Path $framesDir $k.Value)
    $b.EndInit()
    $b.Freeze()
    $script:bitmaps[$k.Key] = $b
}
$script:curFrame = ''
function Set-Frame([string]$name) {
    if ($script:curFrame -ne $name -and $script:bitmaps.ContainsKey($name)) {
        $img.Source = $script:bitmaps[$name]
        $script:curFrame = $name
        if ($script:debug) { Log "frame -> $name" }
    }
}

# 聆听：有 14_listen.png 就用它，没有就先借用疑问那张
$listenPng = Join-Path $framesDir '14_listen.png'
if (Test-Path $listenPng) {
    $lb = New-Object System.Windows.Media.Imaging.BitmapImage
    $lb.BeginInit()
    $lb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $lb.UriSource = [Uri]$listenPng
    $lb.EndInit()
    $lb.Freeze()
    $script:bitmaps['listen'] = $lb
}
function Set-ListenFrame {
    if ($script:bitmaps.ContainsKey('listen')) { Set-Frame 'listen' } else { Set-Frame 'question' }
}
Set-Frame 'idle'

$wa = [System.Windows.SystemParameters]::WorkArea
$pet.WindowStartupLocation = 'Manual'
$pet.Left = $wa.Right - $pet.Width - 36
# 画布底部有 12px 透明边，按缩放折算回去，让脚底贴近工作区底边（留 2px）
$script:canvasPad = 12 * ($PET_WIDTH / 640)
$pet.Top = $wa.Bottom - $pet.Height + $script:canvasPad - 2

$script:state = 'idle'
$script:stateSince = 0.0
$script:t = 0.0
$script:lastT = 0.0
$script:lastLog = 0.0
$script:nextBlink = 3.0
$script:blinkUntil = 0.0
$script:lastInteract = 0.0
$script:dragging = $false

# 与 DSH 的桥：插件把状态写进同目录的 state.json
$script:bridgePath = Join-Path $here 'state.json'
$script:manualUntil = 0.0
$script:bridgeNext = 0.0
$script:typingUntil = 0.0
$script:keyNext = 0.0
$script:micNext = 0.0
$script:micActive = $false
$script:menuOpen = $false

$script:hideTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:hideTimer.Interval = [TimeSpan]::FromSeconds(4.2)
$script:clock = [Diagnostics.Stopwatch]::StartNew()
$script:frameTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:frameTimer.Interval = [TimeSpan]::FromMilliseconds(33)

function Place-Bubble {
    $bubble.UpdateLayout()
    $bubble.Left = $pet.Left + ($pet.Width - $bubble.ActualWidth) / 2
    $bubble.Top = $pet.Top - $bubble.ActualHeight + 26
}

function Show-Bubble([string]$text) {
    $bubbleText.Text = $text
    $bubble.Show()
    Place-Bubble
    $script:hideTimer.Stop()
    $script:hideTimer.Start()
}

function Enter-State([string]$name) {
    $script:state = $name
    $script:stateSince = $script:t
    $script:lastInteract = $script:t
    Log "state -> $name"
}

function Test-TypingKey {
    $keys = @(0x41..0x5A) + @(0x30..0x39) + @(0x20, 0x08, 0x0D, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xDB, 0xDC, 0xDD, 0xDE)
    foreach ($k in $keys) {
        if (([PetWinApi]::GetAsyncKeyState($k) -band 0x8000) -ne 0) { return $true }
    }
    return $false
}

function Test-MicInUse {
    return [MicProbe]::AnyActive()
}

$script:hideTimer.Add_Tick({
    $script:hideTimer.Stop()
    $bubble.Hide()
})

$script:frameTimer.Add_Tick({
    $now = $script:clock.Elapsed.TotalSeconds
    $dt = $now - $script:lastT
    if ($dt -le 0) { return }
    if ($dt -gt 0.12) { $dt = 0.12 }
    $script:lastT = $now
    $script:t += $dt

    # 呼吸（Q 弹期间改由弹簧曲线控制）
    if ($script:state -eq 'bounce') {
        $e = $script:t - $script:stateSince
        $k = [Math]::Exp(-5.5 * $e) * [Math]::Cos(13.0 * $e)
        $scaler.ScaleY = 1 - 0.22 * $k
        $scaler.ScaleX = 1 + 0.13 * $k
    } elseif ($script:state -eq 'land') {
        $e = $script:t - $script:stateSince
        $k = [Math]::Exp(-6.0 * $e) * [Math]::Cos(12.0 * $e)
        $scaler.ScaleY = 1 - 0.14 * $k
        $scaler.ScaleX = 1 + 0.08 * $k
    } else {
        $breathe = [Math]::Sin($script:t * 2.2)
        $scaler.ScaleY = 1 + 0.012 * $breathe
        $scaler.ScaleX = 1 - 0.006 * $breathe
    }

    # 与 DSH 同步：每 0.3 秒看一眼 state.json
    if ($script:t -gt $script:bridgeNext) {
        $script:bridgeNext = $script:t + 0.3
        $quiet = ($script:manualUntil -lt $script:t) -and (-not $script:dragging) -and ($script:state -notlike 'peek_*')
        if ($quiet -and ($script:state -ne 'bounce' -or ($script:t - $script:stateSince) -gt 1.2)) {
            try {
                if (Test-Path $script:bridgePath) {
                    $raw = Get-Content $script:bridgePath -Raw -ErrorAction Stop
                    if ($raw) {
                        $j = $raw | ConvertFrom-Json
                        $age = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - [int64]$j.ts
                        if ($age -lt 6000) {
                            switch ($j.state) {
                                'type' {
                                    if ($script:state -ne 'type') {
                                        $script:state = 'type'
                                        $script:stateSince = $script:t
                                        Set-Frame 'type'
                                    }
                                }
                                'idle' {
                                    if ($script:state -eq 'type') {
                                        $script:state = 'idle'
                                        $script:lastInteract = $script:t
                                        Set-Frame 'idle'
                                    }
                                }
                                'error' {
                                    Enter-State 'bounce'
                                    Set-Frame 'react'
                                }
                            }
                        }
                    }
                }
            } catch { }
        }
    }

    # 打字检测：你在敲键盘时它会歪头看
    if ($script:t -gt $script:keyNext) {
        $script:keyNext = $script:t + 0.12
        if (Test-TypingKey) { $script:typingUntil = $script:t + 1.4 }
    }

    # 麦克风检测：有人开麦（比如语音输入）就进入聆听
    if ($script:t -gt $script:micNext) {
        $script:micNext = $script:t + 0.5
        $script:micActive = Test-MicInUse
    }

    # 拖拽中：被拎起来的静态姿势
    if ($script:dragging) {
        Set-Frame 'held'
        return
    }

    # 右键菜单打开时：歪头思考
    if ($script:menuOpen) {
        Set-Frame 'question'
        return
    }

    switch ($script:state) {
        'idle' {
            if (($script:t - $script:lastInteract) -gt 90) {
                Enter-State 'sleep'
                Set-Frame 'sleep'
            } elseif ($script:micActive) {
                Set-ListenFrame
            } elseif ($script:t -lt $script:typingUntil) {
                Set-Frame 'question'
            } else {
                if ($script:t -gt $script:nextBlink) {
                    $script:blinkUntil = $script:t + 0.12
                    $script:nextBlink = $script:t + 3 + (Get-Random -Maximum 5)
                }
                if ($script:t -lt $script:blinkUntil) { Set-Frame 'blink' }
                else { Set-Frame 'idle' }
            }
        }
        'bounce' {
            Set-Frame 'react'
            if (($script:t - $script:stateSince) -gt 1.0) {
                $script:state = 'idle'
                $script:lastInteract = $script:t
                $scaler.ScaleX = 1
                $scaler.ScaleY = 1
                Set-Frame 'idle'
            }
        }
        'land' {
            Set-Frame 'idle'
            if (($script:t - $script:stateSince) -gt 0.7) {
                $script:state = 'idle'
                $scaler.ScaleX = 1
                $scaler.ScaleY = 1
            }
        }
        'type' {
            Set-Frame 'type'
            if (($script:t - $script:stateSince) -gt 120) { $script:state = 'idle' }
        }
        'sit' {
            Set-Frame 'sit'
            if (($script:t - $script:stateSince) -gt 120) { $script:state = 'idle' }
        }
        'question' {
            Set-Frame 'question'
            if (($script:t - $script:stateSince) -gt 4) { $script:state = 'idle' }
        }
        'sleep' {
            Set-Frame 'sleep'
        }
        'peek_left' {
            Set-Frame 'peek_left'
        }
        'peek_right' {
            Set-Frame 'peek_right'
        }
    }

    if ($script:debug -and ($script:t - $script:lastLog) -gt 3) {
        $script:lastLog = $script:t
        Log ("state={0} frame={1}" -f $script:state, $script:curFrame)
    }
})

$pet.Add_MouseLeftButtonDown({
    $script:dragging = $true
    Set-Frame 'held'
    $downX = $pet.Left
    $downY = $pet.Top
    try { $pet.DragMove() } catch { }
    $script:dragging = $false
    $movedX = [Math]::Abs($pet.Left - $downX)
    $movedY = [Math]::Abs($pet.Top - $downY)
    $script:lastInteract = $script:t
    if ($movedX -lt 4 -and $movedY -lt 4) {
        if ($script:state -like 'peek_*') {
            Show-Bubble ($clickLines | Get-Random)
        } else {
            Enter-State 'bounce'
            Set-Frame 'react'
            Show-Bubble ($clickLines | Get-Random)
        }
    } else {
        # 放手：贴边就扒着边界偷看，否则落地 Q 弹
        $scaler.ScaleX = 1
        $scaler.ScaleY = 1
        $leftGap = $pet.Left - $wa.Left
        $rightGap = $wa.Right - ($pet.Left + $pet.Width)
        if ($leftGap -lt 30) {
            $pet.Left = $wa.Left
            Enter-State 'peek_left'
            Set-Frame 'peek_left'
        } elseif ($rightGap -lt 30) {
            $pet.Left = $wa.Right - $pet.Width
            Enter-State 'peek_right'
            Set-Frame 'peek_right'
        } else {
            Enter-State 'land'
            Set-Frame 'idle'
        }
        if ($bubble.IsVisible) { Place-Bubble }
    }
})

$menu = New-Object System.Windows.Controls.ContextMenu
$say = New-Object System.Windows.Controls.MenuItem
$say.Header = '说句话'
$say.Add_Click({ $script:menuOpen = $false; Show-Bubble ($lines | Get-Random); $script:lastInteract = $script:t })
$work = New-Object System.Windows.Controls.MenuItem
$work.Header = '打字干活'
$work.Add_Click({ $script:menuOpen = $false; Enter-State 'type'; Set-Frame 'type'; $script:manualUntil = $script:t + 180 })
$rest = New-Object System.Windows.Controls.MenuItem
$rest.Header = '坐下歇会儿'
$rest.Add_Click({ $script:menuOpen = $false; Enter-State 'sit'; Set-Frame 'sit'; $script:manualUntil = $script:t + 180 })
$nap = New-Object System.Windows.Controls.MenuItem
$nap.Header = '睡一会儿'
$nap.Add_Click({ $script:menuOpen = $false; Enter-State 'sleep'; Set-Frame 'sleep'; $script:manualUntil = $script:t + 600 })
$top = New-Object System.Windows.Controls.MenuItem
$top.Header = '总在最前'
$top.IsCheckable = $true
$top.IsChecked = $true
$top.Add_Click({ $script:menuOpen = $false; $pet.Topmost = $top.IsChecked; $bubble.Topmost = $top.IsChecked })
$quit = New-Object System.Windows.Controls.MenuItem
$quit.Header = '退出'
$quit.Add_Click({
    $script:frameTimer.Stop()
    $script:hideTimer.Stop()
    $bubble.Close()
    $pet.Close()
})
$menu.Items.Add($say) | Out-Null
$menu.Items.Add($work) | Out-Null
$menu.Items.Add($rest) | Out-Null
$menu.Items.Add($nap) | Out-Null
$menu.Items.Add($top) | Out-Null
$menu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null
$menu.Items.Add($quit) | Out-Null
$img.ContextMenu = $menu
$menu.Add_Opened({ $script:menuOpen = $true; Set-Frame 'question'; Log 'menu opened' })
$menu.Add_Closed({
    $script:menuOpen = $false
    $script:lastInteract = $script:t
    Log 'menu closed'
})

$pet.Add_Loaded({ Log "loaded state=$($script:state) frame=$($script:curFrame) pos=$([int]$pet.Left),$([int]$pet.Top)" })
$pet.Add_Closed({ Log 'closed' })

$script:frameTimer.Start()
$pet.ShowDialog() | Out-Null
