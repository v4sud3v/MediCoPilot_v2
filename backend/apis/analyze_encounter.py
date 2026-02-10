from fastapi import APIRouter, HTTPException
from openai import OpenAI
import os
import re
from datamodel import (
    AnalyzeEncounterRequest,
    AnalyzeEncounterResponse,
    MissedDiagnosis,
    PotentialIssue,
    RecommendedTest
)

router = APIRouter(prefix="/analysis", tags=["Analysis"])

# Configure Groq API (OpenAI-compatible)
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY environment variable not set")

# Create Groq client using OpenAI-compatible interface
client = OpenAI(
    api_key=GROQ_API_KEY,
    base_url="https://api.groq.com/openai/v1",
)
print("Groq API configured successfully!")


def create_prompt(request: AnalyzeEncounterRequest) -> str:
    """Create prompt with patient data"""
    
    # Format vital signs
    vitals = []
    if request.vital_signs.temperature:
        vitals.append(f"Temperature: {request.vital_signs.temperature}°F")
    if request.vital_signs.blood_pressure:
        vitals.append(f"Blood Pressure: {request.vital_signs.blood_pressure}")
    if request.vital_signs.heart_rate:
        vitals.append(f"Heart Rate: {request.vital_signs.heart_rate} bpm")
    if request.vital_signs.respiratory_rate:
        vitals.append(f"Respiratory Rate: {request.vital_signs.respiratory_rate} breaths/min")
    if request.vital_signs.oxygen_saturation:
        vitals.append(f"O2 Saturation: {request.vital_signs.oxygen_saturation}%")
    if request.vital_signs.weight:
        vitals.append(f"Weight: {request.vital_signs.weight} kg")
    if request.vital_signs.height:
        vitals.append(f"Height: {request.vital_signs.height} cm")
    
    vital_signs_text = ', '.join(vitals) if vitals else 'Not provided'
    
    prompt = f"""You are a medical diagnostic assistant. Analyze this patient encounter:

Patient ID: {request.patient_id}
Symptoms: {request.symptoms}
Current Diagnosis: {request.diagnosis}
Vital Signs: {vital_signs_text}
Physical Examination: {request.examination_findings or 'Not provided'}
Current Medications: {request.medications or 'Not provided'}

Provide your analysis in this format:

MISSED DIAGNOSES:
- [Diagnosis name]: [Description] | Confidence: [High/Medium/Low]

POTENTIAL ISSUES:
- [Issue name]: [Description] | Severity: [High/Medium/Low]
- Consider medication interactions and contraindications

RECOMMENDED TESTS:
- [Test name]: [Description] | Priority: [High/Medium/Low]

Analysis:"""
    
    return prompt


def parse_model_output(output: str) -> tuple:
    """Parse model output into structured data"""
    
    missed_diagnoses = []
    potential_issues = []
    recommended_tests = []
    
    try:
        lines = output.split('\n')
        current_section = None
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Detect sections
            if 'MISSED DIAGNOSES' in line.upper():
                current_section = 'missed'
                continue
            elif 'POTENTIAL ISSUES' in line.upper():
                current_section = 'issues'
                continue
            elif 'RECOMMENDED TESTS' in line.upper():
                current_section = 'tests'
                continue
            
            # Parse items (format: "- Title: Description | Level: Value")
            if line.startswith('-') and ':' in line:
                line = line[1:].strip()
                parts = line.split('|')
                title_desc = parts[0].strip()
                
                if ':' not in title_desc:
                    continue
                
                title, description = title_desc.split(':', 1)
                title = title.strip().replace('**', '')
                description = description.strip().replace('**', '')
                
                # Extract level/severity/priority
                level = 'Medium'
                if len(parts) > 1:
                    level_match = re.search(r'(High|Medium|Low)', parts[1], re.IGNORECASE)
                    if level_match:
                        level = level_match.group(1).capitalize()
                
                # Add to appropriate list
                if current_section == 'missed':
                    missed_diagnoses.append(MissedDiagnosis(
                        title=title,
                        description=description,
                        confidence=level
                    ))
                elif current_section == 'issues':
                    potential_issues.append(PotentialIssue(
                        title=title,
                        description=description,
                        severity=level
                    ))
                elif current_section == 'tests':
                    recommended_tests.append(RecommendedTest(
                        title=title,
                        description=description,
                        priority=level
                    ))
    
    except Exception as e:
        print(f"Error parsing output: {e}")
    
    return missed_diagnoses, potential_issues, recommended_tests


@router.post("/encounter", response_model=AnalyzeEncounterResponse)
async def analyze_encounter(request: AnalyzeEncounterRequest) -> AnalyzeEncounterResponse:
    """
    Analyzes encounter data including diagnosis, symptoms, and vital signs.
    Returns potential red flags, missed diagnoses, and recommended tests.
    
    Uses Groq API for medical text understanding.
    """
    
    # Create prompt
    prompt = create_prompt(request)
    
    try:
        # Call Groq API (OpenAI-compatible)
        response = client.chat.completions.create(
            model="openai/gpt-oss-20b",
            messages=[
                {"role": "system", "content": "You are a medical diagnostic assistant."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=2048
        )
        generated_text = response.choices[0].message.content
        
        print(f"\n=== GROQ API OUTPUT ===\n{generated_text}\n===================\n")
        
        # Parse into structured format
        missed, issues, tests = parse_model_output(generated_text)
        
        return AnalyzeEncounterResponse(
            missedDiagnoses=missed,
            potentialIssues=issues,
            recommendedTests=tests
        )
    except Exception as e:
        print(f"Error calling Groq API: {e}")
        raise HTTPException(status_code=500, detail=str(e))
