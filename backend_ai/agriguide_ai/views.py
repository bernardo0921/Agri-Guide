# views.py (Updated with authentication)
import google.generativeai as genai
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
import json
import os
from .models import ChatSession, ChatMessage
from django.core.cache import cache
from datetime import date

# Configure Gemini API
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found in environment variables")

# Initialize Gemini API
genai.configure(api_key=GEMINI_API_KEY)

# Set up the model
model = genai.GenerativeModel('gemini-2.5-flash')

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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def chat_with_ai(request):
    """
    Endpoint to chat with AgriGuide AI (requires authentication)
    Expected JSON body: 
    {
        "message": "user message",
        "session_id": "unique_session_id" (optional, will create if not provided)
    }
    """
    try:
        message = request.data.get('message', '').strip()
        session_id = request.data.get('session_id')
        
        if not message:
            return Response({
                'error': 'Message is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get or create chat session
        if session_id:
            try:
                chat_session = ChatSession.objects.get(
                    session_id=session_id,
                    user=request.user
                )
            except ChatSession.DoesNotExist:
                return Response({
                    'error': 'Session not found or access denied'
                }, status=status.HTTP_404_NOT_FOUND)
        else:
            # Create new session
            import uuid
            session_id = str(uuid.uuid4())
            chat_session = ChatSession.objects.create(
                user=request.user,
                session_id=session_id
            )
        
        # Get conversation history from database
        history_messages = ChatMessage.objects.filter(
            session=chat_session
        ).order_by('created_at')
        
        # Build conversation contents
        contents = []
        
        # Add history
        for msg in history_messages:
            contents.append({
                'role': msg.role,
                'parts': [{'text': msg.message}]
            })
        
        # Add current message
        contents.append({
            'role': 'user',
            'parts': [{'text': message}]
        })
        
        # Generate response
        chat = model.start_chat(history=[])
        
        # Add system instruction
        chat.send_message(SYSTEM_INSTRUCTION)
        
        # Send the actual message and get response
        response = chat.send_message(message, generation_config={
            'temperature': 0.7,
            'top_p': 0.8,
            'top_k': 40
        })
        
        ai_response = response.text
        
        # Save messages to database
        ChatMessage.objects.create(
            session=chat_session,
            role='user',
            message=message
        )
        
        ChatMessage.objects.create(
            session=chat_session,
            role='model',
            message=ai_response
        )
        
        # Update session timestamp
        chat_session.save()
        
        return Response({
            'response': ai_response,
            'session_id': session_id
        })
        
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_chat_sessions(request):
    """Get all chat sessions for the authenticated user"""
    sessions = ChatSession.objects.filter(
        user=request.user,
        is_active=True
    ).order_by('-updated_at')
    
    sessions_data = []
    for session in sessions:
        last_message = session.messages.last()
        sessions_data.append({
            'session_id': session.session_id,
            'created_at': session.created_at,
            'updated_at': session.updated_at,
            'message_count': session.messages.count(),
            'last_message': last_message.message if last_message else None
        })
    
    return Response({'sessions': sessions_data})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_chat_history(request, session_id):
    """Get chat history for a specific session"""
    try:
        chat_session = ChatSession.objects.get(
            session_id=session_id,
            user=request.user
        )
        
        messages = ChatMessage.objects.filter(
            session=chat_session
        ).order_by('created_at')
        
        history = []
        for msg in messages:
            history.append({
                'role': msg.role,
                'message': msg.message,
                'created_at': msg.created_at
            })
        
        return Response({
            'session_id': session_id,
            'history': history
        })
        
    except ChatSession.DoesNotExist:
        return Response({
            'error': 'Session not found or access denied'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def clear_chat_session(request):
    """
    Clear a chat session
    Expected JSON body: {"session_id": "unique_session_id"}
    """
    try:
        session_id = request.data.get('session_id')
        
        if not session_id:
            return Response({
                'error': 'session_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        chat_session = ChatSession.objects.get(
            session_id=session_id,
            user=request.user
        )
        
        chat_session.is_active = False
        chat_session.save()
        
        return Response({'message': 'Session cleared'})
        
    except ChatSession.DoesNotExist:
        return Response({
            'error': 'Session not found or access denied'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_chat_session(request, session_id):
    """Delete a chat session permanently"""
    try:
        chat_session = ChatSession.objects.get(
            session_id=session_id,
            user=request.user
        )
        
        chat_session.delete()
        
        return Response({
            'message': 'Session deleted successfully'
        })
        
    except ChatSession.DoesNotExist:
        return Response({
            'error': 'Session not found or access denied'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def test_connection(request):
    """Test endpoint to verify Gemini API connection"""
    try:
        response = model.generate_content('Hello, test connection')
        return Response({
            'status': 'connected',
            'response': response.text,
            'user': request.user.username
        })
    except Exception as e:
        return Response({
            'status': 'error',
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
