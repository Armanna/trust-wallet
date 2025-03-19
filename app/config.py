import os

# Configuration
POLYGON_RPC_URL = os.getenv("POLYGON_RPC_URL", "https://polygon-rpc.com/")
API_PORT = int(os.getenv("API_PORT", "8000")) 