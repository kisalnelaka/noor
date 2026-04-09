from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "AURA Real Estate Intelligence"
    API_V1_STR: str = "/api/v1"
    
    # Security Auth
    SECRET_KEY: str = "super_secret_key_change_in_production_jwt"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 1 week
    
    # external keys
    OPENAI_API_KEY: str = ""
    ELEVENLABS_API_KEY: str = ""
    GOOGLE_MAPS_API_KEY: str = ""
    
    # Databases
    DATABASE_URL: str = "sqlite:///./aura.db"
    QDRANT_URL: str = "http://localhost:6333"
    REDIS_URL: str = "redis://localhost:6379"
    
    class Config:
        env_file = ".env"

settings = Settings()
