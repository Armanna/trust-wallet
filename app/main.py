from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Union, Dict, List, Any
from app.blockchain import PolygonClient
from app.config import API_PORT
import uvicorn

app = FastAPI(
    title="Polygon Blockchain Client",
    description="A simple client for interacting with the Polygon blockchain",
    version="0.1.0"
)

polygon_client = PolygonClient()

class BlockNumberResponse(BaseModel):
    block_number: str

class GetBlockByNumberRequest(BaseModel):
    block_number: str = Field(..., description="Block number in hex format (e.g., '0x134e82a')")
    include_transactions: bool = Field(True, description="Whether to include full transaction details")

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "ok"}

@app.get("/block/number", response_model=BlockNumberResponse)
def get_block_number():
    """Get the current block number from the Polygon network"""
    try:
        block_number = polygon_client.get_block_number()
        return {"block_number": block_number}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/block/by-number")
def get_block_by_number(request: GetBlockByNumberRequest):
    """Get block details by block number"""
    try:
        block = polygon_client.get_block_by_number(
            request.block_number, 
            request.include_transactions
        )
        if not block:
            raise HTTPException(status_code=404, detail="Block not found")
        return block
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=API_PORT, reload=False) 