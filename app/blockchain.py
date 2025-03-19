import requests
import json
from app.config import POLYGON_RPC_URL

class PolygonClient:
    def __init__(self, rpc_url=POLYGON_RPC_URL):
        self.rpc_url = rpc_url
        self.headers = {
            "Content-Type": "application/json"
        }
        
    def _make_request(self, method, params=None):
        """Make a JSON-RPC request to the Polygon network"""
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "id": 2
        }
        
        if params:
            payload["params"] = params
            
        response = requests.post(
            self.rpc_url,
            headers=self.headers,
            data=json.dumps(payload)
        )
        
        if response.status_code != 200:
            raise Exception(f"Request failed with status code {response.status_code}: {response.text}")
            
        result = response.json()
        if "error" in result:
            raise Exception(f"RPC error: {result['error']}")
            
        return result.get("result")
    
    def get_block_number(self):
        """Get the current block number from the Polygon network"""
        return self._make_request("eth_blockNumber")
    
    def get_block_by_number(self, block_number, include_transactions=True):
        """Get block details by block number
        
        Args:
            block_number: Block number in hex format (e.g., "0x134e82a")
            include_transactions: Whether to include full transaction details
        """
        return self._make_request("eth_getBlockByNumber", [block_number, include_transactions]) 