# agriguide_ai/lms_views.py - FIXED with better error messages
from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.db.models import Q
from .models import Tutorial
from .serializers import TutorialSerializer


class TutorialListCreateView(generics.ListCreateAPIView):
    """
    List all tutorials or create a new tutorial
    GET: List all tutorials with search and category filter
    POST: Create a new tutorial (extension workers only)
    """
    serializer_class = TutorialSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    pagination_class = None  # Disable pagination
    
    def get_queryset(self):
        queryset = Tutorial.objects.all()
        
        # Search functionality
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search) |
                Q(uploader__username__icontains=search) |
                Q(uploader__first_name__icontains=search) |
                Q(uploader__last_name__icontains=search)
            )
        
        # Category filter - FIXED to handle lowercase from Flutter
        category = self.request.query_params.get('category', None)
        if category and category.lower() not in ['all', 'none', '']:
            # Convert to lowercase for consistent comparison
            queryset = queryset.filter(category__iexact=category)
        
        return queryset.select_related('uploader').order_by('-created_at')
    
    def perform_create(self, serializer):
        """Set the uploader to the current user when creating a tutorial"""
        # Debug print to see user type
        print(f"User: {self.request.user.username}")
        print(f"User type: '{self.request.user.user_type}'")
        print(f"User type repr: {repr(self.request.user.user_type)}")
        
        # Check if user is an extension worker - using strip() to handle whitespace
        user_type = str(self.request.user.user_type).strip().lower()
        
        if user_type != 'extension_worker':
            print(f"❌ Permission denied. User type '{user_type}' is not 'extension_worker'")
            raise PermissionError(
                f"Only extension workers can upload tutorials. Your user type is: {self.request.user.user_type}"
            )
        
        print(f"✅ Permission granted for extension worker")
        serializer.save(uploader=self.request.user)
    
    def create(self, request, *args, **kwargs):
        """Override create to add custom response"""
        try:
            return super().create(request, *args, **kwargs)
        except PermissionError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_403_FORBIDDEN
            )


class TutorialDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update or delete a tutorial
    Only the uploader can update/delete their tutorial
    """
    serializer_class = TutorialSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def get_queryset(self):
        return Tutorial.objects.select_related('uploader')
    
    def perform_update(self, serializer):
        """Only allow the uploader to update their tutorial"""
        if serializer.instance.uploader != self.request.user:
            raise PermissionError("You can only edit your own tutorials")
        serializer.save()
    
    def perform_destroy(self, instance):
        """Only allow the uploader to delete their tutorial"""
        if instance.uploader != self.request.user:
            raise PermissionError("You can only delete your own tutorials")
        instance.delete()
    
    def update(self, request, *args, **kwargs):
        """Override update to handle errors"""
        try:
            return super().update(request, *args, **kwargs)
        except PermissionError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_403_FORBIDDEN
            )
    
    def destroy(self, request, *args, **kwargs):
        """Override destroy to handle errors"""
        try:
            return super().destroy(request, *args, **kwargs)
        except PermissionError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_403_FORBIDDEN
            )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def increment_views(request, pk):
    """
    Increment view count for a tutorial
    """
    try:
        tutorial = Tutorial.objects.get(pk=pk)
    except Tutorial.DoesNotExist:
        return Response(
            {'error': 'Tutorial not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    tutorial.increment_view_count()
    
    return Response({
        'message': 'View count incremented',
        'view_count': tutorial.view_count
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_tutorials(request):
    """
    Get all tutorials uploaded by the current user
    """
    # Debug print
    print(f"my_tutorials - User: {request.user.username}")
    print(f"my_tutorials - User type: '{request.user.user_type}'")
    
    # Check if user is an extension worker - using strip() to handle whitespace
    user_type = str(request.user.user_type).strip().lower()
    
    if user_type != 'extension_worker':
        print(f"❌ Access denied. User type '{user_type}' is not 'extension_worker'")
        return Response(
            {
                'error': 'Only extension workers can access this endpoint',
                'user_type': request.user.user_type,
                'detail': f"Your user type is '{request.user.user_type}', but 'extension_worker' is required"
            },
            status=status.HTTP_403_FORBIDDEN
        )
    
    print(f"✅ Access granted for extension worker")
    
    tutorials = Tutorial.objects.filter(
        uploader=request.user
    ).select_related('uploader').order_by('-created_at')
    
    serializer = TutorialSerializer(
        tutorials,
        many=True,
        context={'request': request}
    )
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def tutorial_categories(request):
    """
    Get list of all available tutorial categories
    """
    categories = [
        {'value': 'all', 'label': 'All'},
        {'value': 'crops', 'label': 'Crops'},
        {'value': 'livestock', 'label': 'Livestock'},
        {'value': 'irrigation', 'label': 'Irrigation'},
        {'value': 'pest_control', 'label': 'Pest Control'},
        {'value': 'soil_management', 'label': 'Soil Management'},
        {'value': 'harvesting', 'label': 'Harvesting'},
        {'value': 'post_harvest', 'label': 'Post-Harvest'},
        {'value': 'farm_equipment', 'label': 'Farm Equipment'},
        {'value': 'marketing', 'label': 'Marketing'},
        {'value': 'other', 'label': 'Other'},
    ]
    
    return Response({'categories': categories})


# Add this new debugging endpoint
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_user_type(request):
    """
    Debug endpoint to check current user's type
    """
    return Response({
        'username': request.user.username,
        'user_type': request.user.user_type,
        'user_type_display': request.user.get_user_type_display(),
        'is_extension_worker': request.user.user_type == 'extension_worker',
        'user_type_repr': repr(request.user.user_type),
        'user_type_length': len(request.user.user_type),
    })