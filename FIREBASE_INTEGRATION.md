# Firebase Multi-Provider Authentication Integration

This document outlines the Firebase integration for supporting Google, Facebook, and Microsoft authentication across your Make It Exist application.

## Overview

The application now supports **four authentication methods**:
1. **Google Sign-In** (via Google ID token)
2. **Facebook Sign-In** (via Firebase)
3. **Microsoft Sign-In** (via Firebase)
4. **Email/Password** (admin fallback)

All authentication flows eventually call the backend `/api/v1/auth/firebase` endpoint (or `/api/v1/auth/google` for backward compatibility).

---

## Backend Changes

### Domain Models (`backend/internal/domain/user.go`)

Added new fields to the `User` struct:
```go
type User struct {
    // ... existing fields ...
    Provider    string `json:"provider"`     // google, facebook, microsoft, email
    ProviderID  string `json:"-"`            // provider-specific user ID
}
```

### New Request Type (`backend/internal/domain/user.go`)

```go
type FirebaseAuthRequest struct {
    IDToken  string `json:"id_token" binding:"required"`
    Provider string `json:"provider" binding:"required"` // google, facebook, microsoft
}
```

### New Service Method (`backend/internal/service/auth_service.go`)

```go
func (s *authService) FirebaseLogin(ctx context.Context, req *domain.FirebaseAuthRequest) (*domain.AuthResponse, error)
```

Handles multi-provider authentication:
- Verifies Google ID tokens directly
- Supports Facebook and Microsoft (verification placeholder for production)
- Auto-creates or updates users based on provider
- Returns JWT tokens for frontend use

### New Handler (`backend/internal/handler/auth_handler.go`)

```go
func (h *AuthHandler) FirebaseLogin(c *gin.Context)
```

Endpoint: `POST /api/v1/auth/firebase`

Request:
```json
{
  "id_token": "firebase_id_token_here",
  "provider": "google" | "facebook" | "microsoft"
}
```

Response:
```json
{
  "message": "Login successful",
  "data": {
    "token": "jwt_token",
    "refresh_token": "refresh_token",
    "user": {
      "id": "user-uuid",
      "email": "user@domain.com",
      "full_name": "User Name",
      "provider": "google",
      "role": "student"
    }
  }
}
```

### Database Migration

Updated schema to add new columns:
```sql
ALTER TABLE users ADD COLUMN provider VARCHAR(50) DEFAULT 'email' 
                                  CHECK (provider IN ('email', 'google', 'facebook', 'microsoft'));
ALTER TABLE users ADD COLUMN provider_id VARCHAR(255);
CREATE INDEX idx_users_provider ON users(provider);
```

### Router Configuration (`backend/internal/router/router.go`)

New route added:
```go
auth.POST("/firebase", authHandler.FirebaseLogin)
```

---

## Frontend Changes

### Dependencies (`frontend/pubspec.yaml`)

Added Firebase packages:
```yaml
firebase_core: ^2.24.0
firebase_auth: ^4.14.0
google_sign_in: ^6.2.1
sign_in_with_apple: ^5.0.0
```

### Auth Repository (`frontend/lib/data/repositories/auth_repository.dart`)

Three new sign-in methods:

```dart
Future<AuthResponse> signInWithFacebook()
Future<AuthResponse> signInWithMicrosoft()
```

All methods:
1. Get user credentials from the respective OAuth provider (via Firebase)
2. Extract the ID token
3. Send to `/api/v1/auth/firebase` endpoint
4. Save JWT tokens locally

### Auth Events (`frontend/lib/presentation/blocs/auth/auth_event.dart`)

New events:
```dart
class AuthFacebookSignIn extends AuthEvent {}
class AuthMicrosoftSignIn extends AuthEvent {}
```

### Auth BLoC (`frontend/lib/presentation/blocs/auth/auth_bloc.dart`)

Handlers:
```dart
on<AuthFacebookSignIn>(_onFacebookSignIn)
on<AuthMicrosoftSignIn>(_onMicrosoftSignIn)
```

### Login Screen UI (`frontend/lib/presentation/screens/auth/login_screen.dart`)

Added three sign-in buttons:
- **Google Sign-In Button** (white background, Google logo)
- **Facebook Sign-In Button** (Facebook blue #1877F2)
- **Microsoft Sign-In Button** (Microsoft blue #0078D4)

### API Endpoints (`frontend/lib/core/constants/api_endpoints.dart`)

New endpoint:
```dart
static const String firebaseLogin = '/auth/firebase';
```

### Web Configuration (`frontend/web/index.html`)

Added Firebase SDK initialization:
```html
<script type="module">
  import { initializeApp } from "https://www.gstatic.com/firebasejs/10.0.0/firebase-app.js";
  // Firebase configuration and initialization
</script>
```

---

## Setup Instructions

### 1. Configure Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select existing
3. Enable authentication methods:
   - **Google**: Automatic (built-in)
   - **Facebook**: Configure OAuth app at [Facebook Developers](https://developers.facebook.com)
   - **Microsoft**: Configure Azure AD application

### 2. Backend Configuration

Update `render.yaml` with Firebase credentials:
```yaml
envVars:
  - key: FIREBASE_API_KEY
    value: "your-firebase-api-key"
  - key: FIREBASE_PROJECT_ID
    value: "your-project-id"
  - key: FIREBASE_MESSAGING_SENDER_ID
    value: "your-sender-id"
  - key: FIREBASE_APP_ID
    value: "your-app-id"
```

### 3. Frontend Configuration

Update `frontend/web/index.html` with Firebase config (auto-replaced during build):
```html
<meta name="firebase-api-key" content="%FIREBASE_API_KEY%">
```

Or use `--dart-define` during build:
```bash
flutter build web \
  --dart-define=GOOGLE_AUTH_CLIENT_ID=your-client-id \
  --dart-define=FIREBASE_API_KEY=your-api-key
```

### 4. Deploy Database Migration

Run migration to add provider columns:
```sql
-- Already included in 001_initial_schema.up.sql
-- Run migrations on your database
```

---

## Testing

### Manual Testing

#### Google Sign-In
1. Click "Sign in with Google"
2. Select Gmail account
3. Should redirect to home after JWT token received

#### Facebook Sign-In
1. Click "Sign in with Facebook"
2. Authorize app access to profile
3. Should redirect to home after JWT token received

#### Microsoft Sign-In
1. Click "Sign in with Microsoft"
2. Authorize app access to profile
3. Should redirect to home after JWT token received

#### Email/Password
1. Enter admin credentials (admin@aim.edu / admin)
2. Should redirect to home after JWT token received

### API Testing

```bash
# Test Firebase endpoint
curl -X POST http://localhost:8080/api/v1/auth/firebase \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "firebase-token-here",
    "provider": "google"
  }'

# Test backward-compatible Google endpoint
curl -X POST http://localhost:8080/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "google-token-here"
  }'

# Test email/password endpoint
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@aim.edu",
    "password": "admin"
  }'
```

---

## Production Considerations

### Token Verification

**Current Implementation:**
- Google tokens are verified against Google's tokeninfo endpoint
- Facebook and Microsoft tokens are logged with a warning (placeholder)

**Production Upgrade Required:**
- Implement proper Facebook token verification via Facebook API
- Implement proper Microsoft token verification via Azure AD
- Use Firebase Admin SDK for server-side token verification

### Environment Variables

Keep these secrets in environment:
- `GOOGLE_AUTH_CLIENT_ID` - Public Google OAuth client ID
- `FIREBASE_API_KEY` - Firebase public API key
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `JWT_SECRET` - Your JWT signing secret (never expose)

### Database

Ensure indexes are created:
```sql
CREATE INDEX idx_users_provider ON users(provider);
CREATE INDEX idx_users_email ON users(email);
```

### CORS Configuration

Update `CORS_ALLOWED_ORIGINS` in Render deployment to include your Firebase domain.

---

## User Flow Diagram

```
┌──────────────────┐
│  Login Screen    │
│  (4 Options)     │
└────────┬─────────┘
         │
    ┌────┴────────────────────────┬──────────────┬────────────────┐
    │                             │              │                │
    ▼                             ▼              ▼                ▼
┌────────────┐    ┌──────────┐ ┌────────────┐ ┌──────────┐ ┌──────────┐
│   Google   │    │ Facebook │ │ Microsoft  │ │  Email   │ │ Existing │
│ Sign-In    │    │ Sign-In  │ │ Sign-In    │ │Password  │ │  Users   │
│ OAuth      │    │ Firebase │ │ Firebase   │ │ (Admin)  │ │  (SSO)   │
└─────┬──────┘    └────┬─────┘ └────┬───────┘ └────┬─────┘ └────┬─────┘
      │                │            │              │             │
      └────────────────┴────────────┴──────────────┴─────────────┘
                                │
                    ┌───────────▼──────────┐
                    │  ID Token / Token    │
                    │  Backend Validation  │
                    └───────────┬──────────┘
                                │
                ┌───────────────▼──────────────┐
                │ POST /auth/firebase          │
                │ or /auth/google              │
                │ or /auth/login               │
                └───────────────┬──────────────┘
                                │
                    ┌───────────▼──────────┐
                    │ Create/Update User   │
                    │ Generate JWT Token   │
                    └───────────┬──────────┘
                                │
                    ┌───────────▼──────────┐
                    │ Return Tokens &      │
                    │ User Profile         │
                    └───────────┬──────────┘
                                │
                    ┌───────────▼──────────┐
                    │ Save Tokens Locally  │
                    │ Redirect to /home    │
                    └──────────────────────┘
```

---

## Troubleshooting

### Google Sign-In fails with "client_id mismatch"
- Verify `GOOGLE_AUTH_CLIENT_ID` matches your OAuth credential
- Check `frontend/web/index.html` has correct meta tag

### Facebook authentication not working
- Ensure Facebook App ID is configured in Firebase Console
- Check Facebook app status (in development mode must be admin/tester)
- Verify redirect URIs are whitelisted

### Microsoft authentication not working
- Ensure Azure AD app is registered in Firebase Console
- Check redirect URI matches your deployment domain
- Verify app permissions are granted

### Users not created after sign-in
- Check database connection string
- Verify migration was run and columns exist
- Check backend logs for error messages

---

## Next Steps

1. **Set up Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create project
   - Enable Google, Facebook, Microsoft providers

2. **Get Credentials**
   - Google: OAuth 2.0 Client ID from Google Cloud Console
   - Facebook: App ID and App Secret from Facebook Developers
   - Microsoft: Application ID from Azure AD

3. **Update Configuration Files**
   - Update `render.yaml` with Firebase credentials
   - Update `frontend/web/index.html` with Firebase config

4. **Deploy**
   - Commit changes: `git add -A && git commit -m "feat: Add Firebase multi-provider auth"`
   - Push to Render: `git push origin main`
   - Monitor deployment logs

5. **Test**
   - Test each sign-in method
   - Verify user profiles are created correctly
   - Check JWT tokens are generated and stored

---

## References

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Google Sign-In Documentation](https://developers.google.com/identity/sign-in/web)
- [Facebook Login Docs](https://developers.facebook.com/docs/facebook-login)
- [Microsoft Identity Docs](https://learn.microsoft.com/en-us/azure/active-directory/develop/)
- [Flutter Firebase Plugin](https://pub.dev/packages/firebase_auth)

