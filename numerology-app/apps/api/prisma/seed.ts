/**
 * Database seed.
 *
 * Idempotent: every record is upserted, so the script can be re-run safely
 * against an existing database (for example after adding a new locale).
 *
 * Run with: npm run db:seed
 */
import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { PrismaClient, type Locale as PrismaLocale } from '@prisma/client';
import {
  DEFAULT_CHALDEAN_GROUPS,
  DEFAULT_MARRIAGE_RULES,
  DEFAULT_NUMBER_COMPATIBILITY_RULES,
} from '@numerology/core';
import { NUMBER_SEEDS, type SeedLocale } from './data/numbers';
import { buildAllCombinations } from './data/combinations';
import { buildDailyInsights } from './data/daily';
import { APP_SETTING_SEEDS, LEGAL_SEEDS } from './data/settings';

const prisma = new PrismaClient();
const LOCALES: SeedLocale[] = ['en', 'hi', 'mr'];

/** Permissions granted to each seeded administrator role. */
const ROLES = [
  {
    key: 'SUPER_ADMIN',
    name: 'Super Admin',
    description: 'Full access to every part of the admin panel.',
    permissions: [
      'analytics:read',
      'content:read',
      'content:write',
      'rules:read',
      'rules:write',
      'users:read',
      'users:write',
      'users:delete',
      'settings:read',
      'settings:write',
      'admins:read',
      'admins:write',
      'audit:read',
    ],
  },
  {
    key: 'CONTENT_ADMIN',
    name: 'Content Admin',
    description: 'Can edit numerology content, combinations, rules and Chaldean mappings.',
    permissions: ['analytics:read', 'content:read', 'content:write', 'rules:read', 'rules:write', 'settings:read'],
  },
  {
    key: 'SUPPORT_ADMIN',
    name: 'Support Admin',
    description: 'Can view users and their activity to answer support questions.',
    permissions: ['analytics:read', 'content:read', 'users:read', 'users:write', 'settings:read'],
  },
  {
    key: 'ANALYST',
    name: 'Analyst',
    description: 'Read-only access to analytics and content.',
    permissions: ['analytics:read', 'content:read', 'rules:read', 'settings:read'],
  },
];

async function seedRoles() {
  for (const role of ROLES) {
    await prisma.adminRole.upsert({
      where: { key: role.key },
      update: { name: role.name, description: role.description, permissions: role.permissions, isSystem: true },
      create: { ...role, isSystem: true },
    });
  }
  console.log(`  admin roles: ${ROLES.length}`);
}

async function seedSuperAdmin() {
  const email = process.env.SEED_ADMIN_EMAIL;
  const password = process.env.SEED_ADMIN_PASSWORD;
  const name = process.env.SEED_ADMIN_NAME ?? 'Super Admin';

  if (!email || !password) {
    console.log('  super admin: skipped (set SEED_ADMIN_EMAIL and SEED_ADMIN_PASSWORD to create one)');
    return;
  }

  const role = await prisma.adminRole.findUniqueOrThrow({ where: { key: 'SUPER_ADMIN' } });
  const passwordHash = await bcrypt.hash(password, Number(process.env.BCRYPT_ROUNDS ?? 12));

  await prisma.adminUser.upsert({
    where: { email: email.toLowerCase() },
    update: { roleId: role.id, name },
    // The seeded password must be changed on first login.
    create: { email: email.toLowerCase(), passwordHash, name, roleId: role.id, mustChangePassword: true },
  });
  console.log(`  super admin: ${email}`);
}

async function seedNumbers() {
  let count = 0;
  for (const seed of NUMBER_SEEDS) {
    for (const locale of LOCALES) {
      const copy = seed.copy[locale];
      const data = {
        name: copy.name,
        title: copy.title,
        summary: copy.summary,
        personality: copy.personality,
        behaviour: copy.behaviour,
        strengths: copy.strengths,
        weaknesses: copy.weaknesses,
        career: copy.career,
        relationships: copy.relationships,
        general: copy.general,
        luckyNumbers: seed.luckyNumbers,
        unfavourableNumbers: seed.unfavourableNumbers,
        colors: copy.colors,
        notes: copy.notes,
        isPublished: true,
      };
      await prisma.numerologyNumber.upsert({
        where: { number_locale: { number: seed.number, locale: locale as PrismaLocale } },
        update: data,
        create: { number: seed.number, locale: locale as PrismaLocale, ...data },
      });
      count += 1;
    }
  }
  console.log(`  numerology numbers: ${count} (9 numbers x ${LOCALES.length} locales)`);
}

async function seedCombinations() {
  const rows = buildAllCombinations(LOCALES);
  for (const row of rows) {
    const data = {
      title: row.title,
      description: row.description,
      personality: row.personality,
      strengths: row.strengths,
      challenges: row.challenges,
      career: row.career,
      relationships: row.relationships,
      recommendations: row.recommendations,
      isPublished: true,
    };
    await prisma.mulankBhagyankCombination.upsert({
      where: {
        mulank_bhagyank_locale: {
          mulank: row.mulank,
          bhagyank: row.bhagyank,
          locale: row.locale as PrismaLocale,
        },
      },
      update: data,
      create: { mulank: row.mulank, bhagyank: row.bhagyank, locale: row.locale as PrismaLocale, ...data },
    });
  }
  console.log(`  mulank x bhagyank combinations: ${rows.length} (81 x ${LOCALES.length} locales)`);
}

async function seedMarriageRules() {
  for (const rule of DEFAULT_MARRIAGE_RULES) {
    await prisma.marriageCompatibilityRule.upsert({
      where: { driverNumber: rule.driverNumber },
      update: {
        compatibleMulank: rule.compatibleMulank,
        compatibleBhagyank: rule.compatibleBhagyank,
        enabled: rule.enabled,
      },
      create: {
        driverNumber: rule.driverNumber,
        compatibleMulank: rule.compatibleMulank,
        compatibleBhagyank: rule.compatibleBhagyank,
        enabled: rule.enabled,
        notes: {},
      },
    });
  }
  console.log(`  marriage compatibility rules: ${DEFAULT_MARRIAGE_RULES.length}`);
}

async function seedNumberCompatibilityRules() {
  for (const rule of DEFAULT_NUMBER_COMPATIBILITY_RULES) {
    await prisma.numberCompatibilityRule.upsert({
      where: { baseNumber: rule.baseNumber },
      update: {
        friendly: rule.friendly,
        neutral: rule.neutral,
        unfriendly: rule.unfriendly,
        enabled: rule.enabled,
      },
      create: {
        baseNumber: rule.baseNumber,
        friendly: rule.friendly,
        neutral: rule.neutral,
        unfriendly: rule.unfriendly,
        enabled: rule.enabled,
      },
    });
  }
  console.log(`  number compatibility rules: ${DEFAULT_NUMBER_COMPATIBILITY_RULES.length}`);
}

async function seedChaldeanMappings() {
  let count = 0;
  for (const [value, letters] of Object.entries(DEFAULT_CHALDEAN_GROUPS)) {
    for (const letter of letters) {
      await prisma.chaldeanMapping.upsert({
        where: { letter },
        update: { value: Number(value), enabled: true },
        create: { letter, value: Number(value), enabled: true },
      });
      count += 1;
    }
  }
  console.log(`  chaldean mappings: ${count} letters (no letter is assigned to 9)`);
}

async function seedDailyInsights() {
  const rows = buildDailyInsights(LOCALES);
  for (const row of rows) {
    await prisma.dailyNumberInsight.upsert({
      where: { number_locale: { number: row.number, locale: row.locale as PrismaLocale } },
      update: { title: row.title, message: row.message },
      create: { number: row.number, locale: row.locale as PrismaLocale, title: row.title, message: row.message },
    });
  }
  console.log(`  daily number insights: ${rows.length}`);
}

async function seedSettings() {
  for (const setting of APP_SETTING_SEEDS) {
    await prisma.appSetting.upsert({
      where: { key: setting.key },
      // Values already customised by an administrator are preserved; only the
      // metadata is refreshed.
      update: { group: setting.group, description: setting.description, isPublic: setting.isPublic },
      create: {
        key: setting.key,
        value: setting.value as object,
        group: setting.group,
        description: setting.description,
        isPublic: setting.isPublic,
      },
    });
  }
  console.log(`  app settings: ${APP_SETTING_SEEDS.length}`);
}

async function seedLegalDocuments() {
  const documents = [
    { type: 'DISCLAIMER' as const, copy: LEGAL_SEEDS.DISCLAIMER },
    { type: 'PRIVACY' as const, copy: LEGAL_SEEDS.PRIVACY },
    { type: 'TERMS' as const, copy: LEGAL_SEEDS.TERMS },
    { type: 'ABOUT' as const, copy: LEGAL_SEEDS.ABOUT },
  ];
  let count = 0;
  for (const document of documents) {
    for (const locale of LOCALES) {
      const copy = document.copy[locale];
      await prisma.legalDocument.upsert({
        where: { type_locale: { type: document.type, locale: locale as PrismaLocale } },
        update: { title: copy.title, body: copy.body },
        create: {
          type: document.type,
          locale: locale as PrismaLocale,
          title: copy.title,
          body: copy.body,
          version: '1.0',
          publishedAt: new Date(),
        },
      });
      count += 1;
    }
  }
  console.log(`  legal documents: ${count}`);
}

async function main() {
  console.log('Seeding Ank Jyoti database...');
  await seedRoles();
  await seedSuperAdmin();
  await seedNumbers();
  await seedCombinations();
  await seedMarriageRules();
  await seedNumberCompatibilityRules();
  await seedChaldeanMappings();
  await seedDailyInsights();
  await seedSettings();
  await seedLegalDocuments();
  console.log('Seed complete.');
}

main()
  .catch((error) => {
    console.error('Seed failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
