// const ServiceReceiver = artifacts.require("ServiceReceiver");

// module.exports = function (deployer) {
//   deployer.deploy(ServiceReceiver);
// };

// Deployment of Raini Token

// const StandardERC20 = artifacts.require('StandardERC20')

// module.exports = function (deployer) {
//     deployer.deploy(StandardERC20,
//       "Rainicorn",
//       "RAINI",
//       "18",
//       "10000000000000000000000",
//       "0x717B6711Ae2f9910daf824dC5b10dCCDDBB4115f",
//       {value : '100000000000000000'}  
//     );
// }

// Deployment of UNI-V2 Token

const UNI = artifacts.require('UniswapV2ERC20')

module.exports = function(deployer){
  deployer.deploy(UNI)
}
