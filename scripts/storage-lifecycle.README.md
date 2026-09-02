# Storage lifecycle policy

`storage-lifecycle.json` deletes scan images 30 days after upload.

It is deliberately free of comments and carries only the `rule` key, because
`gcloud storage buckets update --lifecycle-file` parses it as a Cloud Storage
lifecycle document — a `lifecycle` wrapper or a `_comment` field is rejected.
The explanation therefore lives here.

## Why

Scan images are input to an AI call, not user content: the app renders meal
history from the copy on the device, with the remote URL only as a fallback.
Keeping them forever costs roughly 20 TB/year at a million users for data
nothing reads after the scan completes.

## Why scans live at `scans/{uid}/...`

A lifecycle rule matches an object-name **prefix** and cannot wildcard a path
segment. Under the old `users/{uid}/scans/...` layout no rule could reach the
scan images without also matching `users/{uid}/progress_photos/...`, which must
be kept. Moving scans to their own root makes the rule a single line and keeps
it away from anything the user owns long-term.

## Applying it

```
gcloud storage buckets update gs://snapcal-ef333.firebasestorage.app \
  --lifecycle-file=scripts/storage-lifecycle.json \
  --project=snapcal-ef333
```

Verify:

```
gcloud storage buckets describe gs://snapcal-ef333.firebasestorage.app \
  --format="value(lifecycle)" --project=snapcal-ef333
```

Deletion is permanent and applies to existing objects as soon as the policy
lands. Confirm the age threshold before running it against production.

## Legacy objects

Anything already uploaded under `users/{uid}/scans/` cannot be expressed as a
lifecycle rule without also matching progress photos. Sweep those once with a
script that lists the bucket and deletes objects matching `users/*/scans/*`,
rather than widening the policy. There should be very few — the async upload
pipeline has no caller in the Flutter client.
