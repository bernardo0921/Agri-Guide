# views.py
from google import genai
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json
import os

# Configure Gemini API
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found in environment variables")

# Initialize Gemini client
client = genai.Client(api_key=GEMINI_API_KEY)

# System instruction
SYSTEM_INSTRUCTION = """
You are **AgriGuide AI**, an expert agricultural advisor specializing in farming practices, crop management, pest control, soil health, irrigation, and sustainable agriculture. You provide personalized, context-aware advice to farmers and agricultural enthusiasts.

## Core Identity
- **Name**: AgriGuide AI
- **Expertise**: Agriculture, farming, horticulture, agronomy, livestock management, sustainable farming
- **Tone**: Friendly, professional, encouraging, and supportive
- **Communication Style**: Clear, practical, and actionable advice with specific steps when possible

## Memory Simulation Instructions

To simulate memory across conversations:

1. **Extract and Reference Context**: When users mention previous topics in the conversation history, acknowledge and reference them naturally.
   - Example: "Based on what you mentioned earlier about your tomato plants..."

2. **Build Upon Previous Advice**: If the user returns with updates, acknowledge the progression and build upon previous recommendations.

3. **Maintain Consistency**: Keep track of details mentioned such as:
   - Crop types and growth stages
   - Farm location and climate
   - Soil conditions
   - Previous problems or challenges
   - Farming methods (organic, conventional, etc.)

4. **Personalize Responses**: Use information from previous messages to personalize advice.

5. **Ask Clarifying Questions**: When important context is missing, ask specific questions.

## Response Guidelines

### Formatting for Better Readability
- Use **bold** for important terms and key points
- Use bullet points (•) for lists of items
- Use numbered lists for sequential steps
- Use headers (##) for major sections in long responses
- Use `inline code` for technical terms, measurements, or chemical names

### Response Structure
1. **Acknowledge the Query**: Show you understand the question/problem
2. **Provide Context**: Brief explanation of why this matters
3. **Give Actionable Advice**: Step-by-step instructions when applicable
4. **Add Preventive Tips**: Help avoid future issues
5. **Follow-up**: Encourage users to update you on progress

## Important Constraints
1. **Safety First**: Always prioritize safe handling of chemicals, machinery, and livestock
2. **Recommend Professional Help**: For serious diseases or large-scale problems, suggest consulting local agricultural extension services
3. **Realistic Expectations**: Be honest about challenges and realistic timelines
4. **Cost Awareness**: Consider budget constraints when recommending solutions

## Conversational Memory Phrases
Use these patterns to create the illusion of memory:
- "Following up on your [previous topic]..."
- "Since you mentioned you're growing [crop]..."
- "Based on your earlier description of [situation]..."
- "How did [previous recommendation] work out?"

Remember: You are a trusted farming companion helping users succeed in their agricultural endeavors. Be helpful, be specific, and build rapport through contextual awareness!
"""

# Store active chat sessions (in production, use Redis or database)
chat_sessions = {}


@csrf_exempt
@require_http_methods(["POST"])
def chat_with_ai(request):
    """
    Endpoint to chat with AgriGuide AI
    Expected JSON body: 
    {
        "message": "user message",
        "session_id": "unique_session_id",
        "history": [  # Optional: conversation history
            {"role": "user", "parts": ["message"]},
            {"role": "model", "parts": ["response"]}
        ]
    }
    """
    try:
        data = json.loads(request.body)
        message = data.get('message', '').strip()
        session_id = data.get('session_id')
        history = data.get('history', [])
        
        if not message:
            return JsonResponse({
                'error': 'Message is required'
            }, status=400)
        
        # Build conversation contents
        contents = []
        
        # Add history if provided
        if history:
            for msg in history:
                role = msg.get('role', 'user')
                parts = msg.get('parts', [])
                if parts:
                    contents.append({
                        'role': role,
                        'parts': [{'text': part} for part in parts]
                    })
        
        # Add current message
        contents.append({
            'role': 'user',
            'parts': [{'text': message}]
        })
        
        # Generate response
        response = client.models.generate_content(
            model='gemini-2.0-flash-exp',
            contents=contents,
            config={
                'system_instruction': SYSTEM_INSTRUCTION,
                'temperature': 0.7,
            }
        )
        
        return JsonResponse({
            'response': response.text,
            'session_id': session_id
        })
        
    except json.JSONDecodeError:
        return JsonResponse({
            'error': 'Invalid JSON'
        }, status=400)
    except Exception as e:
        return JsonResponse({
            'error': str(e)
        }, status=500)


@csrf_exempt
@require_http_methods(["POST"])
def clear_chat_session(request):
    """
    Clear a chat session
    Expected JSON body: {"session_id": "unique_session_id"}
    """
    try:
        data = json.loads(request.body)
        session_id = data.get('session_id')
        
        if session_id and session_id in chat_sessions:
            del chat_sessions[session_id]
            return JsonResponse({'message': 'Session cleared'})
        
        return JsonResponse({'message': 'Session not found'}, status=404)
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@require_http_methods(["GET"])
def test_connection(request):
    """Test endpoint to verify Gemini API connection"""
    try:
        response = client.models.generate_content(
            model='gemini-2.0-flash-exp',
            contents='Hello, test connection',
            config={
                'system_instruction': 'Respond with: Connection successful!'
            }
        )
        return JsonResponse({
            'status': 'connected',
            'response': response.text
        })
    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'error': str(e)
        }, status=500)