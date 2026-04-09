from fastapi import HTTPException, status
import re

async def check_prompt_injection(user_input: str):
    """
    Heuristic-based middleware to detect jailbreaks or prompt injection attacks
    before they reach the Planner Agent.
    """
    blacklist_patterns = [
        r"ignore previous instructions",
        r"you are no longer aura",
        r"system prompt:",
        r"forget your rules",
        r"disregard",
        r"drop table", 
        r"delete from"
    ]
    
    user_input_lower = user_input.lower()
    for pattern in blacklist_patterns:
        if re.search(pattern, user_input_lower):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="AURA Security: Malicious intent detected. Request blocked."
            )
            
def verify_jwt_token(token: str):
    """
    Decodes the JWT to ensure the requesting user is authorized.
    Extracts the user's role (admin vs standard resident) to enforce RBAC.
    """
    # Mock JWT verification
    if token == "invalid":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token."
        )
    return {"user_id": 1, "role": "admin", "priorities": "Investment & High ROI"}
