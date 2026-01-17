# Backend API Structure

```
backend/
├── main.py                          # FastAPI app entry point
├── datamodel.py                     # Pydantic models for requests/responses
├── apis/
│   └── analyze_encounter.py        # analyze_encounter implementation
├── requirements.txt
└── README.md
```

## Setup

1. Activate virtual environment:
```bash
source venv/bin/activate  # Linux/Mac
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run server:
```bash
python main.py
```

Server runs at `http://localhost:8000`

## API Documentation

Interactive docs: `http://localhost:8000/docs`

## Endpoint

**POST /analyze_encounter**
- Analyzes medical encounters using ClinicalBERT
- Returns missed diagnoses, potential issues, and recommended tests
