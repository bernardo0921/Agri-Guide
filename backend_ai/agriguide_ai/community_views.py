# agriguide_ai/community_views.py
from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.db.models import Q, Count
from .models import CommunityPost, PostLike, PostComment
from .serializers import CommunityPostSerializer, PostCommentSerializer


class CommunityPostListCreateView(generics.ListCreateAPIView):
    """
    List all posts or create a new post
    GET: List all posts with search capability
    POST: Create a new post (supports image upload)
    """
    serializer_class = CommunityPostSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]  # Add parsers for file upload
    pagination_class = None  # Disable pagination to return direct list
    
    def get_queryset(self):
        queryset = CommunityPost.objects.all()
        
        # Search functionality
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(content__icontains=search) |
                Q(author__username__icontains=search) |
                Q(author__first_name__icontains=search) |
                Q(author__last_name__icontains=search) |
                Q(tags__icontains=search)
            )
        
        return queryset.select_related('author').prefetch_related('likes', 'comments').order_by('-created_at')
    
    def perform_create(self, serializer):
        """Set the author to the current user when creating a post"""
        serializer.save(author=self.request.user)


class CommunityPostDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update or delete a post
    Only the author can update/delete their post
    """
    serializer_class = CommunityPostSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]  # Add parsers for file upload
    
    def get_queryset(self):
        return CommunityPost.objects.select_related('author').prefetch_related('likes', 'comments')
    
    def perform_update(self, serializer):
        """Only allow the author to update their post"""
        if serializer.instance.author != self.request.user:
            raise PermissionError("You can only edit your own posts")
        serializer.save()
    
    def perform_destroy(self, instance):
        """Only allow the author to delete their post"""
        if instance.author != self.request.user:
            raise PermissionError("You can only delete your own posts")
        instance.delete()


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def toggle_post_like(request, pk):
    """
    Like or unlike a post
    """
    try:
        post = CommunityPost.objects.get(pk=pk)
    except CommunityPost.DoesNotExist:
        return Response(
            {'error': 'Post not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Check if user already liked the post
    like_exists = PostLike.objects.filter(
        user=request.user,
        post=post
    ).exists()
    
    if like_exists:
        # Unlike the post
        PostLike.objects.filter(user=request.user, post=post).delete()
        message = 'Post unliked'
        liked = False
    else:
        # Like the post
        PostLike.objects.create(user=request.user, post=post)
        message = 'Post liked'
        liked = True
    
    return Response({
        'message': message,
        'liked': liked,
        'likes_count': post.likes.count()
    }, status=status.HTTP_200_OK)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def post_comments(request, pk):
    """
    GET: List all comments for a post
    POST: Add a comment to a post
    """
    try:
        post = CommunityPost.objects.get(pk=pk)
    except CommunityPost.DoesNotExist:
        return Response(
            {'error': 'Post not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    if request.method == 'GET':
        comments = PostComment.objects.filter(post=post).select_related('user').order_by('created_at')
        serializer = PostCommentSerializer(comments, many=True, context={'request': request})
        return Response(serializer.data)
    
    elif request.method == 'POST':
        serializer = PostCommentSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save(user=request.user, post=post)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_comment(request, pk, comment_id):
    """
    Delete a comment (only the author can delete)
    """
    try:
        comment = PostComment.objects.get(pk=comment_id, post_id=pk)
    except PostComment.DoesNotExist:
        return Response(
            {'error': 'Comment not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Only allow the comment author to delete
    if comment.user != request.user:
        return Response(
            {'error': 'You can only delete your own comments'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    comment.delete()
    return Response(
        {'message': 'Comment deleted successfully'},
        status=status.HTTP_204_NO_CONTENT
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_posts(request):
    """
    Get all posts by the current user
    """
    posts = CommunityPost.objects.filter(
        author=request.user
    ).select_related('author').prefetch_related('likes', 'comments').order_by('-created_at')
    
    serializer = CommunityPostSerializer(posts, many=True, context={'request': request})
    return Response(serializer.data)

