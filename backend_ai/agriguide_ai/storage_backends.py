# agriguide_ai/storage_backends.py - UPDATED

from storages.backends.s3boto3 import S3Boto3Storage
from django.conf import settings


class ProfilePictureStorage(S3Boto3Storage):
    """Storage for profile pictures"""
    location = 'media/profile_pics'
    file_overwrite = False
    default_acl = None  # Remove ACL


class TutorialVideoStorage(S3Boto3Storage):
    """Storage for tutorial videos"""
    location = 'media/tutorials/videos'
    file_overwrite = False
    default_acl = None  # Remove ACL


class TutorialThumbnailStorage(S3Boto3Storage):
    """Storage for tutorial thumbnails"""
    location = 'media/tutorials/thumbnails'
    file_overwrite = False
    default_acl = None  # Remove ACL


class CommunityPostImageStorage(S3Boto3Storage):
    """Storage for community post images"""
    location = 'media/community_posts'
    file_overwrite = False
    default_acl = None  # Remove ACL


class VerificationDocumentStorage(S3Boto3Storage):
    """Storage for verification documents"""
    location = 'media/verification_docs'
    file_overwrite = False
    default_acl = None  # Remove ACL, use bucket policy instead