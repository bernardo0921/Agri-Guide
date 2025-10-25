from django.shortcuts import render

# Create your views here.
import os
import google.generativeai as genai
from dotenv import load_dotenv
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

# Load environment variables
load_dotenv()

# Configure Gemini
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

@api_view(['POST'])
def ask_gemini(request):
    try:
        prompt = request.data.get("prompt", "")
        if not prompt:
            return Response({"error": "Prompt is required"}, status=status.HTTP_400_BAD_REQUEST)

        # Load model
        model = genai.GenerativeModel(model_name="gemini-2.5-flash")  # ✅ Stable model name

        # Generate response
        response = model.generate_content([prompt])

        return Response({
            "response": response.text
        })

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
