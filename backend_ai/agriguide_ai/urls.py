# urls.py
from django.urls import path
from . import views
from . import auth_views

urlpatterns = [
    # Authentication endpoints
    path('api/auth/register/farmer/', 
         auth_views.FarmerRegistrationView.as_view(), 
         name='register_farmer'),
    path('api/auth/register/extension-worker/', 
         auth_views.ExtensionWorkerRegistrationView.as_view(), 
         name='register_extension_worker'),
    path('api/auth/login/', 
         auth_views.login_view, 
         name='login'),
    path('api/auth/logout/', 
         auth_views.logout_view, 
         name='logout'),
    path('api/auth/profile/', 
         auth_views.profile_view, 
         name='profile'),
    path('api/auth/profile/update/', 
         auth_views.update_profile_view, 
         name='update_profile'),
    path('api/auth/change-password/', 
         auth_views.change_password_view, 
         name='change_password'),
    path('api/auth/verify-token/', 
         auth_views.verify_token, 
         name='verify_token'),
    
    # Chat endpoints (now authenticated)
    path('api/chat/', 
         views.chat_with_ai, 
         name='chat_with_ai'),
    path('api/chat/sessions/', 
         views.get_chat_sessions, 
         name='get_chat_sessions'),
    path('api/chat/history/<str:session_id>/', 
         views.get_chat_history, 
         name='get_chat_history'),
    path('api/chat/clear/', 
         views.clear_chat_session, 
         name='clear_chat'),
    path('api/chat/delete/<str:session_id>/', 
         views.delete_chat_session, 
         name='delete_chat_session'),
    path('api/test/', 
         views.test_connection, 
         name='test_connection'),
]