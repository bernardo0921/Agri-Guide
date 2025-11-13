# agriguide_ai/urls.py - UPDATED WITH DEEP LINK ROUTES
from django.urls import path
from . import views
from . import auth_views
from . import community_views, lms_views, ai_tip_views
from . import deep_link_views  # NEW IMPORT

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
    
    # DEBUG: Check user type endpoint
    path('api/auth/check-user-type/', 
         lms_views.check_user_type, 
         name='check_user_type'),
    
    # Chat endpoints
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
    
    # AI Tip endpoint
    path('api/farming-tip/', 
         ai_tip_views.get_daily_farming_tip, 
         name='get_daily_farming_tip'),
         
    # Community endpoints
    path('api/community/posts/', 
         community_views.CommunityPostListCreateView.as_view(), 
         name='community_posts'),
    path('api/community/posts/<int:pk>/', 
         community_views.CommunityPostDetailView.as_view(), 
         name='community_post_detail'),
    path('api/community/posts/<int:pk>/like/', 
         community_views.toggle_post_like, 
         name='toggle_post_like'),
    path('api/community/posts/<int:pk>/comments/', 
         community_views.post_comments, 
         name='post_comments'),
    path('api/community/posts/<int:pk>/comments/<int:comment_id>/', 
         community_views.delete_comment, 
         name='delete_comment'),
    path('api/community/my-posts/', 
         community_views.my_posts, 
         name='my_posts'),
    
    # LMS/Tutorial endpoints
    path('api/tutorials/', 
         lms_views.TutorialListCreateView.as_view(), 
         name='tutorial_list_create'),
    path('api/tutorials/<int:pk>/', 
         lms_views.TutorialDetailView.as_view(), 
         name='tutorial_detail'),
    path('api/tutorials/<int:pk>/increment_views/', 
         lms_views.increment_views, 
         name='increment_views'),
    path('api/tutorials/my_tutorials/', 
         lms_views.my_tutorials, 
         name='my_tutorials'),
    path('api/tutorials/categories/', 
         lms_views.tutorial_categories, 
         name='tutorial_categories'),
    
    # ============ NEW: DEEP LINK ENDPOINTS ============
    
    # API endpoint to fetch post data (used by Flutter app)
    path('api/post/<int:post_id>/data/', 
         deep_link_views.post_deep_link_data, 
         name='post_deep_link_data'),
    
    # Web fallback page (when app is not installed)
    # This MUST be at root level, not under /api/
    path('post/<int:post_id>/', 
         deep_link_views.post_fallback_view, 
         name='post_fallback'),
    
    # Optional: Open Graph metadata endpoint
    path('api/post/<int:post_id>/metadata/', 
         deep_link_views.generate_share_metadata, 
         name='post_share_metadata'),
    
    # Optional: Track share analytics
    path('api/post/<int:post_id>/track-share/', 
         deep_link_views.track_share_analytics, 
         name='track_share'),
]