from fastapi import APIRouter, HTTPException
from openai import OpenAI
import os
import json
import re
import base64
from datamodel import (
    XrayAnalysisRequest,
    XrayAnalysisResponse,
    SpecialistAnalysis,
    SpecialistFinding,
)

router = APIRouter(prefix="/analysis", tags=["Analysis"])

# Configure Groq API for vision analysis
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    print("WARNING: GROQ_API_KEY not set. X-ray analysis will not work.")
else:
    print("Groq Vision API configured successfully!")

# Create Groq client (OpenAI-compatible)
client = OpenAI(
    api_key=GROQ_API_KEY,
    base_url="https://api.groq.com/openai/v1",
) if GROQ_API_KEY else None

# Enhanced specialist prompts with clear role definitions
SPECIALIST_PROMPTS = {
    "Cardiologist": """You are Dr. Heart, an expert Cardiologist with 20 years of experience reading chest X-rays for cardiac conditions.

YOUR ROLE: Analyze this medical image ONLY for cardiovascular findings.

LOOK FOR:
- Cardiomegaly (enlarged heart) - compare cardiac silhouette to thoracic width
- Pulmonary edema and vascular congestion
- Aortic abnormalities (calcification, aneurysm, unfolding)
- Pericardial effusion
- Cardiac device placement (pacemakers, ICDs)
- Signs of heart failure
- Mediastinal widening

IMPORTANT: If this is NOT a chest X-ray or cardiac imaging, state "No cardiac findings - image is not cardiac-related" and set has_findings to false.""",

    "Neurologist": """You are Dr. Neuro, an expert Neurologist with 20 years of experience reading imaging for neurological conditions.

YOUR ROLE: Analyze this medical image ONLY for neurological findings.

LOOK FOR:
- Brain abnormalities (if head/brain imaging)
- Spinal cord compression or abnormalities
- Skull fractures or abnormalities
- Cervical spine alignment issues
- Signs of stroke (if applicable)
- Intracranial abnormalities
- Nerve root compression indicators

IMPORTANT: If this is NOT brain/spine imaging, state "No neurological findings - image is not neuro-related" and set has_findings to false.""",

    "Orthopedist": """You are Dr. Bone, an expert Orthopedic Surgeon with 20 years of experience reading X-rays for musculoskeletal conditions.

YOUR ROLE: Analyze this medical image for ALL bone and joint findings.

LOOK FOR (BE VERY THOROUGH):
- FRACTURES - Look carefully at bone cortex for any breaks, cracks, or discontinuities
  * Complete fractures (obvious breaks)
  * Hairline/stress fractures (subtle lines)
  * Displaced vs non-displaced fractures
  * Angulation or malposition
- Joint abnormalities (dislocations, subluxations)
- Bone density issues (osteoporosis, lytic lesions)
- Degenerative changes (arthritis, osteophytes)
- Soft tissue swelling near bones
- Foreign bodies
- Healing fractures with callus formation

CRITICAL: Trace EVERY bone cortex in the image looking for ANY disruption. Even subtle cortical breaks must be reported as findings.

IMPORTANT: If you see ANY bone in this image, analyze it carefully. Report "No orthopedic findings" ONLY if bones appear completely normal."""
}


def create_analysis_prompt(specialist: str, image_type: str, body_region: str, patient_context: str = None) -> str:
    """Create a structured prompt for specialist analysis"""
    base_prompt = SPECIALIST_PROMPTS[specialist]
    
    prompt = f"""{base_prompt}

=== IMAGE DETAILS ===
Image Type: {image_type}
Body Region: {body_region}
{f"Patient Context: {patient_context}" if patient_context else "No additional context provided."}

=== YOUR TASK ===
Carefully examine this image and provide your expert analysis.

RESPOND IN THIS EXACT JSON FORMAT (no markdown, just raw JSON):
{{
    "has_findings": true or false,
    "findings": [
        {{
            "title": "Brief descriptive title",
            "description": "Detailed clinical description of what you observe",
            "severity": "High" or "Medium" or "Low",
            "is_red_flag": true or false
        }}
    ],
    "overlooked_warnings": [
        "Subtle findings that might be missed",
        "Related conditions to consider"
    ],
    "recommended_actions": [
        "Specific clinical recommendations",
        "Follow-up imaging or tests needed"
    ]
}}

If you find NO relevant findings for your specialty, respond with:
{{
    "has_findings": false,
    "findings": [],
    "overlooked_warnings": [],
    "recommended_actions": []
}}

NOW ANALYZE THE IMAGE:"""
    
    return prompt


def parse_specialist_response(response_text: str, specialist: str) -> SpecialistAnalysis:
    """Parse the model response into structured data"""
    try:
        # Try to extract JSON from the response
        json_match = re.search(r'\{[\s\S]*\}', response_text)
        if json_match:
            data = json.loads(json_match.group())
        else:
            data = json.loads(response_text)
        
        findings = []
        for f in data.get("findings", []):
            findings.append(SpecialistFinding(
                title=f.get("title", "Unknown"),
                description=f.get("description", ""),
                severity=f.get("severity", "Medium"),
                is_red_flag=f.get("is_red_flag", False)
            ))
        
        return SpecialistAnalysis(
            specialist=specialist,
            has_findings=data.get("has_findings", len(findings) > 0),
            findings=findings,
            overlooked_warnings=data.get("overlooked_warnings", []),
            recommended_actions=data.get("recommended_actions", [])
        )
    except (json.JSONDecodeError, KeyError) as e:
        print(f"Error parsing {specialist} response: {e}")
        print(f"Response was: {response_text[:500]}")
        return SpecialistAnalysis(
            specialist=specialist,
            has_findings=False,
            findings=[],
            overlooked_warnings=[],
            recommended_actions=[]
        )


@router.post("/xray", response_model=XrayAnalysisResponse)
async def analyze_xray(request: XrayAnalysisRequest) -> XrayAnalysisResponse:
    """
    Analyzes X-ray or medical imaging from three specialist perspectives:
    - Cardiologist
    - Neurologist
    - Orthopedist
    
    Uses Groq's vision model (Llama 4 Scout) for accurate medical image analysis.
    """
    
    if not client:
        raise HTTPException(
            status_code=500,
            detail="GROQ_API_KEY not configured. Cannot perform image analysis."
        )
    
    try:
        # Decode the base64 image
        image_data = base64.b64decode(request.image_base64)
        
        # Determine MIME type
        mime_type = "image/jpeg"
        if request.image_base64.startswith("iVBORw"):
            mime_type = "image/png"
        
        # Re-encode for Groq API (data URL format)
        image_base64_str = base64.b64encode(image_data).decode('utf-8')
        image_url = f"data:{mime_type};base64,{image_base64_str}"
        
        analyses = []
        
        # Analyze from each specialist perspective
        for specialist in ["Cardiologist", "Neurologist", "Orthopedist"]:
            prompt = create_analysis_prompt(
                specialist=specialist,
                image_type=request.image_type,
                body_region=request.body_region,
                patient_context=request.patient_context
            )
            
            try:
                response = client.chat.completions.create(
                    model="meta-llama/llama-4-scout-17b-16e-instruct",
                    messages=[
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": prompt},
                                {
                                    "type": "image_url",
                                    "image_url": {
                                        "url": image_url,
                                    },
                                },
                            ],
                        }
                    ],
                    temperature=0.1,
                    max_tokens=2048,
                )
                
                analysis = parse_specialist_response(
                    response.choices[0].message.content, 
                    specialist
                )
                analyses.append(analysis)
                
                print(f"\n=== {specialist} Analysis (Groq Vision) ===")
                print(f"Has findings: {analysis.has_findings}")
                print(f"Findings count: {len(analysis.findings)}")
                if analysis.findings:
                    for f in analysis.findings:
                        print(f"  - {f.title} ({f.severity})")
                
            except Exception as e:
                print(f"Error getting {specialist} analysis: {e}")
                analyses.append(SpecialistAnalysis(
                    specialist=specialist,
                    has_findings=False,
                    findings=[],
                    overlooked_warnings=[],
                    recommended_actions=[]
                ))
        
        # Determine primary specialist (one with most high-severity findings)
        primary_specialist = None
        max_score = 0
        for analysis in analyses:
            if analysis.has_findings:
                score = sum(
                    3 if f.severity == "High" else 2 if f.severity == "Medium" else 1
                    for f in analysis.findings
                )
                if score > max_score:
                    max_score = score
                    primary_specialist = analysis.specialist
        
        # Generate overall summary
        findings_summary = []
        for analysis in analyses:
            if analysis.has_findings:
                for f in analysis.findings:
                    flag = "🚨 " if f.is_red_flag else ""
                    findings_summary.append(f"{flag}{analysis.specialist}: {f.title}")
        
        if findings_summary:
            overall_summary = "Key findings: " + "; ".join(findings_summary[:5])
            if len(findings_summary) > 5:
                overall_summary += f" (+{len(findings_summary) - 5} more)"
        else:
            overall_summary = "No significant findings detected across all specialties."
        
        return XrayAnalysisResponse(
            analyses=analyses,
            primary_specialist=primary_specialist,
            overall_summary=overall_summary
        )
        
    except Exception as e:
        print(f"Error in X-ray analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))
