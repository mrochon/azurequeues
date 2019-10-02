Connect-AzAccount
Get-AzLocation | select Location
$location = "centralus"
$resourceGroup = "sugarsus"
New-AzResourceGroup -ResourceGroupName $resourceGroup -Location $location
# Create storage account
$storageAccountName = "sugarsusdata"
$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name $storageAccountName `
  -Location $location `
  -SkuName Standard_LRS

$ctx = $storageAccount.Context

#create a queue
$queueName = "observations"
$queue = New-AzStorageQueue –Name $queueName -Context $ctx

# Retrieve a specific queue
$queue = Get-AzStorageQueue –Name $queueName –Context $ctx
# Show the properties of the queue
$queue

# Retrieve all queues and show their names
Get-AzStorageQueue -Context $ctx | select Name