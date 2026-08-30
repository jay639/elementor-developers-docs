import { Router } from 'express';
import { asyncHandler } from '../lib/async';
import { noContent, ok } from '../lib/http';
import { validate } from '../middleware/validate';
import { requireUser } from '../middleware/auth';
import { updatePreferencesSchema, updateProfileSchema } from './schemas';
import { prisma } from '../lib/prisma';
import { coreNumbersFor } from '../services/numerologyService';
import { parseDateOfBirth, formatISODate } from '@numerology/core';
import { track } from '../services/analyticsService';
import { logoutAll } from '../services/authService';

export const profileRouter = Router();

profileRouter.use(requireUser);

function serialise(profile: {
  displayName: string | null;
  dateOfBirth: Date | null;
  gender: string;
  phone: string | null;
  photoUrl: string | null;
  mulank: number | null;
  bhagyank: number | null;
}) {
  return {
    displayName: profile.displayName,
    // Dates are stored as plain dates; only the calendar part is returned.
    dateOfBirth: profile.dateOfBirth ? profile.dateOfBirth.toISOString().slice(0, 10) : null,
    gender: profile.gender,
    phone: profile.phone,
    photoUrl: profile.photoUrl,
    mulank: profile.mulank,
    bhagyank: profile.bhagyank,
  };
}

/** GET /profile - profile, preferences and the derived global numbers. */
profileRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const user = await prisma.user.findUniqueOrThrow({
      where: { id: req.user!.id },
      select: {
        id: true,
        email: true,
        isGuest: true,
        provider: true,
        createdAt: true,
        profile: true,
        preferences: true,
      },
    });

    return ok(res, {
      id: user.id,
      email: user.email,
      isGuest: user.isGuest,
      provider: user.provider,
      memberSince: user.createdAt,
      profile: user.profile ? serialise(user.profile) : null,
      preferences: user.preferences,
    });
  }),
);

/** PUT /profile - updates the profile and recalculates the global numbers. */
profileRouter.put(
  '/',
  validate(updateProfileSchema),
  asyncHandler(async (req, res) => {
    const { displayName, dateOfBirth, gender, phone, photoUrl } = req.body;

    const data: Record<string, unknown> = {};
    if (displayName !== undefined) data.displayName = displayName;
    if (gender !== undefined) data.gender = gender;
    if (phone !== undefined) data.phone = phone;
    if (photoUrl !== undefined) data.photoUrl = photoUrl;

    if (dateOfBirth !== undefined) {
      if (dateOfBirth === null) {
        data.dateOfBirth = null;
        data.mulank = null;
        data.bhagyank = null;
      } else {
        const iso = formatISODate(parseDateOfBirth(dateOfBirth));
        const numbers = coreNumbersFor(iso);
        data.dateOfBirth = new Date(`${iso}T00:00:00Z`);
        data.mulank = numbers.mulank;
        data.bhagyank = numbers.bhagyank;
      }
    }

    const profile = await prisma.userProfile.upsert({
      where: { userId: req.user!.id },
      create: { userId: req.user!.id, ...data },
      update: data,
    });

    if (dateOfBirth) {
      await track({ name: 'dob_saved', userId: req.user!.id, locale: req.locale });
    }
    await track({ name: 'profile_updated', userId: req.user!.id, locale: req.locale });

    return ok(res, serialise(profile));
  }),
);

/** PUT /profile/preferences */
profileRouter.put(
  '/preferences',
  validate(updatePreferencesSchema),
  asyncHandler(async (req, res) => {
    const preferences = await prisma.userPreference.upsert({
      where: { userId: req.user!.id },
      create: { userId: req.user!.id, ...req.body },
      update: req.body,
    });
    return ok(res, preferences);
  }),
);

/**
 * DELETE /profile - account deletion.
 * The row is soft deleted and the personal fields are cleared immediately, so
 * no personal data survives while the id stays referenced by analytics.
 */
profileRouter.delete(
  '/',
  asyncHandler(async (req, res) => {
    const userId = req.user!.id;
    await prisma.$transaction([
      prisma.userProfile.deleteMany({ where: { userId } }),
      prisma.favourite.deleteMany({ where: { userId } }),
      prisma.calculationHistory.deleteMany({ where: { userId } }),
      prisma.deviceToken.deleteMany({ where: { userId } }),
      prisma.analyticsEvent.updateMany({ where: { userId }, data: { userId: null } }),
      prisma.user.update({
        where: { id: userId },
        data: { deletedAt: new Date(), email: null, passwordHash: null, status: 'DISABLED' },
      }),
    ]);
    await logoutAll(userId);
    return noContent(res);
  }),
);
