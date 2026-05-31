Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="AzerothCore Installer" Height="520" Width="720"
        WindowStartupLocation="CenterScreen">

    <Grid Margin="10">

        <TextBlock Name="StatusText"
                   Text="Ready"
                   VerticalAlignment="Top"
                   FontSize="14"
                   Height="30"/>

        <ProgressBar Name="Progress"
                     Height="20"
                     Margin="0,40,0,0"
                     Minimum="0" Maximum="100"/>

        <TextBox Name="LogBox"
                 Margin="0,80,0,60"
                 VerticalScrollBarVisibility="Auto"
                 HorizontalScrollBarVisibility="Auto"
                 AcceptsReturn="True"
                 TextWrapping="Wrap"/>

        <Button Name="StartButton"
                Content="Install AzerothCore"
                Height="35"
                Width="200"
                HorizontalAlignment="Left"
                VerticalAlignment="Bottom"/>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$StatusText = $window.FindName("StatusText")
$Progress = $window.FindName("Progress")
$LogBox = $window.FindName("LogBox")
$StartButton = $window.FindName("StartButton")

function Log($msg) {
    $LogBox.AppendText("`n$msg")
    $LogBox.ScrollToEnd()
}

function Set-Stage($text, $percent) {
    $StatusText.Text = $text
    $Progress.Value = $percent
    Log $text
}

# -------------------------
# INSTALL PIPELINE
# -------------------------
$StartButton.Add_Click({

    try {
        Set-Stage "Checking prerequisites..." 5

        if (!(Get-Command git -ErrorAction SilentlyContinue)) {
            throw "Git missing"
        }

        if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
            throw "Docker missing"
        }

        Set-Stage "Starting database (Docker)..." 10
        docker compose up -d
        Start-Sleep 10

        Set-Stage "Cloning core..." 25
        if (!(Test-Path ".\server\core")) {
            git clone $manifest.core.repo ".\server\core"
        }

        Set-Stage "Installing modules..." 40
        $modulesPath = ".\server\core\modules"

        foreach ($m in $manifest.modules.PSObject.Properties) {
            $target = "$modulesPath\$($m.Name)"
            if (!(Test-Path $target)) {
                git clone $m.Value $target
            }
        }

        Set-Stage "Building server (this takes time)..." 60

        cd ".\server\core"
        if (!(Test-Path "build")) {
            mkdir build
        }

        cd build
        cmake .. -DTOOLS=1 -DSCRIPTS=dynamic -DMODULES=static
        cmake --build . --config Release

        Set-Stage "Finalizing setup..." 85

        Set-Stage "Completed successfully" 100

        [System.Windows.MessageBox]::Show("Install complete! Use Play-WoW.bat")

    } catch {
        [System.Windows.MessageBox]::Show("ERROR: $_")
        Log "ERROR: $_"
    }

})

$window.ShowDialog() | Out-Null
