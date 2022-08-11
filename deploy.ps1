#"First, connect to you Vcenter server"

#$adm = "administrator@vsphere.local"

#$pass = "687#fdk*RR_"

#connect-viserver -server 192.168.51.5 -Protocol https -User $adm -Password $pass  

#Get-VM | fl "the fl flag makes it give the full information"
function testvm(){


    #"^ Always good to check if you're connected to the proper server with a Get-VM command."
    if (get-template win10temp1){
        write-host "Gaming started...."
    }else {
        New-Template -VM (get-VM win10) -Name "win10temp1" -Datastore 'synHA' -Location '192.168.51.101'
    }

    #"This command copies a template from a pre-existing machine. Golden Image"

    New-OSCustomizationSpec -Name 'win10CLI' -FullName 'TestName' -OrgName 'MyCompany' -OSType Windows -ChangeSid -AdminPassword (Read-Host -AsSecureString) -Domain 'Dranger.zone' -TimeZone 035 -DomainCredentials (Get-Credential) -AutoLogonCount 1

    #"This command comes directly after the new template command, and it allows you to customize the golden image deploy in order to change things such as admin password, domaine, time zone, etc."

    $Specs = Get-OSCustomizationSpec -Name 'win10CLI'

    $Template = Get-Template -Name 'win10temp1'

    #"With these commands, you save the specs and template as ps1 variables in order to simplify and dynamicize the deployment process."

    New-VM -Name 'win10CLI' -Template $Template -OSCustomizationSpec $Specs -VMHost ‘192.168.51.107' -Datastore 'synHA’ -DiskStorageFormat Thin

    #"Finally, this command will take everything and make the new vm and deploy it."
}

function get_config([string] $config_path){
    #write-host "Using config from:"$config_path
    $global:config = (Get-Content $config_path) | ConvertFrom-Json
    if  (!$global:config.vcenter_server){ write-host -f yellow "Config file invalid, exiting"; exit }
}

#Dynamic version
function cloner1 () {
    Remove-Item /home/sam/Documents/nameinventory.txt
    #New-Item ./nameinventory.txt
    #Set-Content ./nameinventory.txt "[Hosts]"
    #$vcenter_server = Read-Host -Prompt "(1): Ok, imma need the IP of the Vcenter server that we are connecting to. Please type it here:"
    $vm_host = "192.168.51.101"    # Read-Host -Prompt "(2): What VM host are we putting this on? Please type it here:"
    $datastore = "synHA" #Read-Host -Prompt "(3): Ok, now what datastore are we assigning to this machine? Please type it here:"
    $dest_network = "VM Network" # Read-Host -Prompt "(4): What network do you want this to be assigned to? Please type it here:"
    $dest_folder = "base" #Read-Host -Prompt "(5): What base folder we putting this on? Please type it here:"
    $snapshot = "base" #Read-Host -Prompt "(6): What is the name of the snapshot that we will be copying? Please type it here:"
    $target_vm = "Win10" #Read-Host -Prompt "(7): What is the target VM to copy? Please type it here:"
    $count = 1 #Read-Host -Prompt "(8): How many times do you want to copy the machine? Please type it here:"
    $dest_name = Read-Host -Prompt "What would you like to name this VM? Please type it here:"
    $namecount = 0

    for ($var = 1; $var -le $count; $var++){
        $namecount++
        $dest_name1 = $dest_name + [string]$namecount
        $vm_host = Get-VMHost -Name $vm_host
        $datastore = Get-Datastore -Name $datastore
        $dest_folder = Get-Folder -Name $dest_folder
        $target_vm = Get-VM $target_vm
        $snap = Get-Snapshot -VM $target_vm -Name $snapshot
        $global:new_vm = New-VM -Name $dest_name1 -VM $target_vm -LinkedClone -ReferenceSnapshot $snap -VMHost $vm_host -Datastore $datastore -Location $dest_folder
        $global:new_vm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $dest_network -Confirm:$false
        Start-VM -VM $dest_name1
        $dest_name1 | out-file -filepath ./nameinventory.txt -append
        #(Get-VM $dest_name1).Guest.IPAddress | out-file -append -filepath ./inventory.txt 
        #if ((Get-VM $dest_name1).Guest.IPAddress){
         #   (Get-VM $dest_name1).Guest.IPAddress | out-file -append -filepath ./inventory.txt 
         #   echo "it worked"
       
        #else
          #  echo "not available"
        # }
       
        
        
        
    }
    Read-Host "Your meal has been served. Thank you for choosing the LCDI."
}
    
function inventorygen(){
    Remove-Item /home/sam/Documents/ipinventory.txt
    write-host "grabbing Ips, please wait this takes around 30 seconds. "
    Start-Sleep -Seconds 30 
    $hostnames = Get-Content -Path /home/sam/Documents/nameinventory.txt
    ForEach ($name in $hostnames) {
        write-host $name
        get-vm $name 
        $nadap = Get-NetworkAdapter -VM $name
        Write-Host $nadap.MacAddress
        $ip = (Get-VM $name).Guest.IPAddress[0] 
        write-host $ip + "check"
        $ip | out-file -append -filepath /home/sam/Documents/ipinventory.txt
    }
    #(Get-VM $).Guest.IPAddress[0] | out-file -append -filepath ./inventory.txt 
}
   

#Ryan's Cloner (OP) STATIC BASED ON CONFIG FILE
function cloner2($target_vm, $dest_name, $dest_network, $dest_folder){
    $vm_host = Get-VMHost -Name $global:config.vm_host
    $datastore = Get-Datastore -Name $global:config.datastore
    $dest_folder = Get-Folder -Name $dest_folder
    $target_vm = Get-VM $target_vm
    $snap = Get-Snapshot -VM $target_vm -Name $global:config.snapshot
    $global:new_vm = New-VM -Name $dest_name -VM $target_vm -LinkedClone -ReferenceSnapshot $snap -VMHost $vm_host -Datastore $datastore -Location $dest_folder
    $global:new_vm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $dest_network -Confirm:$false
}

function setup(){
    get_config("./deploycfg.json")
    #connect_esxi
}

setup
#cloner2 -target_vm "Win10" -dest_name "wks1" -dest_network "VM Network" -dest_folder "Leahy"
cloner1
inventorygen

#ansible-playbook ./network.yml 