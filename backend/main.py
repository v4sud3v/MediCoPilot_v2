from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from apis.auth import router as auth_router
from apis.analyze_encounter import router as analysis_router
from apis.save_encounter import router as save_encounter_router

app = FastAPI(
    title="MediCoPilot API",
    description="Medical diagnosis analysis",
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

# Include routers
app.include_router(auth_router)
app.include_router(analysis_router)
app.include_router(save_encounter_router)


@app.get("/", tags=["Health"])
def root():
    return {
        "message": "MediCoPilot API",
        "version": "1.0.0",
        "endpoints": {
            "health": "/",
            "authentication": "/auth/*",
            "analysis": "/analysis/encounter",
            "save_encounter": "/encounter/save"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
