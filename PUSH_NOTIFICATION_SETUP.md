# Push Notification Setup - Deployment Guide

## 1. Database Migration

Run the SQL in `CREATE_FCM_TOKENS_TABLE.sql` in your Supabase SQL Editor.

## 2. Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `dabblersportapp`
3. Go to Project Settings → Service Accounts
4. Click **Generate New Private Key**
5. Download the JSON file (keep it secure!)

## 3. Deploy Edge Function

```bashirebase service account JSON as a secret (paste entire JSON content)
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"dabblersportapp",...}'

# Set your Firebase project ID
supabase secrets set FIREBASE_PROJECT_ID=dabblersportapp

# Deploy the function
supabase functions deploy send-push-notification
```

**Tip**: To set the JSON secret easily:
```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/your-service-account.json)"
supabase functions deploy send-push-notification
```

## 4. Usage Examples

### Send notification to a user:

```dart
// In your Dart code
final response = await supabase.functions.invoke(
  'send-push-notification',
  body: {
    'user_id': 'user-uuid-here',
    'title': 'New Game Invitation',
    'body': 'John invited you to play basketball',
    'data': {
      'type': 'game_invite',
      'game_id': 'game-123',
    },
  },
);
```

### Using curl:

```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/send-push-notification' \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user-uuid",
    "title": "Test Notification",
    "body": "This is a test message"
  }'
```

## 5. Integration Points

Use this Edge Function when:
- User receives a game invitation
- Friend request is received
- Game is canceled
- Check-in reminders
- Achievement unlocked
- New message received

Example integration in `join_game_usecase.dart`:

```dart
// Send notification to game organizer
await supabase.functions.invoke(
  'send-push-notification',
  body: {
    'user_id': game.createdBy,
    'title': 'New Player Joined',
    'body': '$playerName joined your ${game.sportName} game',
    'data': {
      'type': 'player_joined',
      'game_id': game.id,
    },
  },
);
```

## 6. Testing

1. Test with a device that has notifications enabled
2. Check Supabase Functions logs for errors
3. Verify tokens are being saved to `fcm_tokens` table

## Notes

- The Edge Function automatically filters out failed tokens
- Consider adding a cleanup job for expired/invalid tokens
- Monitor FCM quota limits (free tier: unlimited)
- For production, consider upgrading to FCM HTTP v1 API (more secure)
