# models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import RegexValidator

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
        upload_to='profile_pics/',
        blank=True,
        null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_verified = models.BooleanField(default=False)
    
    # Fix for groups and user_permissions clash
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
        upload_to='verification_docs/',
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

# Add these models to your existing models.py file

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
        upload_to='community_posts/',
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