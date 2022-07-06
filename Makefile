.PHONY: build test deploy

build:
	protostar build

test:
	protostar test

deploy:
	nile run ./scripts/deploy-stiki.py --network goerli
