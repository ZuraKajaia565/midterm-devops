import json
import unittest

from app.server import app_response


class AppResponseTests(unittest.TestCase):
    def test_dynamic_route_uses_name(self):
        status, content_type, payload = app_response("GET", "/hello/Ana")

        self.assertEqual(status, 200)
        self.assertIn("text/html", content_type)
        self.assertIn(b"Hello", payload)
        self.assertIn(b"Ana", payload)

    def test_form_endpoint_accepts_message(self):
        status, _, payload = app_response("POST", "/message", "message=CI+works")

        self.assertEqual(status, 200)
        self.assertIn(b"CI works", payload)

    def test_health_endpoint_returns_ok_json(self):
        status, content_type, payload = app_response("GET", "/health")

        self.assertEqual(status, 200)
        self.assertEqual(content_type, "application/json")
        self.assertEqual(json.loads(payload)["status"], "ok")


if __name__ == "__main__":
    unittest.main()
