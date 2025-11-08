# serializers.py
from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from .models import User, FarmerProfile, ExtensionWorkerProfile, CommunityPost, PostLike, PostComment


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


class UserSerializer(serializers.ModelSerializer):
    # Use 'farmer_profile' as the source to match Django's related_name
    farmer_profile = FarmerProfileSerializer(required=False)
    extension_worker_profile = ExtensionWorkerProfileSerializer(
        required=False, 
        read_only=True
    )
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'phone_number', 'user_type', 'profile_picture',
            'is_verified', 'created_at', 'farmer_profile',
            'extension_worker_profile'
        ]
        read_only_fields = [
            'id', 'created_at', 'is_verified', 
            'user_type', 'username'
        ]

    def update(self, instance, validated_data):
        # Pop nested data - use 'farmer_profile' since that's the field name
        farmer_profile_data = validated_data.pop('farmer_profile', None)
        # Pop extension worker profile (read-only, so shouldn't be in validated_data)
        validated_data.pop('extension_worker_profile', None)
        
        # Update fields on the main User instance
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Handle nested FarmerProfile update
        if farmer_profile_data and instance.user_type == 'farmer':
            try:
                # Access the farmer_profile using the related_name
                profile_instance = instance.farmer_profile
            except FarmerProfile.DoesNotExist:
                # Create profile if it doesn't exist
                profile_instance = FarmerProfile.objects.create(user=instance)

            # Update farmer profile fields
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

        # Try login with username
        if username:
            user = authenticate(
                request=self.context.get('request'),
                username=username,
                password=password
            )
        # Try login with email
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
        # Try login with phone number
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

# Add this to your existing serializers.py file (or replace the community serializers)

class CommunityPostSerializer(serializers.ModelSerializer):
    """Serializer for community posts"""
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
        """Get author's full name or username"""
        if obj.author.first_name and obj.author.last_name:
            return f"{obj.author.first_name} {obj.author.last_name}"
        return obj.author.username
    
    def get_author_profile_picture(self, obj):
        """Get author's profile picture URL"""
        if obj.author.profile_picture:
            return obj.author.profile_picture.url
        return None
    
    def get_likes_count(self, obj):
        """Get the number of likes for this post"""
        return obj.likes_count
    
    def get_comments_count(self, obj):
        """Get the number of comments for this post"""
        return obj.comments_count
    
    def get_is_liked(self, obj):
        """Check if the current user has liked this post"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return PostLike.objects.filter(
                user=request.user,
                post=obj
            ).exists()
        return False
    
    def create(self, validated_data):
        """Create a new post with the current user as author"""
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
        """Get user's full name or username"""
        if obj.user.first_name and obj.user.last_name:
            return f"{obj.user.first_name} {obj.user.last_name}"
        return obj.user.username
    
    def get_user_profile_picture(self, obj):
        """Get user's profile picture URL"""
        if obj.user.profile_picture:
            return obj.user.profile_picture.url
        return None