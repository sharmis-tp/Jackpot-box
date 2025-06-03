compile:
	npx hardhat compile
deploy:
	rm -rf ignition/deployments && npx hardhat ignition deploy ignition/modules/Jackpotbox.ts --network etherlinkTestnet
	
verify:
	npx hardhat verify --network etherlinkTestnet $(ca) 0x23f0e8FAeE7bbb405E7A7C3d60138FCfd43d7509
