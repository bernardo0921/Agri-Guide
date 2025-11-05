# agriguide_ai/admin.py

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import (
    User, 
    FarmerProfile, 
    ExtensionWorkerProfile, 
    ChatSession, 
    ChatMessage
)

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