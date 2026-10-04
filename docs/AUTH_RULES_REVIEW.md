# Authentication rule review

Database `rentride`, Enterprise Native, Mumbai. This is a manual code review, not an executed adversarial test suite. Compiler validation succeeded through Firebase Rules API; published release `cloud.firestore/rentride` points to ruleset `dfc683d2-ee62-4ec5-a09d-4436be89d1b1`.

The Flutter client only accesses `users/{currentUid}` by direct get/set/update; no collection queries, filters, sorts, limits or subcollections. Required profile fields: UID, nullable phoneNumber matched to token, displayName 2..60 chars, roles, onboardingCompleted true, createdAt and updatedAt timestamps. Email remains in Firebase Auth. Backend-only challenge and rate records live in `_emailOtp` and `_emailOtpRate`.

| Attack or invalid operation | Expected result from manual review |
|---|---|
| Unauthenticated profile read/list/write | Denied by ownership check |
| User B reads/writes User A | Denied by path UID ownership |
| Unverified email-only account accesses profile | Denied by verified identity check |
| Create/update UID hijack | Token/path equality plus immutable fields |
| Create/update with missing or unknown fields | Validator hasAll/hasOnly on both |
| Oversize name or phone, wrong field types | Validator rejects |
| Create host/admin role; update roles | New profile only customer; roles immutable for clients |
| Creation timestamp rewrite | Create equals request.time; immutable on update |
| Updated timestamp spoof | Must equal server request.time |
| Set phone belonging to another account | Must equal phone_number in Auth token |
| Clear onboarding or corrupt schema on update | Full validator on update |
| Read OTP hash/code or alter challenge attempts | Default deny for all non-profile paths |
| Orphaned user subcollection access | Default deny |
| Write private data into extra fields | hasOnly rejects |
| Public personal-information leak | Profiles never public |
| Client collection query requiring blanket access | Not used by app; no blanket access granted |
| Counter replay, URL traversal, price overflow | No such fields/operations; extras rejected |

Runtime adversarial checks should be performed after Auth is initialized, alongside physical-device delivery validation. No guarantee of exhaustive security is implied.
