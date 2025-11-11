# Updated serializers.py - S3 URLs are now automatically handled
from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from .models import User, FarmerProfile, ExtensionWorkerProfile, CommunityPost, PostLike, PostComment
from .models import Tutorial
import os


class FarmerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = FarmerProfile
        fields = [
            'farm_name', 'farm_size', 'location', 'region',
            'crops_grown', 'farming_method', 'years_of_experience'
        ]


class ExtensionWorkerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExtensionWorkerProfile
        fields = [
            'organization', 'employee_id', 'specialization',
            'regions_covered', 'verification_document', 'is_approved'
        ]
        read_only_fields = ['is_approved']


# serializers.py - UPDATED UserSerializer

class UserSerializer(serializers.ModelSerializer):
    farmer_profile = FarmerProfileSerializer(required=False)
    extension_worker_profile = ExtensionWorkerProfileSerializer(
        required=False, 
        read_only=True
    )
    profile_picture_url = serializers.SerializerMethodField()  # ADD THIS
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'phone_number', 'user_type', 'profile_picture', 'profile_picture_url',
            'is_verified', 'created_at', 'farmer_profile',
            'extension_worker_profile'
        ]
        read_only_fields = [
            'id', 'created_at', 'is_verified', 
            'user_type', 'username'
        ]
    
    def get_profile_picture_url(self, obj):  # ADD THIS METHOD
        """Returns S3 URL automatically"""
        if obj.profile_picture:
            return obj.profile_picture.url
        return None

    def update(self, instance, validated_data):
        farmer_profile_data = validated_data.pop('farmer_profile', None)
        
        # Update user fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update farmer profile if data provided and user is farmer
        if farmer_profile_data and instance.user_type == 'farmer':
            try:
                profile_instance = instance.farmer_profile
            except FarmerProfile.DoesNotExist:
                profile_instance = FarmerProfile.objects.create(user=instance)

            for attr, value in farmer_profile_data.items():
                setattr(profile_instance, attr, value)
            profile_instance.save()
        
        return instance

class FarmerRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password]
    )
    password_confirm = serializers.CharField(write_only=True, required=True)
    farmer_profile = FarmerProfileSerializer(required=True)
    
    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password_confirm',
            'first_name', 'last_name', 'phone_number',
            'profile_picture', 'farmer_profile'
        ]
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({
                "password": "Password fields didn't match."
            })
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        farmer_profile_data = validated_data.pop('farmer_profile')
        
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            phone_number=validated_data['phone_number'],
            user_type='farmer',
            profile_picture=validated_data.get('profile_picture')
        )
        
        farmer_profile = FarmerProfile.objects.create(user=user, **farmer_profile_data)
        
        return farmer_profile


class ExtensionWorkerRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password]
    )
    password_confirm = serializers.CharField(write_only=True, required=True)
    extension_worker_profile = ExtensionWorkerProfileSerializer(required=True)
    
    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password_confirm',
            'first_name', 'last_name', 'phone_number',
            'profile_picture', 'extension_worker_profile'
        ]
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({
                "password": "Password fields didn't match."
            })
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        extension_profile_data = validated_data.pop('extension_worker_profile')
        
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            phone_number=validated_data['phone_number'],
            user_type='extension_worker',
            profile_picture=validated_data.get('profile_picture')
        )
        
        extension_worker_profile = ExtensionWorkerProfile.objects.create(
            user=user,
            **extension_profile_data
        )
        
        return extension_worker_profile


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(required=False)
    email = serializers.EmailField(required=False)
    phone_number = serializers.CharField(required=False)
    password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'}
    )

    def validate(self, attrs):
        username = attrs.get('username')
        email = attrs.get('email')
        phone_number = attrs.get('phone_number')
        password = attrs.get('password')

        user = None

        if username:
            user = authenticate(
                request=self.context.get('request'),
                username=username,
                password=password
            )
        elif email:
            try:
                user_obj = User.objects.get(email=email)
                user = authenticate(
                    request=self.context.get('request'),
                    username=user_obj.username,
                    password=password
                )
            except User.DoesNotExist:
                pass
        elif phone_number:
            try:
                user_obj = User.objects.get(phone_number=phone_number)
                user = authenticate(
                    request=self.context.get('request'),
                    username=user_obj.username,
                    password=password
                )
            except User.DoesNotExist:
                pass

        if not user:
            raise serializers.ValidationError(
                'Unable to log in with provided credentials.',
                code='authorization'
            )

        if not user.is_active:
            raise serializers.ValidationError(
                'User account is disabled.',
                code='authorization'
            )

        attrs['user'] = user
        return attrs


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(
        required=True,
        write_only=True,
        validators=[validate_password]
    )
    new_password_confirm = serializers.CharField(
        required=True,
        write_only=True
    )
    
    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({
                "new_password": "Password fields didn't match."
            })
        return attrs
    
    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("Old password is incorrect.")
        return value


class CommunityPostSerializer(serializers.ModelSerializer):
    """Serializer for community posts - S3 URLs handled automatically"""
    author_name = serializers.SerializerMethodField()
    author_username = serializers.CharField(source='author.username', read_only=True)
    author_profile_picture = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    
    class Meta:
        model = CommunityPost
        fields = [
            'id', 'author_name', 'author_username', 'author_profile_picture',
            'content', 'image', 'tags', 'likes_count', 'comments_count',
            'is_liked', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_author_name(self, obj):
        if obj.author.first_name and obj.author.last_name:
            return f"{obj.author.first_name} {obj.author.last_name}"
        return obj.author.username
    
    def get_author_profile_picture(self, obj):
        """Returns S3 URL automatically"""
        if obj.author.profile_picture:
            return obj.author.profile_picture.url
        return None
    
    def get_likes_count(self, obj):
        return obj.likes_count
    
    def get_comments_count(self, obj):
        return obj.comments_count
    
    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return PostLike.objects.filter(
                user=request.user,
                post=obj
            ).exists()
        return False
    
    def create(self, validated_data):
        request = self.context.get('request')
        validated_data['author'] = request.user
        return super().create(validated_data)


class PostCommentSerializer(serializers.ModelSerializer):
    """Serializer for post comments"""
    user_name = serializers.SerializerMethodField()
    user_username = serializers.CharField(source='user.username', read_only=True)
    user_profile_picture = serializers.SerializerMethodField()
    
    class Meta:
        model = PostComment
        fields = [
            'id', 'user_name', 'user_username', 'user_profile_picture',
            'content', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        if obj.user.first_name and obj.user.last_name:
            return f"{obj.user.first_name} {obj.user.last_name}"
        return obj.user.username
    
    def get_user_profile_picture(self, obj):
        """Returns S3 URL automatically"""
        if obj.user.profile_picture:
            return obj.user.profile_picture.url
        return None


# Add this to your serializers.py - Updated TutorialSerializer

class TutorialSerializer(serializers.ModelSerializer):
    """Serializer for Tutorial model - S3 URLs handled automatically"""
    uploader_name = serializers.SerializerMethodField()
    uploader_id = serializers.IntegerField(source='uploader.id', read_only=True)
    uploader_profile_picture = serializers.SerializerMethodField()
    video_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Tutorial
        fields = [
            'id', 'title', 'description', 'category', 'video', 'thumbnail',
            'video_url', 'thumbnail_url', 'uploader_id', 'uploader_name',
            'uploader_profile_picture', 'view_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'view_count', 'created_at', 'updated_at']
    
    def get_uploader_name(self, obj):
        return obj.uploader_name
    
    def get_uploader_profile_picture(self, obj):
        """Returns S3 URL automatically"""
        if obj.uploader.profile_picture:
            return obj.uploader.profile_picture.url
        return None
    
    def get_video_url(self, obj):
        """Returns S3 URL automatically"""
        if obj.video:
            return obj.video.url
        return None
    
    def get_thumbnail_url(self, obj):
        """Returns S3 URL automatically"""
        if obj.thumbnail:
            return obj.thumbnail.url
        return None
    
    def validate_category(self, value):
        """FIXED: Accept both lowercase and original format"""
        # List of valid categories in lowercase
        valid_categories = [
            'crops', 'livestock', 'irrigation', 'pest_control',
            'soil_management', 'harvesting', 'post_harvest',
            'farm_equipment', 'marketing', 'other'
        ]
        
        # Convert to lowercase for validation
        if value.lower() not in valid_categories:
            raise serializers.ValidationError(
                f"Invalid category. Must be one of: {', '.join(valid_categories)}"
            )
        
        # Return lowercase version for consistency
        return value.lower()
    
    def validate_video(self, value):
        if value:
            if value.size > 100 * 1024 * 1024:
                raise serializers.ValidationError(
                    "Video file size must be under 100MB"
                )
            
            allowed_extensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm']
            file_extension = os.path.splitext(value.name)[1].lower()
            if file_extension not in allowed_extensions:
                raise serializers.ValidationError(
                    f"Video file must be one of: {', '.join(allowed_extensions)}"
                )
        
        return value
    
    def validate_thumbnail(self, value):
        if value:
            if value.size > 5 * 1024 * 1024:
                raise serializers.ValidationError(
                    "Thumbnail file size must be under 5MB"
                )
            
            allowed_extensions = ['.jpg', '.jpeg', '.png', '.webp']
            file_extension = os.path.splitext(value.name)[1].lower()
            if file_extension not in allowed_extensions:
                raise serializers.ValidationError(
                    f"Thumbnail must be one of: {', '.join(allowed_extensions)}"
                )
        
        return value
    
    def validate(self, attrs):
        request = self.context.get('request')
        if request and request.method == 'POST':
            if request.user.user_type != 'extension_worker':
                raise serializers.ValidationError(
                    "Only extension workers can upload tutorials"
                )
        
        return attrs
    
    def create(self, validated_data):
        request = self.context.get('request')
        validated_data['uploader'] = request.user
        return super().create(validated_data)