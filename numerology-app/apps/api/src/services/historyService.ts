import type { CalculationType, Locale as PrismaLocale, Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';

export interface RecordHistoryInput {
  userId: string;
  type: CalculationType;
  label: string;
  input: Prisma.InputJsonValue;
  result: Prisma.InputJsonValue;
  primaryNumber?: number | null;
  secondaryNumber?: number | null;
  locale: PrismaLocale;
}

/**
 * History is only written for signed in users. Guest calculations stay on the
 * device, which is what the privacy policy promises.
 */
export async function recordHistory(input: RecordHistoryInput) {
  return prisma.calculationHistory.create({
    data: {
      userId: input.userId,
      type: input.type,
      label: input.label,
      input: input.input,
      result: input.result,
      primaryNumber: input.primaryNumber ?? null,
      secondaryNumber: input.secondaryNumber ?? null,
      locale: input.locale,
    },
    select: { id: true, createdAt: true },
  });
}

export interface HistoryQuery {
  userId: string;
  page: number;
  pageSize: number;
  type?: CalculationType;
  search?: string;
}

export async function listHistory(query: HistoryQuery) {
  const where: Prisma.CalculationHistoryWhereInput = {
    userId: query.userId,
    deletedAt: null,
    ...(query.type ? { type: query.type } : {}),
    ...(query.search ? { label: { contains: query.search, mode: 'insensitive' } } : {}),
  };

  const [items, total] = await Promise.all([
    prisma.calculationHistory.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
      select: {
        id: true,
        type: true,
        label: true,
        input: true,
        result: true,
        primaryNumber: true,
        secondaryNumber: true,
        locale: true,
        createdAt: true,
      },
    }),
    prisma.calculationHistory.count({ where }),
  ]);

  return { items, total };
}

/** Soft delete, so an accidental tap can be recovered by support if needed. */
export async function deleteHistoryEntry(userId: string, id: string) {
  const result = await prisma.calculationHistory.updateMany({
    where: { id, userId, deletedAt: null },
    data: { deletedAt: new Date() },
  });
  return result.count > 0;
}

export async function clearHistory(userId: string) {
  const result = await prisma.calculationHistory.updateMany({
    where: { userId, deletedAt: null },
    data: { deletedAt: new Date() },
  });
  return result.count;
}
