"""
Medicine PDF Generator
Generates patient-friendly PDF documents with medicine information only.
These PDFs can be shared without revealing patient conditions or diagnosis.
"""

from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib import colors
from io import BytesIO
from datetime import datetime
from typing import List, Dict, Optional
import re


class MedicineInfo:
    """Data class to hold medicine information"""
    def __init__(self, name: str, dosage: str, frequency: str, instructions: str,
                 indication: str = "", side_effects: str = "", precautions: str = "",
                 duration: str = ""):
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.instructions = instructions
        self.indication = indication
        self.side_effects = side_effects
        self.precautions = precautions
        self.duration = duration


def parse_medications_string(medications_str: str) -> List[MedicineInfo]:
    """
    Parse medications string into MedicineInfo objects.
    Expected format: "Medicine Name (Dosage, Frequency, Instructions)"
    Or structured with newlines and colons
    """
    medicines = []
    
    if not medications_str:
        return medicines
    
    # Try to parse structured format first
    lines = medications_str.strip().split('\n')
    current_med = None
    
    for line in lines:
        line = line.strip()
        if not line:
            if current_med and current_med['name']:
                medicines.append(MedicineInfo(**current_med))
                current_med = None
            continue
        
        # Check if it's a medicine name (usually capitalized and doesn't contain colons)
        if ':' not in line and current_med is None:
            current_med = {
                'name': line.strip('- *'),
                'dosage': '',
                'frequency': '',
                'instructions': '',
                'indication': '',
                'side_effects': '',
                'precautions': '',
                'duration': ''
            }
        elif current_med:
            if line.lower().startswith('dosage'):
                current_med['dosage'] = line.split(':', 1)[1].strip() if ':' in line else ''
            elif line.lower().startswith('frequency'):
                current_med['frequency'] = line.split(':', 1)[1].strip() if ':' in line else ''
            elif line.lower().startswith('instruction'):
                current_med['instructions'] = line.split(':', 1)[1].strip() if ':' in line else ''
            elif line.lower().startswith('indication'):
                current_med['indication'] = line.split(':', 1)[1].strip() if ':' in line else ''
            elif line.lower().startswith('side effect'):
                current_med['side_effects'] = line.split(':', 1)[1].strip() if ':' in line else ''
            elif line.lower().startswith('precaution'):
                current_med['precautions'] = line.split(':', 1)[1].strip() if ':' in line else ''
            elif line.lower().startswith('duration'):
                current_med['duration'] = line.split(':', 1)[1].strip() if ':' in line else ''
    
    # Add the last medicine if exists
    if current_med and current_med['name']:
        medicines.append(MedicineInfo(**current_med))
    
    # Fallback to simple parsing if structured parsing didn't work
    if not medicines and medications_str:
        # Simple regex pattern to extract medicine names and details
        pattern = r'([A-Za-z\s]+?)(?:\s*\(([^)]+)\))?(?:\n|$)'
        matches = re.findall(pattern, medications_str)
        for match in matches:
            med_name = match[0].strip()
            details = match[1] if match[1] else ""
            if med_name:
                medicines.append(MedicineInfo(
                    name=med_name,
                    dosage=details,
                    frequency="As prescribed",
                    instructions="Follow doctor's instructions"
                ))
    
    return medicines


def generate_medicine_pdf(medicines: List[MedicineInfo], patient_name: str = "Patient",
                          doctor_name: str = "Your Doctor") -> bytes:
    """
    Generate a PDF with medicine information only.
    Returns the PDF as bytes.
    """
    # Create BytesIO buffer
    pdf_buffer = BytesIO()
    
    # Create PDF document
    doc = SimpleDocTemplate(
        pdf_buffer,
        pagesize=letter,
        rightMargin=0.75*inch,
        leftMargin=0.75*inch,
        topMargin=0.75*inch,
        bottomMargin=0.75*inch,
        title="Medication Information"
    )
    
    # Define styles
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        textColor=colors.HexColor('#667eea'),
        spaceAfter=6,
        alignment=0,  # Left align
        fontName='Helvetica-Bold'
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#764ba2'),
        spaceAfter=8,
        spaceBefore=12,
        fontName='Helvetica-Bold'
    )
    
    med_name_style = ParagraphStyle(
        'MedicineName',
        parent=styles['Heading3'],
        fontSize=12,
        textColor=colors.HexColor('#1e293b'),
        spaceAfter=6,
        spaceBefore=6,
        fontName='Helvetica-Bold'
    )
    
    normal_style = ParagraphStyle(
        'CustomNormal',
        parent=styles['Normal'],
        fontSize=10,
        leading=12,
        textColor=colors.HexColor('#334155'),
        spaceAfter=4
    )
    
    label_style = ParagraphStyle(
        'Label',
        parent=styles['Normal'],
        fontSize=10,
        leading=12,
        textColor=colors.HexColor('#64748b'),
        spaceAfter=2,
        fontName='Helvetica-Bold'
    )
    
    # Build document
    story = []
    
    # Header
    story.append(Paragraph("Medication Information", title_style))
    story.append(Spacer(1, 0.1*inch))
    story.append(Paragraph(
        f"<b>Date:</b> {datetime.now().strftime('%B %d, %Y')}<br/>"
        f"<b>Prescribed by:</b> {doctor_name}<br/>"
        f"<b>For:</b> {patient_name}",
        normal_style
    ))
    story.append(Spacer(1, 0.25*inch))
    
    # Important Note
    story.append(Paragraph("Important Information", heading_style))
    story.append(Paragraph(
        "This document contains information about your prescribed medications. "
        "Please read all instructions carefully and follow your doctor's advice. "
        "If you have any questions or concerns about your medications, contact your healthcare provider immediately.",
        normal_style
    ))
    story.append(Spacer(1, 0.2*inch))
    
    # Medications
    if medicines:
        story.append(Paragraph("Your Medications", heading_style))
        
        for idx, medicine in enumerate(medicines, 1):
            # Medicine name
            story.append(Paragraph(f"{idx}. {medicine.name}", med_name_style))
            
            # Create table for medicine details
            med_data = []
            
            if medicine.indication:
                med_data.append([
                    Paragraph("<b>What is it for?</b>", label_style),
                    Paragraph(medicine.indication, normal_style)
                ])
            
            if medicine.dosage:
                med_data.append([
                    Paragraph("<b>Dosage:</b>", label_style),
                    Paragraph(medicine.dosage, normal_style)
                ])
            
            if medicine.frequency:
                med_data.append([
                    Paragraph("<b>How often?</b>", label_style),
                    Paragraph(medicine.frequency, normal_style)
                ])
            
            if medicine.instructions:
                med_data.append([
                    Paragraph("<b>How to take:</b>", label_style),
                    Paragraph(medicine.instructions, normal_style)
                ])
            
            if medicine.duration:
                med_data.append([
                    Paragraph("<b>Duration:</b>", label_style),
                    Paragraph(medicine.duration, normal_style)
                ])
            
            if medicine.side_effects:
                med_data.append([
                    Paragraph("<b>Possible side effects:</b>", label_style),
                    Paragraph(medicine.side_effects, normal_style)
                ])
            
            if medicine.precautions:
                med_data.append([
                    Paragraph("<b>Precautions:</b>", label_style),
                    Paragraph(medicine.precautions, normal_style)
                ])
            
            # Add a note about common precautions if not specified
            if not medicine.precautions:
                med_data.append([
                    Paragraph("<b>General notes:</b>", label_style),
                    Paragraph(
                        "• Take at the same time each day if possible<br/>"
                        "• Do not stop taking without consulting your doctor<br/>"
                        "• Report any unusual symptoms to your healthcare provider",
                        normal_style
                    )
                ])
            
            if med_data:
                med_table = Table(med_data, colWidths=[1.5*inch, 4*inch])
                med_table.setStyle(TableStyle([
                    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                    ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                    ('COLUMNBACKGROUNDCOLOR', (0, 0), (0, -1), colors.HexColor('#f0f4f8')),
                    ('TEXTCOLOR', (0, 0), (0, -1), colors.HexColor('#1e293b')),
                    ('FONTSIZE', (0, 0), (-1, -1), 10),
                    ('LEFTPADDING', (0, 0), (0, -1), 10),
                    ('RIGHTPADDING', (0, 0), (0, -1), 10),
                    ('TOPPADDING', (0, 0), (-1, -1), 8),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
                    ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#e2e8f0')),
                ]))
                story.append(med_table)
            
            story.append(Spacer(1, 0.15*inch))
    else:
        story.append(Paragraph("No medications prescribed.", normal_style))
    
    # Footer
    story.append(Spacer(1, 0.3*inch))
    story.append(Paragraph(
        "<b>Important Reminders:</b><br/>"
        "• This document is confidential and contains your medication information only<br/>"
        "• Keep all medications out of reach of children<br/>"
        "• Store medications as directed (room temperature, refrigerated, etc.)<br/>"
        "• Do not share medications with others<br/>"
        "• If you miss a dose, follow your doctor's instructions on what to do<br/>"
        "• Contact your doctor or pharmacist if you experience any adverse effects",
        normal_style
    ))
    
    story.append(Spacer(1, 0.2*inch))
    story.append(Paragraph(
        f"<i>This document was generated on {datetime.now().strftime('%B %d, %Y at %I:%M %p')} "
        "and can be safely shared without revealing your medical conditions or diagnosis.</i>",
        ParagraphStyle(
            'Footer',
            parent=styles['Normal'],
            fontSize=9,
            textColor=colors.HexColor('#94a3b8'),
            alignment=1  # Center align
        )
    ))
    
    # Build PDF
    doc.build(story)
    
    # Get PDF bytes
    pdf_bytes = pdf_buffer.getvalue()
    pdf_buffer.close()
    
    return pdf_bytes


def generate_medicine_pdf_from_string(medications_str: str, patient_name: str = "Patient",
                                      doctor_name: str = "Your Doctor") -> bytes:
    """
    Generate a medicine PDF from a medications string.
    """
    medicines = parse_medications_string(medications_str)
    return generate_medicine_pdf(medicines, patient_name, doctor_name)
