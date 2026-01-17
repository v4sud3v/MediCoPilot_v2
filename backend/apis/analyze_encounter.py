from transformers import AutoTokenizer, AutoModelForCausalLM
import torch
import re
from datamodel import (
    AnalyzeEncounterRequest,
    AnalyzeEncounterResponse,
    MissedDiagnosis,
    PotentialIssue,
    RecommendedTest
)

# Load Microsoft Phi-2 model globally (only once)
print("Loading Phi-2 model...")
model_name = "microsoft/phi-2"
tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.float16,
    trust_remote_code=True,
    device_map="auto"
)
print("Model loaded successfully!")


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

Provide your analysis in this format:

MISSED DIAGNOSES:
- [Diagnosis name]: [Description] | Confidence: [High/Medium/Low]

POTENTIAL ISSUES:
- [Issue name]: [Description] | Severity: [High/Medium/Low]

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
                title = title.strip()
                description = description.strip()
                
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


def analyze_encounter(request: AnalyzeEncounterRequest) -> AnalyzeEncounterResponse:
    """Analyze encounter using Phi-2 model"""
    
    # Create prompt
    prompt = create_prompt(request)
    
    # Get device from model
    device = model.device
    
    # Generate response
    inputs = tokenizer(prompt, return_tensors="pt", return_attention_mask=True)
    inputs = {k: v.to(device) for k, v in inputs.items()}  # Move inputs to same device as model
    
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_length=1024,
            temperature=0.7,
            do_sample=True,
            top_p=0.9,
            pad_token_id=tokenizer.eos_token_id
        )
    
    # Decode output
    generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
    response = generated_text[len(prompt):].strip()
    
    print(f"\n=== MODEL OUTPUT ===\n{response}\n===================\n")
    
    # Parse into structured format
    missed, issues, tests = parse_model_output(response)
    
    return AnalyzeEncounterResponse(
        missedDiagnoses=missed,
        potentialIssues=issues,
        recommendedTests=tests
    )
