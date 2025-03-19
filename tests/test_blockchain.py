import pytest
from unittest.mock import patch, MagicMock
from app.blockchain import PolygonClient

@pytest.fixture
def polygon_client():
    return PolygonClient()

def test_get_block_number(polygon_client):
    with patch('requests.post') as mock_post:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "jsonrpc": "2.0",
            "id": 2,
            "result": "0x134e82a"
        }
        mock_post.return_value = mock_response
        
        result = polygon_client.get_block_number()
        assert result == "0x134e82a"
        
        called_args = mock_post.call_args[1]
        payload = called_args["data"]
        assert '"method": "eth_blockNumber"' in payload

def test_get_block_by_number(polygon_client):
    with patch('requests.post') as mock_post:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "jsonrpc": "2.0",
            "id": 2,
            "result": {
                "number": "0x134e82a",
                "hash": "0x1234567890abcdef",
                "transactions": []
            }
        }
        mock_post.return_value = mock_response
        
        result = polygon_client.get_block_by_number("0x134e82a", True)
        assert result["number"] == "0x134e82a"
        
        called_args = mock_post.call_args[1]
        payload = called_args["data"]
        assert '"method": "eth_getBlockByNumber"' in payload
        assert '"params": ["0x134e82a", true]' in payload.replace(" ", "")

def test_request_error(polygon_client):
    with patch('requests.post') as mock_post:
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.text = "Internal Server Error"
        mock_post.return_value = mock_response
        
        with pytest.raises(Exception) as excinfo:
            polygon_client.get_block_number()
        assert "Request failed with status code 500" in str(excinfo.value)

def test_rpc_error(polygon_client):
    with patch('requests.post') as mock_post:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "jsonrpc": "2.0",
            "id": 2,
            "error": {
                "code": -32000,
                "message": "Invalid parameters"
            }
        }
        mock_post.return_value = mock_response
        
        with pytest.raises(Exception) as excinfo:
            polygon_client.get_block_number()
        assert "RPC error" in str(excinfo.value) 