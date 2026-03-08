import subprocess
import sys

imports = [
    (
        "module.networking.azurerm_subnet.database",
        "/subscriptions/43d04a59-a943-43a9-9364-7120c9d57bd1/resourceGroups/mlops3tier-dev-rg/providers/Microsoft.Network/virtualNetworks/mlops3tier-dev-pset49-vnet/subnets/mlops3tier-dev-pset49-db",
    ),
    (
        "module.networking.azurerm_network_security_group.public",
        "/subscriptions/43d04a59-a943-43a9-9364-7120c9d57bd1/resourceGroups/mlops3tier-dev-rg/providers/Microsoft.Network/networkSecurityGroups/mlops3tier-dev-pset49-public-nsg",
    ),
    (
        "module.networking.azurerm_private_dns_zone_virtual_network_link.postgres",
        "/subscriptions/43d04a59-a943-43a9-9364-7120c9d57bd1/resourceGroups/mlops3tier-dev-rg/providers/Microsoft.Network/privateDnsZones/mlops3tier-dev-pset49.postgres.database.azure.com/virtualNetworkLinks/mlops3tier-dev-pset49-pg-dns-link",
    ),
]

def run(cmd):
    print("\n>>>", " ".join(cmd))
    result = subprocess.run(cmd, text=True)
    if result.returncode != 0:
        print(f"\nFAILED: {' '.join(cmd)}")
        sys.exit(result.returncode)

def state_has(address):
    result = subprocess.run(
        ["terraform", "state", "show", address],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    return result.returncode == 0

def main():
    print("Checking Terraform state and importing missing resources...\n")

    for address, resource_id in imports:
        if state_has(address):
            print(f"[SKIP] Already in state: {address}")
            continue

        run(["terraform", "import", address, resource_id])

    print("\nDone.")
    print("Now run:")
    print("  terraform plan")

if __name__ == "__main__":
    main()
