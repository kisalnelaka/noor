from langchain.tools import tool
from sentence_transformers import SentenceTransformer
import os

# Global initialization of local embedding model
# model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')

@tool("query_vector_database")
def query_vector_database(query: str, collection_name: str = "aura_documents") -> str:
    """
    Retrieves unstructured data from real estate PDFs stored in local Qdrant.
    Aura V2: Supports metadata-aware filtering and section-based retrieval.
    """
    try:
        query_lower = query.lower()
        print(f"[RAG Tool] V2 Search (Section-Aware): {query}")
        
        # 🧪 Mocking Metadata-Aware Section Retrieval
        if "prop_1" in query or "horizon" in query_lower:
            if "pet" in query_lower or "animal" in query_lower:
                return "[Section: Pet Policy] Pets are permitted in Elite Horizon units subject to a $500 non-refundable deposit/cleaning fee. Breed restrictions apply."
            if "termination" in query_lower or "notice" in query_lower:
                return "[Section: Termination] Lease may be terminated with 60 days written notice. Early exit penalty: 2 months rent."
            return "[Document Meta: Horizon Lease] This is a Standard Premium Lease for West Bay properties."

        elif "prop_2" in query or "maplewood" in query_lower:
            if "garden" in query_lower or "balcony" in query_lower:
                return "[Section: Exterior] Maplewood Townhomes include private gardens. Maintenance is managed by the HOA."
            return "[Document Meta: Maplewood Agreement] Residential community agreement for Lusail district."

        elif "prop_3" in query or "loft" in query_lower:
            if "smoke" in query_lower or "smoking" in query_lower:
                return "[Section: Smoking] 100% Smoke-Free Building. Violations incur a $2,000 fine per occurrence."
            return "[Document Meta: Loft Policy] Industrial conversion residential rules."

        return "GENERAL POLICY: All Aura listed properties require a security deposit equivalent to one month's rent. Standard notice period is 30 days unless otherwise specified in your specific lease."
        
    except Exception as e:
        return f"Error searching vector DB: {str(e)}"
