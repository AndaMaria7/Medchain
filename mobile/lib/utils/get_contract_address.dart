import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

void main() async {
  // Use the same private key as in your wallet service
  final privateKey = '0x02e00c7415385db8ee2603ddabc450c3266f68788077453d0057301ec3cc1d15';
  
  // Create credentials from private key
  final String formattedPk = privateKey.startsWith('0x') ? privateKey.substring(2) : privateKey;
  final credentials = EthPrivateKey.fromHex(formattedPk);
  
  // Get wallet address
  final address = await credentials.extractAddress();
  print('Wallet address: ${address.hex}');
  
  // Connect to Sepolia
  final rpcUrl = 'https://rpc.ankr.com/eth_sepolia';
  final web3client = Web3Client(rpcUrl, http.Client());
  
  // Get transaction count
  final txCount = await web3client.getTransactionCount(address);
  print('Transaction count: $txCount');
  
  // Get balance
  final balance = await web3client.getBalance(address);
  print('Balance: ${balance.getValueInUnit(EtherUnit.ether)} ETH');
  
  // Clean up
  web3client.dispose();
}
