# agriguide_ai/admin.py

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CommunityPost, PostLike, PostComment

from .models import (
    User, 
    FarmerProfile, 
    ExtensionWorkerProfile, 
    ChatSession, 
    ChatMessage
)



@admin.register(CommunityPost)
class CommunityPostAdmin(admin.ModelAdmin):
    """Admin interface for community posts"""
    list_display = [
        'id',
        'author',
        'content_preview',
        'tags_display',
        'likes_count',
        'comments_count',
        'created_at'
    ]
    list_filter = ['created_at', 'author']
    search_fields = ['content', 'author__username', 'author__email']
    readonly_fields = ['created_at', 'updated_at', 'likes_count', 'comments_count']
    
    def content_preview(self, obj):
        """Show a preview of the content"""
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'
    
    def tags_display(self, obj):
        """Display tags as a comma-separated string"""
        return ', '.join(obj.tags) if obj.tags else 'No tags'
    tags_display.short_description = 'Tags'


@admin.register(PostLike)
class PostLikeAdmin(admin.ModelAdmin):
    """Admin interface for post likes"""
    list_display = ['id', 'user', 'post', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__username', 'post__content']
    readonly_fields = ['created_at']


@admin.register(PostComment)
class PostCommentAdmin(admin.ModelAdmin):
    """Admin interface for post comments"""
    list_display = ['id', 'user', 'post', 'content_preview', 'created_at']
    list_filter = ['created_at']
    search_fields = ['content', 'user__username', 'post__content']
    readonly_fields = ['created_at', 'updated_at']
    
    def content_preview(self, obj):
        """Show a preview of the comment content"""
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Comment'
# This custom admin class will improve how your User model looks
class CustomUserAdmin(UserAdmin):
    model = User
    
    # This adds your custom fields to the "Edit User" page
    fieldsets = UserAdmin.fieldsets + (
        ('Custom Profile Info', {
            'fields': (
                'user_type', 
                'phone_number', 
                'profile_picture', 
                'is_verified'
            )
        }),
    )
    
    # This adds your custom fields to the "Create User" page
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Custom Profile Info', {
            'fields': (
                'first_name', 
                'last_name', 
                'email', 
                'user_type', 
                'phone_number'
            )
        }),
    )
    
    # This adds your custom fields to the main user list
    list_display = [
        'username', 
        'email', 
        'user_type', 
        'first_name', 
        'last_name', 
        'is_staff'
    ]

# Register your models with the admin site
admin.site.register(User, CustomUserAdmin)
admin.site.register(FarmerProfile)
admin.site.register(ExtensionWorkerProfile)
admin.site.register(ChatSession)
admin.site.register(ChatMessage)