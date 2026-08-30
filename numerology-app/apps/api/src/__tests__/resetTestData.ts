/**
 * Removes rows created by previous test runs so each run starts from the
 * seeded content only. Seeded numerology content, rules and the administrator
 * account are left untouched.
 *
 * Guarded so it can only ever run against the test database.
 */
import { PrismaClient } from '@prisma/client';

async function main() {
  if (!/numerology_test/.test(process.env.DATABASE_URL ?? '')) {
    throw new Error('resetTestData refuses to run outside the test database.');
  }

  const prisma = new PrismaClient();
  try {
    await prisma.analyticsEvent.deleteMany({});
    await prisma.auditLog.deleteMany({});
    await prisma.favourite.deleteMany({});
    await prisma.calculationHistory.deleteMany({});
    await prisma.deviceToken.deleteMany({});
    await prisma.refreshToken.deleteMany({});
    await prisma.userProfile.deleteMany({});
    await prisma.userPreference.deleteMany({});
    await prisma.user.deleteMany({});
    await prisma.adminRefreshToken.deleteMany({});
  } finally {
    await prisma.$disconnect();
  }
}

void main();
