import { z } from 'zod';
import { MAX_NAME_LENGTH, MAX_NUMBER_DIGITS, SUPPORTED_LOCALES } from '@numerology/core';
import { PASSWORD_MESSAGE, PASSWORD_RULE } from '../lib/password';

/**
 * Request schemas. Validation happens on the server for every endpoint; the
 * mobile app performs the same checks only to give faster feedback.
 */

export const localeSchema = z.enum(SUPPORTED_LOCALES as unknown as [string, ...string[]]);

/** ISO date (YYYY-MM-DD) or DD/MM/YYYY - the engine validates the calendar. */
export const dobSchema = z
  .string()
  .trim()
  .min(1, 'Please enter a date of birth.')
  .regex(/^(\d{4}-\d{2}-\d{2}|\d{1,2}[/\-.]\d{1,2}[/\-.]\d{4})$/, 'Please enter a valid date of birth.');

export const numberInputSchema = z
  .string()
  .trim()
  .min(1, 'Please enter a number.')
  .max(64, 'That value is too long.')
  .refine((value) => /\d/.test(value), 'Please enter a value that contains at least one digit.')
  .refine(
    (value) => (value.match(/\d/g) ?? []).length <= MAX_NUMBER_DIGITS,
    `Please enter at most ${MAX_NUMBER_DIGITS} digits.`,
  );

export const nameInputSchema = z
  .string()
  .trim()
  .min(1, 'Please enter a name.')
  .max(MAX_NAME_LENGTH, `Please enter at most ${MAX_NAME_LENGTH} characters.`);

export const emailSchema = z.string().trim().toLowerCase().email('Please enter a valid email address.').max(180);
export const passwordSchema = z.string().min(8, PASSWORD_MESSAGE).max(128).regex(PASSWORD_RULE, PASSWORD_MESSAGE);

export const registerSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  displayName: z.string().trim().min(1).max(60).optional(),
  dateOfBirth: dobSchema.nullish(),
});

export const loginSchema = z.object({ email: emailSchema, password: z.string().min(1, 'Please enter your password.') });
export const refreshSchema = z.object({ refreshToken: z.string().min(20, 'Invalid session.') });

export const updateProfileSchema = z
  .object({
    displayName: z.string().trim().min(1).max(60).nullish(),
    dateOfBirth: dobSchema.nullish(),
    gender: z.enum(['MALE', 'FEMALE', 'OTHER', 'UNSPECIFIED']).optional(),
    phone: z.string().trim().max(20).nullish(),
    photoUrl: z.string().trim().url().max(500).nullish(),
  })
  .refine((value) => Object.keys(value).length > 0, 'Please provide at least one field to update.');

export const updatePreferencesSchema = z
  .object({
    locale: localeSchema.optional(),
    theme: z.enum(['SYSTEM', 'LIGHT', 'DARK']).optional(),
    notificationsEnabled: z.boolean().optional(),
    dailyNumberOptIn: z.boolean().optional(),
    analyticsConsent: z.boolean().optional(),
    marketingConsent: z.boolean().optional(),
    shareDobOnCards: z.boolean().optional(),
  })
  .refine((value) => Object.keys(value).length > 0, 'Please provide at least one preference to update.');

/** `save: true` stores the date of birth as the user's global date of birth. */
const saveFlag = z.boolean().optional().default(false);

export const coreNumbersSchema = z.object({ dateOfBirth: dobSchema.optional(), save: saveFlag });

export const luckyNumberSchema = z.object({
  number: numberInputSchema,
  dateOfBirth: dobSchema.nullish(),
  save: saveFlag,
});

export const nameNumerologySchema = z.object({
  name: nameInputSchema,
  dateOfBirth: dobSchema.nullish(),
  compareWithDob: z.boolean().optional().default(true),
});

export const compatibilitySchema = z.object({
  maleDateOfBirth: dobSchema,
  femaleDateOfBirth: dobSchema,
});

export const dailyNumberSchema = z.object({ date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional() });

export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().trim().max(120).optional(),
});

export const historyQuerySchema = paginationSchema.extend({
  type: z
    .enum(['CORE_NUMBERS', 'LUCKY_NUMBER', 'NAME_NUMEROLOGY', 'MARRIAGE_COMPATIBILITY', 'DAILY_NUMBER'])
    .optional(),
});

export const favouriteSchema = z.object({
  historyId: z.string().uuid().optional(),
  type: z.enum(['CORE_NUMBERS', 'LUCKY_NUMBER', 'NAME_NUMEROLOGY', 'MARRIAGE_COMPATIBILITY', 'DAILY_NUMBER']),
  label: z.string().trim().min(1).max(120),
  input: z.record(z.unknown()).default({}),
  result: z.record(z.unknown()).default({}),
});

export const analyticsEventSchema = z.object({
  name: z.string().trim().min(1).max(60),
  sessionId: z.string().trim().max(64).optional(),
  properties: z.record(z.unknown()).optional(),
  platform: z.enum(['ANDROID', 'IOS', 'WEB']).optional(),
  appVersion: z.string().trim().max(20).optional(),
});

export const deviceTokenSchema = z.object({
  token: z.string().trim().min(10).max(400),
  platform: z.enum(['ANDROID', 'IOS', 'WEB']),
  enabled: z.boolean().optional().default(true),
});

export const idParamSchema = z.object({ id: z.string().uuid('Invalid identifier.') });

// --- Admin ----------------------------------------------------------------

export const adminLoginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'Please enter your password.'),
});

export const adminChangePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: passwordSchema,
});

const digits = z.array(z.number().int().min(1).max(9));

export const numberContentSchema = z.object({
  name: z.string().trim().min(1).max(120),
  title: z.string().trim().min(1).max(160),
  summary: z.string().trim().min(1).max(2000),
  personality: z.string().trim().min(1).max(4000),
  behaviour: z.string().trim().min(1).max(4000),
  strengths: z.array(z.string().trim().min(1).max(120)).max(20),
  weaknesses: z.array(z.string().trim().min(1).max(120)).max(20),
  career: z.string().trim().min(1).max(4000),
  relationships: z.string().trim().min(1).max(4000),
  general: z.string().trim().min(1).max(4000),
  luckyNumbers: digits.max(9),
  unfavourableNumbers: digits.max(9),
  colors: z.array(z.string().trim().min(1).max(40)).max(10),
  notes: z.string().trim().max(1000).nullish(),
  isPublished: z.boolean().optional(),
});

export const combinationContentSchema = z.object({
  title: z.string().trim().min(1).max(200),
  description: z.string().trim().min(1).max(6000),
  personality: z.string().trim().min(1).max(6000),
  strengths: z.array(z.string().trim().min(1).max(120)).max(20),
  challenges: z.array(z.string().trim().min(1).max(120)).max(20),
  career: z.string().trim().min(1).max(4000),
  relationships: z.string().trim().min(1).max(4000),
  recommendations: z.string().trim().min(1).max(4000),
  isPublished: z.boolean().optional(),
});

export const marriageRuleSchema = z.object({
  compatibleMulank: digits.max(9),
  compatibleBhagyank: digits.max(9),
  enabled: z.boolean().optional(),
  notes: z.record(z.string().max(600)).optional(),
});

export const numberRuleSchema = z
  .object({
    friendly: digits.max(9),
    neutral: digits.max(9),
    unfriendly: digits.max(9),
    enabled: z.boolean().optional(),
  })
  .refine(
    (value) => {
      const all = [...value.friendly, ...value.neutral, ...value.unfriendly];
      return new Set(all).size === all.length;
    },
    { message: 'A number can only appear in one of friendly, neutral or unfriendly.' },
  );

export const chaldeanMappingSchema = z.object({
  groups: z.record(z.string().regex(/^[1-9]$/), z.array(z.string().regex(/^[A-Za-z]$/)).max(26)),
});

export const settingSchema = z.object({ value: z.unknown() });

export const adminUserStatusSchema = z.object({ status: z.enum(['ACTIVE', 'DISABLED']) });

export const dailyInsightSchema = z.object({
  title: z.string().trim().min(1).max(160),
  message: z.string().trim().min(1).max(2000),
});

export const legalDocumentSchema = z.object({
  title: z.string().trim().min(1).max(160),
  body: z.string().trim().min(1).max(40000),
  version: z.string().trim().max(20).optional(),
});
