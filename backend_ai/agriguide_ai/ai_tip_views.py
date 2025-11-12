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
    print("=" * 80)
    print("🌾 FARMING TIP REQUEST RECEIVED")
    print("=" * 80)
    
    try:
        # Generate cache key based on current date
        today = datetime.now().date()
        cache_key = f'farming_tip_{today}'
        
        print(f"📅 Today's date: {today}")
        print(f"🔑 Cache key: {cache_key}")
        
        # Try to get cached tip
        cached_tip = cache.get(cache_key)
        
        if cached_tip:
            print(f"✅ CACHED TIP FOUND for {today}")
            print(f"📝 Cached tip: {cached_tip[:100]}...")
            logger.info(f"Returning cached tip for {today}")
            return Response({
                'tip': cached_tip,
                'cached': True,
                'date': today.isoformat()
            })
        
        print(f"❌ No cached tip found. Generating new tip...")
        
        # Check if API key is configured
        if not GEMINI_API_KEY:
            print("🚨 ERROR: GEMINI_API_KEY is not set!")
            raise ValueError("GEMINI_API_KEY not configured")
        
        print(f"🔑 API Key present: {GEMINI_API_KEY[:10]}...{GEMINI_API_KEY[-5:]}")
        
        # Generate new tip using Gemini
        print(f"🤖 Calling Gemini API...")
        logger.info(f"Generating new tip for {today}")
        
        response = model.generate_content(
            FARMING_TIP_PROMPT,
            generation_config={
                'temperature': 0.8,
                'top_p': 0.9,
                'max_output_tokens': 150,
            }
        )
        
        print(f"✅ Gemini API response received")
        print(f"📊 Response type: {type(response)}")
        print(f"📊 Response object: {response}")
        
        tip = response.text.strip()
        
        print(f"✅ Generated tip: {tip}")
        print(f"📏 Tip length: {len(tip)} characters")
        
        # Cache the tip for 2 days (48 hours)
        cache.set(cache_key, tip, timeout=60 * 60 * 48)
        print(f"💾 Tip cached for 48 hours")
        
        logger.info(f"Successfully generated and cached new tip")
        
        print("=" * 80)
        print("✅ SUCCESS - Returning AI-generated tip")
        print("=" * 80)
        
        return Response({
            'tip': tip,
            'cached': False,
            'date': today.isoformat()
        })
        
    except Exception as e:
        print("=" * 80)
        print("🚨 ERROR OCCURRED")
        print("=" * 80)
        print(f"❌ Error type: {type(e).__name__}")
        print(f"❌ Error message: {str(e)}")
        
        import traceback
        print(f"📋 Full traceback:")
        print(traceback.format_exc())
        
        logger.error(f"Error generating farming tip: {str(e)}")
        
        # Try to get yesterday's tip as fallback
        yesterday = (datetime.now() - timedelta(days=1)).date()
        yesterday_tip = cache.get(f'farming_tip_{yesterday}')
        
        print(f"🔍 Checking for yesterday's tip ({yesterday})...")
        
        if yesterday_tip:
            print(f"✅ Found yesterday's tip as fallback")
            print(f"📝 Yesterday's tip: {yesterday_tip[:100]}...")
            logger.info("Returning yesterday's tip as fallback")
            return Response({
                'tip': yesterday_tip,
                'cached': True,
                'fallback': True,
                'date': yesterday.isoformat()
            })
        
        print(f"❌ No yesterday's tip found")
        
        # Return random default tip if all else fails
        fallback_tip = random.choice(DEFAULT_FALLBACK_TIPS)
        
        print(f"🔄 Using default fallback tip")
        print(f"📝 Fallback tip: {fallback_tip[:100]}...")
        logger.info("Returning default fallback tip")
        
        print("=" * 80)
        print("⚠️ FALLBACK - Returning default tip")
        print("=" * 80)
        
        return Response({
            'tip': fallback_tip,
            'cached': False,
            'fallback': True,
            'date': datetime.now().date().isoformat()
        })