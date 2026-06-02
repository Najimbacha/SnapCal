import { readFileSync } from 'node:fs';
import test from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  ref,
  uploadBytes,
  getBytes,
  deleteObject,
} from 'firebase/storage';

let env;

test.before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'snapcal-storage-security-test',
    storage: {
      rules: readFileSync('../storage.rules', 'utf8'),
    },
  });
});

test.after(async () => {
  await env.cleanup();
});

function storageFor(uid) {
  return env.authenticatedContext(uid).storage();
}

test('owner can upload and read a valid private scan image', async () => {
  const storage = storageFor('alice');
  const path = 'users/alice/scans/scan12345/scan.jpg';
  await assertSucceeds(uploadBytes(ref(storage, path), new Uint8Array([1, 2, 3]), {
    contentType: 'image/jpeg',
  }));
  await assertSucceeds(getBytes(ref(storage, path)));
});

test('users cannot access another user scan image', async () => {
  const alicePath = 'users/alice/scans/scan12345/scan.jpg';
  await assertFails(uploadBytes(ref(storageFor('bob'), alicePath), new Uint8Array([1]), {
    contentType: 'image/jpeg',
  }));
  await assertFails(getBytes(ref(storageFor('bob'), alicePath)));
  await assertFails(deleteObject(ref(storageFor('bob'), alicePath)));
});

test('non-image and oversized uploads are denied', async () => {
  const storage = storageFor('alice');
  await assertFails(uploadBytes(ref(storage, 'users/alice/scans/scan12345/file.txt'), new Uint8Array([1]), {
    contentType: 'text/plain',
  }));
  await assertFails(uploadBytes(
    ref(storage, 'users/alice/scans/scan12345/huge.jpg'),
    new Uint8Array(5 * 1024 * 1024 + 1),
    { contentType: 'image/jpeg' },
  ));
});

test('signed out access and arbitrary paths are denied', async () => {
  await assertFails(uploadBytes(ref(env.unauthenticatedContext().storage(), 'users/alice/scans/scan12345/scan.jpg'), new Uint8Array([1]), {
    contentType: 'image/jpeg',
  }));
  await assertFails(uploadBytes(ref(storageFor('alice'), 'public/scan.jpg'), new Uint8Array([1]), {
    contentType: 'image/jpeg',
  }));
});
