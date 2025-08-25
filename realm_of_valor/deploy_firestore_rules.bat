@echo off
echo Deploying Firestore security rules...
firebase deploy --only firestore:rules
echo Firestore rules deployed successfully!
pause
