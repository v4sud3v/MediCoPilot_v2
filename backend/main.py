from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datamodel import AnalyzeEncounterRequest, AnalyzeEncounterResponse
from apis.analyze_encounter import analyze_encounter

app = FastAPI(
    title="MediCoPilot API",
    description="Medical diagnosis analysis using ClinicalBERT",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {
        "message": "MediCoPilot API",
        "version": "1.0.0",
        "endpoints": ["/analyze_encounter"]
    }


@app.post("/analyze_encounter", response_model=AnalyzeEncounterResponse)
async def analyze_encounter_endpoint(request: AnalyzeEncounterRequest):
    """
    Analyzes encounter data including diagnosis, symptoms, and vital signs.
    Returns potential red flags, missed diagnoses, and recommended tests.
    
    Uses ClinicalBERT model for medical text understanding.
    """
    return analyze_encounter(request)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
