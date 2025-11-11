# auth_views.py - UPDATED with proper imports
from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser  # ADD THIS IMPORT
from rest_framework.authtoken.models import Token
from django.contrib.auth import logout
from .models import User
from .serializers import (
    FarmerRegistrationSerializer,
    ExtensionWorkerRegistrationSerializer,
    LoginSerializer,
    UserSerializer,
    ChangePasswordSerializer
)


class FarmerRegistrationView(generics.CreateAPIView):
    """Register a new farmer"""
    queryset = User.objects.all()
    permission_classes = [AllowAny]
    serializer_class = FarmerRegistrationSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]  # ADD THIS

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        farmer_profile = serializer.save()

        # Extract the related user from the FarmerProfile
        user = farmer_profile.user

        # Create token for the user
        token, created = Token.objects.get_or_create(user=user)

        return Response({
            'message': 'Farmer registration successful',
            'user': UserSerializer(user).data,
            'token': token.key
        }, status=status.HTTP_201_CREATED)


class ExtensionWorkerRegistrationView(generics.CreateAPIView):
    """Register a new extension worker"""
    queryset = User.objects.all()
    permission_classes = [AllowAny]
    serializer_class = ExtensionWorkerRegistrationSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]  # ADD THIS

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        worker_profile = serializer.save()

        # Extract the related user from the ExtensionWorkerProfile
        user = worker_profile.user

        # Create token for the user
        token, created = Token.objects.get_or_create(user=user)

        return Response({
            'message': 'Extension worker registration successful. '
                       'Your account is pending approval.',
            'user': UserSerializer(user).data,
            'token': token.key
        }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    """Login endpoint"""
    serializer = LoginSerializer(data=request.data, context={'request': request})
    
    if serializer.is_valid():
        user = serializer.validated_data['user']
        token, created = Token.objects.get_or_create(user=user)
        
        return Response({
            'message': 'Login successful',
            'user': UserSerializer(user).data,
            'token': token.key
        }, status=status.HTTP_200_OK)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """Logout endpoint - deletes user token"""
    print(f"Logout requested for user: {request.user.username}")
    
    try:
        from rest_framework.authtoken.models import Token
        
        token_exists = Token.objects.filter(user=request.user).exists()
        print(f"Token exists before logout: {token_exists}")
        
        if token_exists:
            Token.objects.filter(user=request.user).delete()
            print("Token deleted successfully")
        
        logout(request)
        print("Django logout completed")
        
        return Response({
            'message': 'Successfully logged out',
            'token_deleted': token_exists
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Logout error: {str(e)}")
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile_view(request):
    """Get current user profile"""
    serializer = UserSerializer(request.user, context={'request': request})
    return Response(serializer.data)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])  # NOW THIS WILL WORK
def update_profile_view(request):
    """
    Update current user profile
    Supports both JSON and multipart/form-data (for file uploads)
    """
    user = request.user
    
    # Handle both multipart and JSON data
    data = request.data.copy()
    
    # Parse nested farmer_profile data if it exists
    if 'farmer_profile' not in data and any(key.startswith('farmer_profile.') for key in data.keys()):
        farmer_profile_data = {}
        farmer_fields = [
            'farm_name', 'farm_size', 'location', 'region',
            'crops_grown', 'farming_method', 'years_of_experience'
        ]
        
        for field in farmer_fields:
            field_key = f'farmer_profile.{field}'
            if field_key in data:
                # Handle both string and list values
                value = data[field_key]
                if isinstance(value, list):
                    farmer_profile_data[field] = value[0]
                else:
                    farmer_profile_data[field] = value
                del data[field_key]
        
        if farmer_profile_data:
            data['farmer_profile'] = farmer_profile_data
    
    serializer = UserSerializer(user, data=data, partial=True, context={'request': request})
    
    if serializer.is_valid():
        try:
            serializer.save()
            return Response({
                'message': 'Profile updated successfully',
                'user': serializer.data
            })
        except Exception as e:
            return Response({
                'error': f'Failed to save profile: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password_view(request):
    """Change user password"""
    serializer = ChangePasswordSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        user = request.user
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        
        # Update token
        Token.objects.filter(user=user).delete()
        token = Token.objects.create(user=user)
        
        return Response({
            'message': 'Password changed successfully',
            'token': token.key
        })
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def verify_token(request):
    """Verify if token is valid"""
    return Response({
        'valid': True,
        'user': UserSerializer(request.user, context={'request': request}).data
    })