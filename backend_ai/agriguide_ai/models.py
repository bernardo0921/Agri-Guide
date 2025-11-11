# Updated models.py with S3 storage backends
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import RegexValidator
from django.core.files.storage import default_storage

from .storage_backends import (
    ProfilePictureStorage,
    TutorialVideoStorage,
    TutorialThumbnailStorage,
    CommunityPostImageStorage,
    VerificationDocumentStorage
)


class User(AbstractUser):
    """Extended User model for AgriGuide AI"""
    USER_TYPE_CHOICES = (
        ('farmer', 'Farmer'),
        ('extension_worker', 'Extension Worker'),
    )
    
    user_type = models.CharField(
        max_length=20,
        choices=USER_TYPE_CHOICES,
        default='farmer'
    )
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message="Phone number must be entered in format: '+233123456789'"
    )
    phone_number = models.CharField(
        validators=[phone_regex],
        max_length=17,
        unique=True
    )
    profile_picture = models.ImageField(
        storage=ProfilePictureStorage(),  # Use S3 storage
        blank=True,
        null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_verified = models.BooleanField(default=False)
    
    groups = models.ManyToManyField(
        'auth.Group',
        verbose_name='groups',
        blank=True,
        help_text='The groups this user belongs to.',
        related_name='agriguide_user_set',
        related_query_name='agriguide_user',
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        verbose_name='user permissions',
        blank=True,
        help_text='Specific permissions for this user.',
        related_name='agriguide_user_set',
        related_query_name='agriguide_user',
    )
    def save(self, *args, **kwargs):
        """Override save to handle S3 storage errors"""
        try:
            super().save(*args, **kwargs)
        except Exception as e:
            # Log the error and re-raise
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error saving user {self.username}: {str(e)}")
            raise
    
    class Meta:
        db_table = 'users'
    
    def __str__(self):
        return f"{self.username} ({self.get_user_type_display()})"


class FarmerProfile(models.Model):
    """Profile for farmers"""
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='farmer_profile'
    )
    farm_name = models.CharField(max_length=200, blank=True)
    farm_size = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        help_text="Farm size in acres"
    )
    location = models.CharField(max_length=255, blank=True)
    region = models.CharField(max_length=100, blank=True)
    crops_grown = models.TextField(
        blank=True,
        help_text="Comma-separated list of crops"
    )
    farming_method = models.CharField(
        max_length=50,
        choices=(
            ('organic', 'Organic'),
            ('conventional', 'Conventional'),
            ('mixed', 'Mixed'),
        ),
        default='conventional'
    )
    years_of_experience = models.IntegerField(blank=True, null=True)
    
    class Meta:
        db_table = 'farmer_profiles'
    
    def __str__(self):
        return f"{self.user.username}'s Farm Profile"


class ExtensionWorkerProfile(models.Model):
    """Profile for extension workers"""
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='extension_worker_profile'
    )
    organization = models.CharField(max_length=255)
    employee_id = models.CharField(max_length=50, unique=True)
    specialization = models.CharField(
        max_length=100,
        help_text="e.g., Crop Science, Animal Husbandry"
    )
    regions_covered = models.TextField(
        help_text="Comma-separated list of regions"
    )
    verification_document = models.FileField(
        storage=VerificationDocumentStorage(),  # Use S3 storage
        blank=True,
        null=True
    )
    is_approved = models.BooleanField(default=False)
    approved_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        db_table = 'extension_worker_profiles'
    
    def __str__(self):
        return f"{self.user.username} - {self.organization}"


class ChatSession(models.Model):
    """Store chat sessions for users"""
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='chat_sessions'
    )
    session_id = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        db_table = 'chat_sessions'
        ordering = ['-updated_at']
    
    def __str__(self):
        return f"Session {self.session_id} - {self.user.username}"


class ChatMessage(models.Model):
    """Store individual chat messages"""
    session = models.ForeignKey(
        ChatSession,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    role = models.CharField(
        max_length=10,
        choices=(('user', 'User'), ('model', 'Model'))
    )
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'chat_messages'
        ordering = ['created_at']
    
    def __str__(self):
        return f"{self.role}: {self.message[:50]}..."


class CommunityPost(models.Model):
    """Community post model for farmers to share information"""
    author = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='community_posts'
    )
    content = models.TextField(
        help_text="Post content"
    )
    image = models.ImageField(
        storage=CommunityPostImageStorage(),  # Use S3 storage
        blank=True,
        null=True,
        help_text="Optional image for the post"
    )
    tags = models.JSONField(
        default=list,
        blank=True,
        help_text="List of tags for the post"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'community_posts'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.author.username}: {self.content[:50]}..."
    
    @property
    def likes_count(self):
        """Get the number of likes for this post"""
        return self.likes.count()
    
    @property
    def comments_count(self):
        """Get the number of comments for this post"""
        return self.comments.count()


class PostLike(models.Model):
    """Model to track post likes"""
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='post_likes'
    )
    post = models.ForeignKey(
        CommunityPost,
        on_delete=models.CASCADE,
        related_name='likes'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'post_likes'
        unique_together = ['user', 'post']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} likes post {self.post.id}"


class PostComment(models.Model):
    """Model to track post comments"""
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='post_comments'
    )
    post = models.ForeignKey(
        CommunityPost,
        on_delete=models.CASCADE,
        related_name='comments'
    )
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'post_comments'
        ordering = ['created_at']
    
    def __str__(self):
        return f"{self.user.username} on post {self.post.id}: {self.content[:30]}..."


class Tutorial(models.Model):
    """Tutorial model for extension farmers to post educational videos"""
    
    CATEGORY_CHOICES = (
        ('crops', 'Crops'),
        ('livestock', 'Livestock'),
        ('irrigation', 'Irrigation'),
        ('pest_control', 'Pest Control'),
        ('soil_management', 'Soil Management'),
        ('harvesting', 'Harvesting'),
        ('post_harvest', 'Post-Harvest'),
        ('farm_equipment', 'Farm Equipment'),
        ('marketing', 'Marketing'),
        ('other', 'Other'),
    )
    
    uploader = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='tutorials',
        help_text="User who uploaded the tutorial"
    )
    title = models.CharField(
        max_length=200,
        help_text="Tutorial title"
    )
    description = models.TextField(
        help_text="Detailed description of the tutorial"
    )
    category = models.CharField(
        max_length=50,
        choices=CATEGORY_CHOICES,
        default='other',
        help_text="Tutorial category"
    )
    video = models.FileField(
        storage=TutorialVideoStorage(),  # Use S3 storage
        help_text="Tutorial video file"
    )
    thumbnail = models.ImageField(
        storage=TutorialThumbnailStorage(),  # Use S3 storage
        blank=True,
        null=True,
        help_text="Optional thumbnail image for the video"
    )
    view_count = models.IntegerField(
        default=0,
        help_text="Number of views"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'tutorials'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['category']),
            models.Index(fields=['uploader']),
        ]
    
    def __str__(self):
        return f"{self.title} by {self.uploader.username}"
    
    def increment_view_count(self):
        """Increment the view count for this tutorial"""
        self.view_count += 1
        self.save(update_fields=['view_count'])
    
    @property
    def uploader_name(self):
        """Get uploader's full name or username"""
        if self.uploader.first_name and self.uploader.last_name:
            return f"{self.uploader.first_name} {self.uploader.last_name}"
        return self.uploader.username