# $passsword = $(Get-PASAccountPassword -id $(Get-PASAccount | Where-Object {$_.username -eq "CCPDBAuth01"}).id -Reason "REST TEST").Password
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
#Add-Type -AssemblyName PresentationFramework


#region Constants
$CURRENT_DIRECTORY     = (Get-Location).Path
$CONFIGURATION_FILE    = $CURRENT_DIRECTORY+"\PAM Password Picker.xml"
$SCHEMA_FILE           = $CURRENT_DIRECTORY+"\PAM Password Picker.xsd"
#endregion

[xml]$XAML = @"

<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:PAM_Password_Picker"

        Title="PAM Password Picker" Height="333" Width="450" ResizeMode="NoResize" Topmost="True">
    <Grid Margin="0,0,10,-6">
        <Grid.RowDefinitions>
            <RowDefinition Height="165*"/>
            <RowDefinition Height="12*"/>
            <RowDefinition Height="38*"/>
            <RowDefinition Height="108*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="225*"/>
            <ColumnDefinition Width="34*"/>
            <ColumnDefinition Width="292*"/>
        </Grid.ColumnDefinitions>
        <Label Name="lblSelectSafe" Content="Select Safe" HorizontalAlignment="Left" Margin="63,23,0,0" VerticalAlignment="Top" Height="26" Width="67"/>
        <Label Name="lblSelectAccount" Content="Select Account" HorizontalAlignment="Left" Margin="42,0,0,0" VerticalAlignment="Center" Height="26" Width="88"/>
        <ComboBox Name="cboxSelectSafe" Grid.ColumnSpan="3" HorizontalAlignment="Left" Margin="142,25,0,0" VerticalAlignment="Top" Width="266" Height="22"/>
        <ComboBox Name="cboxSelectAccount" Grid.ColumnSpan="3" HorizontalAlignment="Left" Margin="142,0,0,0" VerticalAlignment="Center" Width="263" Height="22"/>
        <Button Name="btnGet" Content="Fetch Password" HorizontalAlignment="Left" VerticalAlignment="Top" Height="38" Width="128" Grid.Row="3" Margin="33,30,0,0"/>
        <TextBox Name="txtBoxPassword" HorizontalAlignment="Left" Margin="72,30,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="126" Height="38" IsReadOnly="True" Grid.Row="3" Grid.Column="2" Text="Password" SelectionOpacity="0.1"/>
        <Label Name="lblReason" Content="Reason" HorizontalAlignment="Left" Margin="73,111,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.793,-0.23" Height="26" Width="48"/>
        <TextBox Name="txtBoxReason" HorizontalAlignment="Left" Margin="142,115,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="263" Grid.ColumnSpan="3" Height="18"/>
    </Grid>
</Window>

"@
#Read XAML
[object]$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Form=[Windows.Markup.XamlReader]::Load($reader)

# Store Form Objects In PowerShell
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

#Read XML Config
try
{
    [xml]$xmlConfiguration = Get-Content -Path $CONFIGURATION_FILE -ErrorAction 'Stop'
}
catch
{
    [System.Windows.MessageBox]::Show("XML Configuration could not be loaded. \n Make sure the file " +  $CONFIGURATION_FILE + " exists in the script location")
}


# Get parameter values from the external configuration
#$BaseURI = $xmlConfiguration.SelectSingleNode("//configuration/connection/BaseUrl/"
$BaseURI = $xmlConfiguration.configuration.connection.BaseUrl
$authType = $xmlConfiguration.configuration.authentication.type
$logonUserName = $xmlConfiguration.configuration.authentication.username


#$password = ConvertTo-SecureString 'Gc0n21#' -AsPlainText -Force

#$credential = New-Object System.Management.Automation.PSCredential ('APIUser', $password)

New-PASSession -BaseURI $BaseURI -Credential $logonUserName -type $authType
#New-PASSession -BaseURI https://pvwa01.lab.test.local -Credential $(Get-Credential) -type CyberArk

$allSafes = Get-PASSafe -FindAll | Select-Object SafeName

[string]$pasAccount = $null


foreach($safe in $allSafes)
{
    $cboxSelectSafe.Items.Add($safe.SafeName)
}

$cboxSelectSafe.add_SelectionChanged(
    {
        $selectedSafe = $cboxSelectSafe.SelectedItem
        $cboxSelectAccount.Items.Clear()

        foreach($account in (Get-PASAccount -safeName $selectedSafe | Select-Object userName))
        {
            $cboxSelectAccount.Items.Add($account.userName)
        }
    }
)
$pasaccountID = $null
$cboxSelectAccount.add_SelectionChanged(
    {

    }
)
$btnGet.add_Click(
    {
        $pasAccount = $cboxSelectAccount.SelectedItem
        [string]$reason = $txtBoxReason.Text
        if([string]::IsNullOrEmpty($reason))
        {
            [System.Windows.MessageBox]::Show('Please enter reason to proceed')
            return;
        }
        if(($pasAccount -ne $null) -or ($pasAccount -ne ""))
        {
            $pasaccountID = $(Get-PASAccount | Where-Object {$_.username -eq $pasAccount}).id
            try
            {

                $password = $(Get-PASAccountPassword -AccountID $pasaccountID -Reason $reason).Password
                $txtBoxPassword.text = $password
            }
            catch
            {
                Write-Host "Error Stuff"
            }
        }
    }
)


function Get-PlatformID
{
    $plaformID = $(Get-PASAccount | Where-Object {$_.username -eq $pasAccount}).platformID
}

function [bool]ReasonMandatory()
{

}
#show the dialog
$Form.ShowDialog() | out-null