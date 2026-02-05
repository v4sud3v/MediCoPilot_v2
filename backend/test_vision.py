from openai import OpenAI
import os
import base64
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(
    api_key=os.getenv("GROQ_API_KEY"),
    base_url="https://api.groq.com/openai/v1",
)

# Use the image path provided by the system/user
IMAGE_PATH = "/home/crv/.gemini/antigravity/brain/8e07cb21-52bc-4d08-ac00-daa692a59b2f/uploaded_media_1770124049443.jpg"

def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

image_data = encode_image(IMAGE_PATH)
image_url = f"data:image/jpeg;base64,{image_data}"

print("Testing model: meta-llama/llama-4-scout-17b-16e-instruct")

try:
    response = client.chat.completions.create(
        model="meta-llama/llama-4-scout-17b-16e-instruct",
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Describe this medical image in detail. What do you see? Do you see any fractures?"},
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
    )
    print("\n--- Response ---")
    print(response.choices[0].message.content)

except Exception as e:
    print(f"Error: {e}")
