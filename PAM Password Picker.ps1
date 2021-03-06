[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Timers")
[void][System.Reflection.Assembly]::LoadWithPartialName("System")


#region Constants
$CURRENT_DIRECTORY     = (Get-Location).Path
$CONFIGURATION_FILE    = $CURRENT_DIRECTORY+"\PAM Password Picker.xml"
[object]$PSPASMINVER   = @([PSCustomObject]@{Major = 5; Minor=2; Build = 52; Revision = -1})
#endregion


#region UI
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
        <Button Name="btnGet" Content="Fetch Password" HorizontalAlignment="Left" VerticalAlignment="Top" Height="38" Width="128" Grid.Row="2" Margin="33,16,0,0" Grid.RowSpan="2"/>
        <TextBox Name="txtBoxPassword" HorizontalAlignment="Left" Margin="72,16,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="126" Height="38" IsReadOnly="True" Grid.Row="2" Grid.Column="2" Text="Password" SelectionOpacity="0.1" Grid.RowSpan="2"/>
        <Label Name="lblReason" Content="Reason" HorizontalAlignment="Left" Margin="73,111,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.793,-0.23" Height="26" Width="48"/>
        <TextBox Name="txtBoxReason" HorizontalAlignment="Left" Margin="142,115,0,0" Text="Reason" TextWrapping="Wrap" VerticalAlignment="Top" Width="263" Grid.ColumnSpan="3" Height="18"/>
        <Button Name="btnCheckIn" Content="Account Check-In" HorizontalAlignment="Left" VerticalAlignment="Top" Height="38" Width="128" Grid.Row="3" Margin="33,30,0,0"/>
    </Grid>
</Window>

"@

#endregion

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
    [System.Windows.Forms.MessageBox]::Show("XML Configuration could not be loaded. `n Make sure the file " +  $CONFIGURATION_FILE + " exists in the script location", [System.Windows.Forms.MessageBoxIcon]::Error)
}

#region Install and load PSPAS module:

[bool]$isAdmin = $false
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()) #Get current user running the script
if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true)
{
    $isAdmin = $true  #Checks  current user has Admin rights to install the module
}
if((Get-Module -ListAvailable -Name psPAS) -eq $null) # check if the module isn't already installed; if not :
{
        if($isAdmin)
        {
            try
            {
                Find-Module -Name psPAS -MinimumVersion 5.2.54 | Install-Module -Force # Install the psPAS module with min required version
            }
            catch
            {
                [System.Windows.Forms.MessageBox]::Show('Unexpected error ocurred. Unable to load psPAS module. Please verify the module is installed and loaded or make sure internet connection is availabe to download and install it.', `
                'Module psPAS missing', `
                [System.Windows.Forms.MessageBoxButtons]::OK, `
                [System.Windows.Forms.MessageBoxIcon]::Error)
                exit
            }
        }
        else # Displays an error message that the module is missing and we need to have admin rights
        {
            [System.Windows.Forms.MessageBox]::Show('Powershell module psPAS is not installed. Please run the script as Administrator to install the required module', `
            'Module psPAS missing', `
            [System.Windows.Forms.MessageBoxButtons]::OK, `
            [System.Windows.Forms.MessageBoxIcon]::Error)
            exit
        }
}
else
{
    $modules = (Get-Module -ListAvailable -Name psPAS | Select-Object Version) # If a psPAS module is installed get the version of all installed psPAS modules (more than one can coexist)
    foreach($module in $modules)
    {
        if(-not (($modules.version.major -eq $PSPASMINVER.major) -and ($modules.version.minor -eq $PSPASMINVER.minor))) # if Major.Minor versions don't match
        {
            if($isAdmin -eq $true)
            {
                try
                {
                    Update-Module -Name psPAS -RequiredVersion 5.2.54 -Force
                }
                catch
                {
                    [System.Windows.Forms.MessageBox]::Show('Unexpected error ocurred. Unable to load psPAS module. Please verify the module is installed and loaded or make sure internet connection is availabe to download and install it.', `
                    'Module psPAS missing', `
                    [System.Windows.Forms.MessageBoxButtons]::OK, `
                    [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            else # Displays an error message that the module is missing and we need to be admin
            {
                [System.Windows.Forms.MessageBox]::Show('Powershell module psPAS is not installed. Please run the script as Administrator to install the required module', `
                'Module psPAS missing', `
                [System.Windows.Forms.MessageBoxButtons]::OK, `
                [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    }
}
#endregion


<# Get parameter values from the external configuration
$BaseURI = $xmlConfiguration.SelectSingleNode("//configuration/connection/BaseUrl/"
$BaseURI = $xmlConfiguration.configuration.connection.BaseUrl
authType = $xmlConfiguration.configuration.authentication.type
$logonUserName = $xmlConfiguration.configuration.authentication.username #>

                    # ACHTUNG! -->>> DELETE THESE CONNECTION STRINGS IN THE FINAL RELEASE <<<-- ACHTUNG
                    $password = ConvertTo-SecureString 'Gc0n21#' -AsPlainText -Force
                    $credential = New-Object System.Management.Automation.PSCredential ('APIUser', $password)



# ----- Establish a REST session to the PVWA server
try
{
    #New-PASSession -BaseURI $BaseURI -Credential $logonUserName -type $authType

    <# ACHTUNG! -->>> DELETE THESE CONNECTION STRINGS IN THE FINAL RELEASE <<<-- ACHTUNG      #>
    New-PASSession -BaseURI https://pvwa01.lab.test.local -Credential $credential -type CyberArk
}
catch
{
    [System.Windows.Forms.MessageBox]::Show('Unable to connect to the remote server', `
    'Connection Error',`
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Error)

    exit
}


$allSafes = Get-PASSafe -FindAll | Select-Object SafeName

$cboxSelectSafe.Add_DropDownOpened(
    {
        $cboxSelectSafe.items.Clear()
        foreach($safe in $allSafes)
        {
            $cboxSelectSafe.Items.Add($safe.SafeName)
        }
    }
)
[string]$pasAccount = $null
$cboxSelectSafe.add_SelectionChanged(
    {
        $txtBoxPassword.Clear()
        $global:selectedSafe = $cboxSelectSafe.SelectedItem
        $cboxSelectAccount.Items.Clear()
        if($selectedSafe -ne $null)
        {
            foreach($account in (Get-PASAccount -safeName $selectedSafe | Select-Object userName))
            {
                $cboxSelectAccount.Items.Add($account.userName)
            }
        }
    }
)


[string]$cboxSelectAccount.Add_SelectionChanged(
    {
        $txtBoxPassword.Clear()
        $global:pasAccount = $cboxSelectAccount.SelectedItem
        return $global:pasAccount
    }
)

$pasAccountID = $null

$btnGet.Add_Click(
    {

        [string]$reason = $txtBoxReason.Text # Reason provided in the text box
        [string]$platformID = $(Get-PASAccount | Where-Object {$_.username -eq $pasAccount}).platformID #plaftofm ID of the selected Account (needed to check if Reason is required)
        [bool]$reasonRequired = $(Get-PASPlatform | Where-Object {($_.PlatformID -eq $platformID) -and ($PSItem.details.PrivilegedAccessWorkflows.RequireUsersToSpecifyReasonForAccess.IsActive -eq $true)} | Select-Object {$PSItem.details.PrivilegedAccessWorkflows.RequireUsersToSpecifyReasonForAccess.IsActive}).'$PSItem.details.PrivilegedAccessWorkflows.RequireUsersToSpecifyReasonForAccess.IsActive'
        #checks if providing a reason is mandatory for the selected account platform policy

        if($reasonRequired -eq $true)
        {
            if([string]::IsNullOrEmpty($reason))
            {
                [System.Windows.MessageBox]::Show('Please enter a reason to proceed')
                return;
            }
        }
        if($pasAccount -ne $null)
        {
            $global:pasAccountID = $(Get-PASAccount | Where-Object {$_.username -eq $pasAccount}).id
            try
            {
                $password = $(Get-PASAccountPassword -AccountID $pasAccountID -Reason $reason).Password
                $txtBoxPassword.text = $password
                StartTimer;
                #return $global:pasAccountID
            }
            catch
            {
                [System.Windows.Forms.MessageBox]::Show('Unable to retrieve the password for the selected account', `
                'Something went wrong', `
                [System.Windows.Forms.MessageBoxButtons]::OK, `
                [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
        else
        {
            [System.Windows.Forms.MessageBox]::Show('Please Select Account', `
            'Account not selected', `
            [System.Windows.Forms.MessageBoxButtons]::OK, `
            [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
)

<#
-- Event listener
-- displays confirmation window
-- checks in the exclusive account using the pasAccountID value and closes the form.
#>
$Form.Add_Closing(
    {param($sender,$e)
            $result = [System.Windows.Forms.MessageBox]::Show(`
                "Are you sure you want to exit?", `
                "Close", [System.Windows.Forms.MessageBoxButtons]::YesNo, `
                [System.Windows.Forms.MessageBoxIcon]::Question)

            if($result -eq [System.Windows.Forms.DialogResult]::Yes)
            {
                if($pasAccountID -ne $null)
                {
                    Unlock-PASAccount -AccountID $pasAccountID
                }
            }
            else
            {
                $e.Cancel= $true
            }
    }
)
<#
Release account button onClick() event listener.
# -- clears textboxes
# -- checks in the exclusive account using the pasAccountID value
#>
$btnCheckIn.Add_Click(
    {
        #$pasAccount = $cboxSelectAccount.SelectedItem
        #$pasAccountID = $(Get-PASAccount | Where-Object {$_.username -eq $pasAccount}).id
        if($pasAccountID -ne $null)
        {
            $txtBoxPassword.Clear()
            $txtBoxReason.Clear()
            Unlock-PASAccount -AccountID $pasAccountID
        }
        else
        {
            [System.Windows.Forms.MessageBox]::Show('Please Select Account', `
            "Ooops", `
            [System.Windows.Forms.MessageBoxButtons]::OK, `
            [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
)

$Global:timer = New-Object System.Windows.Forms.Timer -Property @{
    Interval = $xmlConfiguration.configuration.policy.MinValidityPeriod -as [int]
}
$timer.Add_Tick({
    Unlock-PASAccount -AccountID $Global:pasAccountID
    $timer.Stop()
})

function StartTimer()
{
    $timer.Start()
}
#show the dialog
$Form.ShowDialog() | out-null