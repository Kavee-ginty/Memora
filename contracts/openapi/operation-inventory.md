# Operation inventory

Stable operation IDs for the Memora HTTP surface. Published IDs are permanent. `/v1` IDs begin with a verb; `healthLive` and `healthReady` are grandfathered.

| Domain | Method | Path | Operation ID | Auth | Idempotency | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| Health | GET | `/health/live` | `healthLive` | Public | Read | T01 |
| Health | GET | `/health/ready` | `healthReady` | Public | Read | T02 |
| Session | GET | `/v1/session/bootstrap` | `bootstrapSession` | Bearer | Read | T06 |
| Session | POST | `/v1/session/revoke` | `revokeSession` | Bearer | Header | T06 |
| Session | POST | `/v1/devices` | `registerDevice` | Bearer | Header | T06 |
| Session | DELETE | `/v1/devices/{device_id}` | `deleteDevice` | Bearer | Natural | T06 |
| Profile | GET | `/v1/profile` | `getProfile` | Bearer | Read | T17 |
| Profile | PATCH | `/v1/profile` | `updateProfile` | Bearer | Version + header | T17 |
| Profile | GET | `/v1/profile/preferences` | `getProfilePreferences` | Bearer | Read | T17 |
| Profile | PATCH | `/v1/profile/preferences` | `updateProfilePreferences` | Bearer | Version + header | T17 |
| Consent | GET | `/v1/consent` | `getConsent` | Bearer | Read | T06 |
| Consent | POST | `/v1/consent/acceptances` | `acceptConsent` | Bearer | Header | T06 |
| Home | GET | `/v1/home` | `getHome` | Bearer | Read | T13/T15 |
| Curriculum | GET | `/v1/subjects` | `listSubjects` | Bearer | Read | T08 |
| Curriculum | GET | `/v1/subjects/{subject_id}` | `getSubject` | Bearer | Read | T08 |
| Curriculum | GET | `/v1/subjects/{subject_id}/learning-path` | `getLearningPath` | Bearer | Read | T08 |
| Curriculum | GET | `/v1/subjects/{subject_id}/concept-progress` | `listConceptProgress` | Bearer | Read | T11/T15 |
| Curriculum | GET | `/v1/concepts/{concept_id}/history` | `getConceptHistory` | Bearer | Read | T11 |
| Learning | POST | `/v1/learning-updates` | `createLearningUpdate` | Bearer | Header | T09 |
| Learning | GET | `/v1/learning-updates` | `listLearningUpdates` | Bearer | Read | T09 |
| Learning | GET | `/v1/learning-updates/{update_id}` | `getLearningUpdate` | Bearer | Read | T09 |
| Learning | PATCH | `/v1/learning-updates/{update_id}` | `updateLearningUpdate` | Bearer | Version + header | T09 |
| Learning | DELETE | `/v1/learning-updates/{update_id}` | `deleteLearningUpdate` | Bearer | Header | T09 |
| Learning | POST | `/v1/learning-updates/{update_id}/uploads` | `createUploadGrant` | Bearer | Header | T09 |
| Learning | POST | `/v1/learning-updates/{update_id}/uploads/{upload_id}/finalize` | `finalizeUpload` | Bearer | Header | T09 |
| Learning | POST | `/v1/learning-updates/{update_id}/retry` | `retryLearningUpdate` | Bearer | Header | T09 |
| Verification | GET | `/v1/learning-updates/{update_id}/candidates` | `listExtractionCandidates` | Bearer | Read | T09 |
| Verification | POST | `/v1/learning-updates/{update_id}/verification-decisions` | `submitVerificationDecisions` | Bearer | Version + header | T09 |
| Verification | GET | `/v1/learning-updates/{update_id}/preview` | `previewLearningPath` | Bearer | Read | T09 |
| Verification | POST | `/v1/learning-updates/{update_id}/commit` | `commitLearningUpdate` | Bearer | Header | T09 |
| Missions | GET | `/v1/missions/today` | `getTodayMission` | Bearer | Read | T13 |
| Missions | GET | `/v1/missions/{mission_id}` | `getMission` | Bearer | Read | T13 |
| Missions | POST | `/v1/missions/{mission_id}/start` | `startMission` | Bearer | Header | T13 |
| Missions | GET | `/v1/missions/{mission_id}/items/{item_id}` | `getMissionItem` | Bearer | Read | T13 |
| Missions | POST | `/v1/missions/{mission_id}/items/{item_id}/attempts` | `submitAttempt` | Bearer | `client_operation_id` | T13 |
| Missions | POST | `/v1/missions/{mission_id}/items/{item_id}/skip` | `skipMissionItem` | Bearer | Header | T13 |
| Missions | POST | `/v1/missions/{mission_id}/pause` | `pauseMission` | Bearer | Header | T13 |
| Missions | POST | `/v1/missions/{mission_id}/complete` | `completeMission` | Bearer | Header | T13 |
| Missions | GET | `/v1/missions/{mission_id}/results` | `getMissionResults` | Bearer | Read | T13 |
| Progress | GET | `/v1/seabed` | `getSeabed` | Bearer | Read | T15 |
| Progress | GET | `/v1/seabed/reefs/{subject_id}` | `getReef` | Bearer | Read | T15 |
| Progress | GET | `/v1/progress/statistics` | `getProgressStatistics` | Bearer | Read | T15 |
| Rewards | GET | `/v1/rewards` | `listRewards` | Bearer | Read | T15 |
| Rewards | PATCH | `/v1/rewards/{reward_grant_id}` | `updateRewardPlacement` | Bearer | Version + header | T15 |
| Reports | POST | `/v1/questions/{question_version_id}/reports` | `createQuestionReport` | Bearer | Header | T12 |
| Reports | GET | `/v1/question-reports` | `listQuestionReports` | Bearer | Read | T12 |
| Reports | GET | `/v1/question-reports/{report_id}` | `getQuestionReport` | Bearer | Read | T12 |
| Privacy | POST | `/v1/privacy/exports` | `createPrivacyExport` | Bearer + recent auth | Header | T20 |
| Privacy | GET | `/v1/privacy/exports/{request_id}` | `getPrivacyExport` | Bearer | Read | T20 |
| Privacy | POST | `/v1/privacy/deletions` | `createPrivacyDeletion` | Bearer + recent auth | Header | T20 |
| Privacy | GET | `/v1/privacy/deletions/{request_id}` | `getPrivacyDeletion` | Bearer | Read | T20 |
| Privacy | POST | `/v1/privacy/deletions/{request_id}/cancel` | `cancelPrivacyDeletion` | Bearer | Header | T20 |
