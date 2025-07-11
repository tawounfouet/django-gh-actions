from django.test import TestCase
from .models import Post

# Create your tests here.


class PostModelTest(TestCase):
    def setUp(self):
        Post.objects.create(title="Test Post", body="This is a test post.")

    def test_post_creation(self):
        post = Post.objects.get(title="Test Post")
        self.assertEqual(post.body, "This is a test post.")

    def test_post_str(self):
        post = Post.objects.get(title="Test Post")
        self.assertEqual(str(post), "Test Post")

    def test_post_created_auto_now_add(self):
        post = Post.objects.get(title="Test Post")
        self.assertIsNotNone(post.created_at)

    def test_post_ordering(self):
        posts = Post.objects.all()
        self.assertEqual(posts[0].title, "Test Post")  # Assuming this is the only post
