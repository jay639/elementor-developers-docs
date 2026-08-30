import path from 'node:path';
import dotenv from 'dotenv';

// Loaded before any test file imports the application, so the API connects to
// the test database and never to a development or production one.
dotenv.config({ path: path.resolve(__dirname, '../../.env.test'), override: true });
