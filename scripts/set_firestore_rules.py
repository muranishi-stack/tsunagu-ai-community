"""
Set Firestore Security Rules for TSUNAGU
=========================================

This script sets development-friendly security rules so the Flutter app
can read/write data during development. For production, replace with
stricter rules.

Usage:
    python3 scripts/set_firestore_rules.py
"""

import os
import sys
import json
import google.auth
from google.auth.transport.requests import Request
from google.oauth2 import service_account

FIREBASE_KEY_PATH = "/opt/flutter/firebase-admin-sdk.json"

# Development rules (allow authenticated reads, allow admin SDK writes from server)
# WARNING: Tighten these before production!
DEV_RULES = """rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // TSUNAGU development rules
    // Allow read for everyone (anonymized public data)
    // Allow write only for authenticated users on their own data
    // Server-side (Admin SDK) bypasses these rules

    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if false;  // Only admin can modify
    }

    match /transactions/{txId} {
      allow read: if request.auth != null;
      allow write: if false;  // Only server-side
    }

    match /announcements/{annId} {
      allow read: if true;
      allow write: if false;  // Only admin
    }

    match /ai_flags/{flagId} {
      allow read: if request.auth != null;
      allow write: if false;  // Only AI scanner (server)
    }

    // Default: deny all
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
"""


def get_access_token():
    """Get an OAuth2 access token from the service account."""
    if not os.path.exists(FIREBASE_KEY_PATH):
        print(f"❌ Firebase admin key not found at: {FIREBASE_KEY_PATH}")
        sys.exit(1)

    credentials_obj = service_account.Credentials.from_service_account_file(
        FIREBASE_KEY_PATH,
        scopes=["https://www.googleapis.com/auth/firebase",
                "https://www.googleapis.com/auth/cloud-platform"]
    )
    credentials_obj.refresh(Request())
    return credentials_obj.token


def get_project_id():
    """Extract project ID from the admin SDK file."""
    with open(FIREBASE_KEY_PATH) as f:
        data = json.load(f)
    return data.get("project_id")


def set_rules(rules_content):
    """Update Firestore security rules via Firebase Management API."""
    import urllib.request
    import urllib.error

    token = get_access_token()
    project_id = get_project_id()
    print(f"📋 Project ID: {project_id}")

    # Step 1: Create a new ruleset
    print("\n📝 Creating new ruleset...")
    create_url = f"https://firebaserules.googleapis.com/v1/projects/{project_id}/rulesets"
    create_body = {
        "source": {
            "files": [
                {
                    "name": "firestore.rules",
                    "content": rules_content,
                }
            ]
        }
    }

    req = urllib.request.Request(
        create_url,
        data=json.dumps(create_body).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
            ruleset_name = result.get("name")
            print(f"✅ Created ruleset: {ruleset_name}")
    except urllib.error.HTTPError as e:
        print(f"❌ Failed to create ruleset: {e.code} {e.reason}")
        print(e.read().decode())
        sys.exit(1)

    # Step 2: Release the ruleset to cloud.firestore
    print("\n🚀 Releasing ruleset to cloud.firestore...")
    release_url = f"https://firebaserules.googleapis.com/v1/projects/{project_id}/releases/cloud.firestore"
    release_body = {
        "release": {
            "name": f"projects/{project_id}/releases/cloud.firestore",
            "rulesetName": ruleset_name,
        }
    }

    req = urllib.request.Request(
        release_url,
        data=json.dumps(release_body).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="PATCH",  # Use PATCH to update existing release
    )
    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
            print(f"✅ Released: {result.get('name')}")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            # Try creating instead
            print("   Release doesn't exist, creating new one...")
            create_release_url = f"https://firebaserules.googleapis.com/v1/projects/{project_id}/releases"
            req = urllib.request.Request(
                create_release_url,
                data=json.dumps(release_body).encode(),
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json",
                },
                method="POST",
            )
            with urllib.request.urlopen(req) as resp:
                result = json.loads(resp.read())
                print(f"✅ Created release: {result.get('name')}")
        else:
            print(f"❌ Failed to release: {e.code} {e.reason}")
            print(e.read().decode())
            sys.exit(1)


def main():
    print("=" * 60)
    print("🛡️  Setting Firestore Security Rules for TSUNAGU")
    print("=" * 60)
    set_rules(DEV_RULES)
    print("\n" + "=" * 60)
    print("🎉 Firestore rules updated!")
    print("=" * 60)
    print("\n💡 Verify in Firebase Console:")
    print("   https://console.firebase.google.com/project/tsunagu-ai-community/firestore/rules")


if __name__ == "__main__":
    main()
