from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

@patch("app.main.polygon_client.get_block_number")
def test_get_block_number(mock_get_block_number):
    mock_get_block_number.return_value = "0x134e82a"
    
    response = client.get("/block/number")
    assert response.status_code == 200
    assert response.json() == {"block_number": "0x134e82a"}

@patch("app.main.polygon_client.get_block_by_number")
def test_get_block_by_number(mock_get_block_by_number):
    mock_block = {
        "number": "0x134e82a",
        "hash": "0x1234567890abcdef",
        "transactions": []
    }
    mock_get_block_by_number.return_value = mock_block
    
    response = client.post(
        "/block/by-number",
        json={"block_number": "0x134e82a", "include_transactions": True}
    )
    assert response.status_code == 200
    assert response.json() == mock_block

@patch("app.main.polygon_client.get_block_by_number")
def test_get_block_by_number_not_found(mock_get_block_by_number):
    mock_get_block_by_number.return_value = None
    
    response = client.post(
        "/block/by-number",
        json={"block_number": "0x999999", "include_transactions": True}
    )
    assert response.status_code == 404
    assert "Block not found" in response.json()["detail"]

@patch("app.main.polygon_client.get_block_by_number")
def test_get_block_by_number_error(mock_get_block_by_number):
    mock_get_block_by_number.side_effect = Exception("RPC error")
    
    response = client.post(
        "/block/by-number",
        json={"block_number": "0x134e82a", "include_transactions": True}
    )
    assert response.status_code == 500
    assert "RPC error" in response.json()["detail"] 