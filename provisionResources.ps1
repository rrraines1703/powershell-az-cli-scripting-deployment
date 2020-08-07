# TODO: set variables
$studentName = "rain"
$rgName = "$studentName-0820-ps-rg"
$vmName = "$studentName-0820-ps-vm"
$vmSize = "Standard_B2s"
$vmImage = "Canonical:UbuntuServer:18.04-LTS:latest"
$vmAdminUsername = "student"
$vmAdminPassword = 'LaunchCode-@zure1'
$kvName = "$studentName-lc0820-ps-kv"
$kvSecretName = 'ConnectionStrings--Default'
$kvSecretValue = 'server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode'

# set az location default
az configure --default location=eastus

# TODO: provision RG
az group create -n "$rgName" | Set-Content rg.json
az configure --default group=$rgName

# TODO: provision VM
az vm create -n $vmName --size $vmSize --image $vmImage --admin-username $vmAdminUsername --admin-password $vmAdminPassword --authentication-type password --assign-identity | Set-Content vm.json
az configure --default vm=$vmName
$vm = Get-Content vm.json | ConvertFrom-json

# TODO: capture the VM systemAssignedIdentity
$vmId = $vm.identity.systemAssignedIdentity
$vmIp = $vm.publicIpAddress

# TODO: open vm port 443
az vm open-port --port 443

# provision KV

az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true | Set-Content kv.json

# TODO: create KV secret (database connection string)
az keyvault secret set --vault-name $kvName --description 'connection string' --name $kvSecretName --value $kvSecretValue

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)
az keyvault set-policy --name $kvName --object-id $vmId --secret-permissions list get

#Deploy
az vm run-command invoke --command-id RunShellScript --scripts '@.\vm-configuration-scripts\1configure-vm.sh' '@.\vm-configuration-scripts\2configure-ssl.sh' '@deliver-deploy.sh'

# TODO: print VM public IP address to STDOUT or save it as a file
Write-Output "VM available at $vmIp"