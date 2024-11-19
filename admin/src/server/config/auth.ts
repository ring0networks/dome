import { cache } from 'react';

import { VerificationToken } from '@prisma/client';
import { TRPCError } from '@trpc/server';
import bcrypt from 'bcrypt';
import dayjs from 'dayjs';
import { cookies, headers } from 'next/headers';
import { generateRandomString } from 'oslo/crypto';

import { env } from '@/env.mjs';
import {
  VALIDATION_CODE_ALLOWED_CHARACTERS,
  VALIDATION_CODE_MOCKED,
  getValidationRetryDelayInSeconds,
} from '@/features/auth/utils';
import { AppContext } from '@/server/config/trpc';

import { lucia } from './lucia';

/**
 * getServerAuthSession
 */
export const getServerAuthSession = cache(async () => {
  const sessionId =
    headers().get('Authorization')?.split('Bearer ')[1] ??
    // Get Session from cookies
    cookies().get(lucia.sessionCookieName)?.value;

  if (!sessionId)
    return {
      user: null,
      session: null,
    };

  const { user, session } = await lucia.validateSession(sessionId);

  if (user?.accountStatus !== 'ENABLED')
    return {
      user: null,
      session: null,
    };

  try {
    if (session?.fresh) {
      const sessionCookie = lucia.createSessionCookie(session.id);
      cookies().set(
        sessionCookie.name,
        sessionCookie.value,
        sessionCookie.attributes
      );
    }

    if (!session) {
      const sessionCookie = lucia.createBlankSessionCookie();
      cookies().set(
        sessionCookie.name,
        sessionCookie.value,
        sessionCookie.attributes
      );
    }
  } catch {
    // Next.js throws error when attempting to set cookies when rendering page
  }

  return {
    user,
    session,
  };
});

export async function generateCode() {
  const code =
    env.NODE_ENV === 'development' || env.NEXT_PUBLIC_IS_DEMO
      ? VALIDATION_CODE_MOCKED
      : generateRandomString(6, VALIDATION_CODE_ALLOWED_CHARACTERS);
  return {
    hashed: await bcrypt.hash(code, 12),
    readable: code,
  };
}

export async function validateCode({
  ctx,
  code,
  token,
}: {
  ctx: AppContext;
  code: string;
  token: string;
}): Promise<{ verificationToken: VerificationToken }> {
  ctx.logger.info('Removing expired verification tokens from database');
  await ctx.db.verificationToken.deleteMany({
    where: { expires: { lt: new Date() } },
  });

  ctx.logger.info('Checking if verification token exists');
  const verificationToken = await ctx.db.verificationToken.findUnique({
    where: {
      token,
    },
  });

  if (!verificationToken) {
    ctx.logger.warn('Verification token does not exist');
    throw new TRPCError({
      code: 'UNAUTHORIZED',
      message: 'Failed to authenticate the user',
    });
  }

  const retryDelayInSeconds = getValidationRetryDelayInSeconds(
    verificationToken.attempts
  );

  ctx.logger.info('Check last attempt date');
  if (
    dayjs().isBefore(
      dayjs(verificationToken.lastAttemptAt).add(retryDelayInSeconds, 'seconds')
    )
  ) {
    ctx.logger.warn('Last attempt was to close');
    throw new TRPCError({
      code: 'UNAUTHORIZED',
      message: 'Failed to authenticate the user',
    });
  }

  ctx.logger.info('Checking code');
  const isCodeValid = await bcrypt.compare(code, verificationToken.code);

  if (!isCodeValid) {
    ctx.logger.warn('Invalid code');

    try {
      ctx.logger.info('Updating token attempts');
      await ctx.db.verificationToken.update({
        where: {
          token,
        },
        data: {
          attempts: {
            increment: 1,
          },
        },
      });
    } catch {
      ctx.logger.error('Failed to update token attempts');
    }

    throw new TRPCError({
      code: 'UNAUTHORIZED',
      message: 'Failed to authenticate the user',
    });
  }

  return { verificationToken };
}

export async function deleteUsedCode({
  ctx,
  token,
}: {
  ctx: AppContext;
  token: string;
}) {
  ctx.logger.info('Deleting used token');
  try {
    await ctx.db.verificationToken.delete({
      where: { token },
    });
  } catch {
    ctx.logger.warn('Failed to delete the used token');
  }
}

export async function createSession(userId: string) {
  const session = await lucia.createSession(
    userId,
    {
      // Possible to pass custom session attributes defined when declaring the Lucia instance
    },
    {
      // Possible to pass custom sessionId but otherwise it will be generated
      // sessionId: CUSTOM_SESSION_ID,
    }
  );

  const sessionCookie = lucia.createSessionCookie(session.id);

  cookies().set(
    sessionCookie.name,
    sessionCookie.value,
    sessionCookie.attributes
  );

  return session.id;
}

export async function deleteSession(sessionId: string) {
  await lucia.invalidateSession(sessionId);

  const sessionCookie = lucia.createBlankSessionCookie();

  cookies().set(
    sessionCookie.name,
    sessionCookie.value,
    sessionCookie.attributes
  );
}
