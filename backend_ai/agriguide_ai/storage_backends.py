# Create this file in your project root (same level as settings.py)
# agriguide_ai/storage_backends.py

from storages.backends.s3boto3 import S3Boto3Storage
from django.conf import settings


class MediaStorage(S3Boto3Storage):
    """Custom storage for media files (user uploads)"""
    location = 'media'
    file_overwrite = False
    default_acl = 'public-read'


class ProfilePictureStorage(S3Boto3Storage):
    """Storage for profile pictures"""
    location = 'media/profile_pics'
    file_overwrite = False
    default_acl = 'public-read'


class TutorialVideoStorage(S3Boto3Storage):
    """Storage for tutorial videos"""
    location = 'media/tutorials/videos'
    file_overwrite = False
    default_acl = 'public-read'


class TutorialThumbnailStorage(S3Boto3Storage):
    """Storage for tutorial thumbnails"""
    location = 'media/tutorials/thumbnails'
    file_overwrite = False
    default_acl = 'public-read'


class CommunityPostImageStorage(S3Boto3Storage):
    """Storage for community post images"""
    location = 'media/community_posts'
    file_overwrite = False
    default_acl = 'public-read'


class VerificationDocumentStorage(S3Boto3Storage):
    """Storage for verification documents"""
    location = 'media/verification_docs'
    file_overwrite = False
    default_acl = 'private'  # Keep verification docs private