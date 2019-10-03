Connect-AzAccount
Get-AzLocation | select Location

$subscriptionId = "b63a13ff-9687-48e5-83bc-81d818f8f12c"
$location = "centralus"
$resourceGroup = "sugarsus"
$queueName = "observations"
$storageAccountName = "sugarsusdata"

# Create queue
    New-AzResourceGroup -ResourceGroupName $resourceGroup -Location $location
    # Create storage account
    $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup `
      -Name $storageAccountName `
      -Location $location `
      -SkuName Standard_LRS
    $ctx = $storageAccount.Context
    #create a queue
    $queue = New-AzStorageQueue –Name $queueName -Context $ctx


Get-AzRoleDefinition | FT Name, Description

# Create receiver
    connect-azuread
    $sp = New-AzADServicePrincipal -DisplayName "SugarsUSReceiver" 
    $cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\CurrentUser\My" -Subject "CN=sugarsus-receiver" -KeySpec KeyExchange
    $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
    New-AzureADServiceprincipalKeyCredential -ObjectId $sp.Id -CustomKeyIdentifier "Key2" -Type AsymmetricX509Cert -Usage Verify -Value $keyValue -EndDate "2020-01-01"
    $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName/queueServices/default/queues/$queueName"
    New-AzRoleAssignment -ApplicationId $sp.ApplicationId `
        -RoleDefinitionName "Storage Queue Data Reader" `
        -Scope  $scope


# Create sender (no key)
    connect-azuread
    $sp = New-AzADServicePrincipal -DisplayName "SugarsUSSender" 
    $scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName/queueServices/default/queues/$queueName"
	Import-Certificate -FilePath c:\signingkey.cer -CertStoreLocation "Cert:\CurrentUser\My"
	#Change to the location of the personal certificates
	Set-Location Cert:\CurrentUser\My
	Get-ChildItem | Format-Table Subject, FriendlyName, Thumbprint -AutoSize
	foreach($cert in Get-ChildItem) {
		if ($cert.Subject.startsWith('CN=sugars-sender')) {
			break
		}
	}
	New-AzureADServiceprincipalKeyCredential -ObjectId $sp.Id -CustomKeyIdentifier "Key1" -Type AsymmetricX509Cert -Usage Verify -Value $keyValue -EndDate "2020-01-01"
    New-AzRoleAssignment -ApplicationId $sp.ApplicationId `
        -RoleDefinitionName "Storage Queue Data Message Sender" `
        -Scope  $scope

#
# Create sender key (on sender computer)
#
    $cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\CurrentUser\My" -Subject "CN=sugarsus-sender2" -KeySpec KeyExchange
    $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
	Export-Certificate -Cert $cert -FilePath c:\signingkey.cer

