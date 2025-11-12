# agriguide_ai/ai_tip_views.py
import google.generativeai as genai
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.core.cache import cache
from datetime import datetime, timedelta
import os
import logging
import random

logger = logging.getLogger(__name__)

# Configure Gemini API
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found in environment variables")

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-2.5-flash')

FARMING_TIP_PROMPT = """
You are an expert agricultural advisor. Generate ONE practical, actionable farming tip.

Requirements:
- Keep it concise (2-3 sentences maximum, around 50-80 words)
- Make it practical and actionable
- Focus on one specific aspect (crop care, soil health, pest management, water conservation, etc.)
- Use simple, clear language
- Make it relevant for small to medium-scale farmers
- Don't include greetings or sign-offs, just the tip itself

Generate a unique farming tip now:
"""

DEFAULT_FALLBACK_TIPS = [
    "Water your plants early in the morning to reduce water loss through evaporation. This also helps prevent fungal diseases that thrive in moist conditions during cooler evening hours.",
    "Rotate your crops each season to prevent soil nutrient depletion and reduce pest buildup. For example, follow nitrogen-fixing legumes with heavy feeders like corn or tomatoes.",
    "Apply mulch around your plants to retain soil moisture, regulate temperature, and suppress weeds. Organic mulches also improve soil health as they decompose.",
    "Monitor your crops regularly for early signs of pests or diseases. Early detection allows for quicker intervention and prevents widespread damage to your harvest.",
    "Test your soil pH annually to ensure optimal nutrient availability. Most crops thrive in slightly acidic to neutral soil (pH 6.0-7.0).",
]


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_daily_farming_tip(request):
    """
    Get daily farming tip from Gemini AI
    Tips are cached for 24 hours
    """
    try:
        # Generate cache key based on current date
        today = datetime.now().date()
        cache_key = f'farming_tip_{today}'
        
        # Try to get cached tip
        cached_tip = cache.get(cache_key)
        
        if cached_tip:
            logger.info(f"Returning cached tip for {today}")
            return Response({
                'tip': cached_tip,
                'cached': True,
                'date': today.isoformat()
            })
        
        # Generate new tip using Gemini
        logger.info(f"Generating new tip for {today}")
        
        response = model.generate_content(
            FARMING_TIP_PROMPT,
            generation_config={
                'temperature': 0.8,
                'top_p': 0.9,
                'max_output_tokens': 150,
            }
        )
        
        tip = response.text.strip()
        
        # Cache the tip for 2 days (48 hours)
        cache.set(cache_key, tip, timeout=60 * 60 * 48)
        
        logger.info(f"Successfully generated and cached new tip")
        
        return Response({
            'tip': tip,
            'cached': False,
            'date': today.isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error generating farming tip: {str(e)}")
        
        # Try to get yesterday's tip as fallback
        yesterday = (datetime.now() - timedelta(days=1)).date()
        yesterday_tip = cache.get(f'farming_tip_{yesterday}')
        
        if yesterday_tip:
            logger.info("Returning yesterday's tip as fallback")
            return Response({
                'tip': yesterday_tip,
                'cached': True,
                'fallback': True,
                'date': yesterday.isoformat()
            })
        
        # Return random default tip if all else fails
        import random
        fallback_tip = random.choice(DEFAULT_FALLBACK_TIPS)
        
        logger.info("Returning default fallback tip")
        return Response({
            'tip': fallback_tip,
            'cached': False,
            'fallback': True,
            'date': datetime.now().date().isoformat()
        })