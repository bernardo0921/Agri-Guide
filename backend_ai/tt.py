import os
from google import genai

# Fetch Gemini API key from environment variable
# GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')

# if not GEMINI_API_KEY:
#     raise ValueError("❌ GEMINI_API_KEY environment variable not found!")

# Initialize Gemini client
client = genai.Client(api_key='AIzaSyAPh3XBQhI9YVjWMpluoVzLWHdxrrn4UsI')

# Send a simple prompt to Gemini Flash
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="hi"
)

# Print the response text
print("Gemini says:", response.text)
