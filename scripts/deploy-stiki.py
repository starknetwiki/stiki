# scripts/deploy-stiki.py
import os
import sys
from nile.nre import NileRuntimeEnvironment

sys.path.append(os.path.dirname(__file__))
from utils import prepare_nile_deploy


def run(nre: NileRuntimeEnvironment):
    print("Deploying Stiki contract…")
    prepare_nile_deploy()

    admin = nre.get_or_deploy_account("PKEYADMIN")
    owner = admin.address
    params = [owner]
    address, abi = nre.deploy(
        "stiki",
        params,
        overriding_path=("build", "build"))
    print(f"ABI: {abi},\nStiki contract address: {address}")
