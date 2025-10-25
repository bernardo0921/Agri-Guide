import requests
import json

# URL of your running Django backend
DJANGO_API_URL = "http://127.0.0.1:8000/api/gemini/ask/"

# The prompt you want to test
payload = {
    "prompt": "Explain in simple terms what IoT in agriculture means."
}

# Make the POST request
try:
    response = requests.post(
        DJANGO_API_URL,
        headers={"Content-Type": "application/json"},
        data=json.dumps(payload),
        timeout=15
    )

    # Check response status
    if response.status_code == 200:
        print("✅ Success! Gemini responded:")
        print(response.json()["response"])
    else:
        print(f"❌ Error {response.status_code}: {response.text}")

except requests.exceptions.RequestException as e:
    print(f"⚠️ Request failed: {e}")
