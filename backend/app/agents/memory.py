import json
from typing import Dict, Any

class MemoryAgent:
    """
    Independent agent responsible for context retention.
    Mocked internally with a dictionary if Redis is offline during dev.
    """
    def __init__(self):
        self._mock_memory = {}
        
    def save_context(self, session_id: str, key: str, value: Any):
        """Saves dynamic context like 'last_viewed_property'"""
        if session_id not in self._mock_memory:
            self._mock_memory[session_id] = {}
        self._mock_memory[session_id][key] = value
        print(f"[Memory Agent] Saved Context -> {key}: {value}")
        
    def get_context(self, session_id: str, key: str) -> Any:
        """Retrieves context to resolve questions like 'what about its permits'"""
        val = self._mock_memory.get(session_id, {}).get(key)
        print(f"[Memory Agent] Retrieved Context -> {key}: {val}")
        return val

# Singleton instance
memory = MemoryAgent()
