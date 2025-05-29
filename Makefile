deploy:
	rm -rf ignition/deployments && npx hardhat ignition deploy ignition/modules/Jackpotbox.ts --network etherlinkTestnet
	
verify:
	npx hardhat verify --network etherlinkTestnet $(ca)
