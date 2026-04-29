
$NicName=""
$NicRG=""

$results=Get-AzEffectiveRouteTable -NetworkInterfaceName $NicName -ResourceGroupName $NicRG
$results | ft AddressPrefix,NextHopIpAddress,NextHopType  