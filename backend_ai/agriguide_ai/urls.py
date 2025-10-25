from django.urls import path
from .views import ask_gemini

urlpatterns = [
    path('ask/', ask_gemini, name='ask_gemini'),
]
