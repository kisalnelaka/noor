import os
import httpx
import json
from typing import List, Dict, Any

class LLMProvider:
    """ Unified Provider for Free Intelligence (Groq / Gemini) """
    
    def __init__(self):
        # 🔑 Keys should be in .env. We'll provide placeholders.
        self.groq_key = os.getenv("GROQ_API_KEY", "")
        self.gemini_key = os.getenv("GEMINI_API_KEY", "")
        self.use_groq = bool(self.groq_key)
        
    async def chat(self, messages: List[Dict[str, str]], model: str = "llama-3.3-70b-versatile") -> str:
        if self.use_groq:
            return await self._call_groq(messages, model)
        elif self.gemini_key:
            return await self._call_gemini(messages)
        else:
            # Fallback for Development (Self-Correction / Mock)
            return "I'm currently in basic mode. Please provide a Groq or Gemini API key in the .env file to activate my high-fidelity brain."

    async def _call_groq(self, messages: List[Dict[str, str]], model: str) -> str:
        url = "https://api.groq.com/openai/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.groq_key}",
            "Content-Type": "application/json"
        }
        data = {
            "model": model,
            "messages": messages,
            "temperature": 0.5,
            "max_tokens": 1024
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, headers=headers, json=data, timeout=30.0)
                if response.status_code == 200:
                    return response.json()["choices"][0]["message"]["content"]
                return f"Groq Error: {response.status_code} - {response.text}"
            except Exception as e:
                print(f"[LLM Error] Groq failed: {e}")
                return "NOOR IQ is currently offline. Please check your API configuration."

    async def _call_gemini(self, messages: List[Dict[str, str]]) -> str:
        # Simplified Gemini Direct API call
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={self.gemini_key}"
        # We transform OpenAI format to Gemini format simply
        contents = []
        for msg in messages:
            role = "user" if msg["role"] == "user" else "model"
            contents.append({"role": role, "parts": [{"text": msg["content"]}]})
            
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json={"contents": contents}, timeout=30.0)
                if response.status_code == 200:
                    return response.json()["candidates"][0]["content"]["parts"][0]["text"]
                return f"Gemini Error: {response.status_code} - {response.text}"
            except Exception as e:
                print(f"[LLM Error] Gemini failed: {e}")
                return "NOOR IQ (Gemini) encountered an error. Check API key."

# 🤖 Global Instance
llm = LLMProvider()
