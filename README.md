# NutriSense

NutriSense is a Flutter/Firebase health and wellness prototype for students. It helps users manage class schedules, study focus, workouts, meal recommendations, daily quests, reminders, and basic wellness analytics.

## Tech Stack

- Flutter / Dart
- Firebase Authentication
- Cloud Firestore
- Rule-based recommendation logic
- Local recipe and exercise catalogs

## Implemented Prototype Flow

1. Register or log in with Firebase Authentication.
2. Select study, workout, and wellness goals.
3. Complete the health profile:
   - age
   - gender
   - height
   - weight
   - activity level
   - fitness goal
   - dietary preference
   - medical conditions
   - allergies
   - mood/wellness status
4. Open the Home dashboard to view real user-specific summaries.
5. Use Quick Actions to add class schedules.
6. View saved schedules and study tasks on the Study page.
7. Generate a workout plan from schedule availability and health profile data.
8. Generate meal recommendations from ingredients and health profile filters.
9. Complete daily quests and review progress on Home/Profile.
10. Log out and log back in to verify Firestore persistence.

## Firestore Data

User data is scoped under:

```text
users/{uid}
users/{uid}/healthProfile/current
users/{uid}/schedules/{classId}
users/{uid}/studyTasks/{taskId}
users/{uid}/studySessions/{sessionId}
users/{uid}/workoutPlans/{planId}
users/{uid}/mealLogs/{mealId}
users/{uid}/mealRecommendations/{recommendationId}
users/{uid}/dailyQuests/{questId}
users/{uid}/reminders/{reminderId}
users/{uid}/wellnessLogs/{logId}
```

## Run

```bash
flutter pub get
flutter run
```

For verification:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Presentation Notes

The recommendation system is intentionally rule-based for a realistic school prototype. It does not claim to use a live AI or external nutrition API. Meal and workout suggestions are generated from local catalogs and saved to Firestore as user data.
