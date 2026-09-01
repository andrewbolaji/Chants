# Change rationale: Production preflight and device gate

## Boundary

Andrew asked Codex to continue after the configured physical iPhone opened the development-signed release client. This Lane 1 evidence block refreshes production read-only, reconciles the owner guide and records the next decision. It does not create resources, change IAM, Auth, Firestore, Storage, Scheduler or Hosting, deploy code, repair data, run a destructive test, publish policy, change the 17+ rule or change store territories.

The source candidate is merged commit `c3a071cfea70f68cd4d8f76d26561843d7478c31`, tree `2d59b99cd2539c42007ae728b54b25e397fad2b2`, previously verified by all eight CI jobs in run `33408526284`. Current staged work is documentation and launch-guide code only.

## Evidence

- Production remains on nine July Node 20 Gen 2 Functions in `europe-west2`, all using the default Compute runtime. Reviewed source exports 48 Node 22 Functions with a dedicated runtime identity that does not yet exist.
- The two callable Cloud Run services are public; the seven event services are not. All report triggers and source-generation evidence remain predecessor state.
- Firestore `(default)` remains Native mode in `nam5`, with old rules, two of 16 indexes, PITR disabled and delete protection disabled. No second database or deny policy exists.
- Cloud Storage API is enabled, but there is no Firebase app-media bucket. Only the two managed Functions buckets exist. Scheduler is disabled. `gcf-artifacts` retains the observed one-day delete policy.
- The Compute and Appspot service accounts retain Editor. The Firebase Admin SDK account has two user-managed keys. No key identifier, owner, contact value or raw IAM response is stored here.
- Auth contains one enabled password account. Email/password registration is enabled; phone and anonymous are disabled; no supported external identity provider or Auth blocking function is configured. The check returned counts and enabled states only.
- Aggregate production content remains 20 teams, 622 players, 192 chants, one profile, four comments, one chant report and one feedback row. Media, creator and deletion/cleanup backlogs were zero. Counts are separate observations, not a paused snapshot.
- The physical release client reached placeholder policy copy. Source deletion replaces attribution on contributed bodies, omits `performanceUploadLimits`, lacks account-owned published-media removal and has no public deletion request route.

One Firebase CLI status command unexpectedly exposed credential material in local tool output. The session was immediately revoked and reauthenticated. Project memory contains no token, account or raw response. The reusable prevention rule is recorded in `docs/LEARNINGS.md`.

## Decision

Do not deploy the merged backend yet. A maintenance-only infrastructure rollout would not enable a truthful device journey and would require a second backend migration soon afterward. Deploying `acceptPolicy` would record acceptance of unfinished copy. Deploying current deletion behavior would contradict the policy target.

The smallest next block is one separately approved V1 launch policy and deletion source closure. It integrates the public-policy destinations and honest versioning, deletes account-authored contributions and media while preserving catalogue/thread integrity, covers upload limits, provides an identity-verified external request route into the same durable workflow and makes retention promises implementable. It keeps the age rule and all live systems unchanged.

After that block passes exact-head CI and independent review, refresh production once and prepare the Lane 3 packet with exact principals, key disposition, deny/invoker containment, recovery resources, costs, test exposure, stages, stop conditions and attended window.

## Verification and recovery

Official Google documentation was checked for current IAM deny support/propagation, Firestore PITR, managed export/import and Functions runtime options. The guide regressions and staged governance checks are recorded in `docs/EXECUTION.md` after completion.

Reverting this documentation boundary does not affect production or the installed app. The Firebase session containment already occurred and is not undone by Git. No live rollback is needed because no live state changed.
