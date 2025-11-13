# agriguide_ai/deep_link_views.py
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.shortcuts import render
from django.http import JsonResponse
from .models import CommunityPost
from .serializers import CommunityPostSerializer


@api_view(['GET'])
@permission_classes([AllowAny])  # Allow unauthenticated access for sharing
def post_deep_link_data(request, post_id):
    """
    API endpoint to fetch post data for deep links
    This endpoint doesn't require authentication to allow previews in messaging apps
    
    Returns post data in JSON format for the Flutter app
    """
    try:
        post = CommunityPost.objects.select_related('author').prefetch_related('likes', 'comments').get(pk=post_id)
        
        # Serialize the post with context
        serializer = CommunityPostSerializer(post, context={'request': request})
        
        return Response({
            'success': True,
            'post': serializer.data
        }, status=status.HTTP_200_OK)
        
    except CommunityPost.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Post not found',
            'message': 'The post you are looking for does not exist or has been deleted.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'error': 'Server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def post_fallback_view(request, post_id):
    """
    Web fallback page when app is not installed
    Shows a download page with post preview
    """
    try:
        post = CommunityPost.objects.select_related('author').get(pk=post_id)
        
        # Get post author name
        author_name = post.author.get_full_name() or post.author.username
        
        # Truncate content for preview
        content_preview = post.content[:150] + '...' if len(post.content) > 150 else post.content
        
        context = {
            'post': post,
            'author_name': author_name,
            'content_preview': content_preview,
            'app_store_link': 'https://play.google.com/store/apps/details?id=com.yourcompany.agriguide',
            'ios_store_link': 'https://apps.apple.com/app/agriguide/id123456789',  # Add when iOS is ready
        }
        
        return render(request, 'post_fallback.html', context)
        
    except CommunityPost.DoesNotExist:
        # Render a not found page
        context = {
            'error': 'Post not found',
            'message': 'The post you are looking for does not exist or has been deleted.',
            'app_store_link': 'https://play.google.com/store/apps/details?id=com.yourcompany.agriguide',
        }
        return render(request, 'post_not_found.html', context, status=404)


@api_view(['GET'])
@permission_classes([AllowAny])
def generate_share_metadata(request, post_id):
    """
    Generate Open Graph metadata for rich link previews in messaging apps
    Used by the fallback page to show rich previews
    """
    try:
        post = CommunityPost.objects.select_related('author').get(pk=post_id)
        
        author_name = post.author.get_full_name() or post.author.username
        content_preview = post.content[:200] + '...' if len(post.content) > 200 else post.content
        
        metadata = {
            'og:title': f'Post by {author_name} on AgriGuide',
            'og:description': content_preview,
            'og:type': 'article',
            'og:url': f'https://my-app-domain.com/post/{post_id}',
            'og:site_name': 'AgriGuide Community',
        }
        
        # Add image if available
        if post.image:
            metadata['og:image'] = request.build_absolute_uri(post.image.url)
        
        return Response({
            'success': True,
            'metadata': metadata
        })
        
    except CommunityPost.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Post not found'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([AllowAny])
def track_share_analytics(request, post_id):
    """
    Optional: Track when posts are shared
    Can be called from Flutter when share is successful
    """
    try:
        post = CommunityPost.objects.get(pk=post_id)
        
        # You can add a share_count field to your model and increment it
        # Or log to analytics service
        
        # For now, just return success
        return Response({
            'success': True,
            'message': 'Share tracked successfully'
        })
        
    except CommunityPost.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Post not found'
        }, status=status.HTTP_404_NOT_FOUND)