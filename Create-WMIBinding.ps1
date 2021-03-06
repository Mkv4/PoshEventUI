Param (
    [string]$Computername = $Env:Computername,
    [object]$Filter = (Get-WMIObject -Computername $Computername -Namespace root\Subscription -Class __EventFilter | Sort Name),
    [object]$Consumer = (Get-WMIObject -Computername $Computername -Namespace root\Subscription -Class __EventConsumer | Sort Name)
)

#Build the GUI
[xml]$Binding_xaml = @"
<Window
    xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
    xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
    x:Name='Window' Title='New WMI Event Consumer Binding on $Computername' WindowStartupLocation = 'CenterScreen' 
    SizeToContent = 'Height' Width = '550' ShowInTaskbar = 'True' ResizeMode = 'Noresize'>
        <Window.Background>
            <LinearGradientBrush StartPoint='0,0' EndPoint='0,1'>
                <LinearGradientBrush.GradientStops> <GradientStop Color='#C4CBD8' Offset='0' /> <GradientStop Color='#E6EAF5' Offset='0.2' /> 
                <GradientStop Color='#CFD7E2' Offset='0.9' /> <GradientStop Color='#C4CBD8' Offset='1' /> </LinearGradientBrush.GradientStops>
            </LinearGradientBrush>
        </Window.Background> 
    <Grid x:Name = 'Grid' ShowGridLines = 'False'>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="5"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="5"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="5"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height = 'Auto'/>
            <RowDefinition Height = 'Auto'/>
            <RowDefinition Height = '10'/>
            <RowDefinition Height = '*'/>
            <RowDefinition Height = 'Auto'/>
        </Grid.RowDefinitions>    
        <Label Content='Filter' Grid.Column = '1' Grid.Row = '0' HorizontalAlignment = 'Center' 
            FontWeight = 'Bold' FontSize = '12'/>
        <Label Content='Consumer' Grid.Column = '3' Grid.Row = '0' HorizontalAlignment = 'Center' 
            FontWeight = 'Bold' FontSize = '12'/>   
        <ComboBox x:Name = 'FilterComboBox' Grid.Column = '1' Grid.Row = '1' IsReadOnly = 'True' SelectedIndex='0'/>  
        <ComboBox x:Name = 'ConsumerComboBox' Grid.Column = '3' Grid.Row = '1' IsReadOnly = 'True' SelectedIndex='0'/>          
        <TextBox x:Name = 'StatusTextbox' Grid.Row = '4' Grid.ColumnSpan = '5' IsReadOnly = 'True'>       
            <TextBox.Background>
                <LinearGradientBrush StartPoint='0,0' EndPoint='0,1'>
                    <LinearGradientBrush.GradientStops> <GradientStop Color='#C4CBD8' Offset='0' /> <GradientStop Color='#E6EAF5' Offset='0.2' /> 
                    <GradientStop Color='#CFD7E2' Offset='0.9' /> <GradientStop Color='#C4CBD8' Offset='1' /> </LinearGradientBrush.GradientStops>
                </LinearGradientBrush>
            </TextBox.Background>         
        </TextBox> 
        <Grid Grid.Row = '3' Grid.Column = '3' ShowGridLines = 'False'>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="5"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition Height = '5'/>       
                <RowDefinition Height = 'Auto'/>  
            </Grid.RowDefinitions>   
            <Button x:Name = 'CreateButton' Content ='Create' Grid.Column = '0' Grid.Row = '1' MaxWidth = '125' IsDefault = 'True'/>       
            <Button x:Name = 'CancelButton' Content = 'Cancel' Grid.Column = '2' Grid.Row = '1' MaxWidth = '125' IsCancel = 'True'/>       
        </Grid>              
    </Grid>   
</Window>
"@ 

$reader=(New-Object System.Xml.XmlNodeReader $Binding_xaml)
$Global:Binding_Window=[Windows.Markup.XamlReader]::Load( $reader )

##Connect To Controls
$FilterComboBox = $Binding_Window.FindName('FilterComboBox')
$ConsumerComboBox = $Binding_Window.FindName('ConsumerComboBox')
$CreateButton = $Binding_Window.FindName('CreateButton')

##Events
$Binding_Window.Add_Loaded({
    $Filter | ForEach {
        $FilterComboBox.Items.Add($_.Name) | Out-Null
    }
    $Consumer | ForEach {
        $ConsumerComboBox.Items.Add($_.Name) | Out-Null
    }
})

$CreateButton.Add_Click({
    $instanceBinding = ([wmiclass]"\\$Computername\root\subscription:__FilterToConsumerBinding").CreateInstance()
    
    #Get Filter
    $filterToBind = $Filter | Where {
        $_.Name -eq $FilterComboBox.Text
    }

    #Get Consumer
    $consumerToBind = $Consumer | Where {
        $_.Name -eq $ConsumerComboBox.Text
    }
    $instanceBinding.Filter = $filterToBind
    $instanceBinding.Consumer = $consumerToBind
    $instanceBinding.Put()

    $Binding_Window.DialogResult = $True
    $Binding_Window.Close()
})

$Binding_Window.ShowDialog()
