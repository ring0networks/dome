import { Page } from '@playwright/test';

import { ROUTES_AUTH } from '@/features/auth/routes';
import { VALIDATION_CODE_MOCKED } from '@/features/auth/utils';
import locales from '@/locales';

/**
 * Utilities constructor
 *
 * @example
 * ```ts
 * test.describe('My scope', () => {
 *   test('My test', async ({ page }) => {
 *     const utils = pageUtils(page);
 *
 *     // No need too pass page on each util
 *     await utils.login(...)
 *   })
 * })
 * ```
 */
export const pageUtils = (page: Page) => {
  return {
    /**
     * Utility used to authenticate a user on the app
     */
    async loginApp(input: { email: string; code?: string }) {
      await page.goto(ROUTES_AUTH.login());
      await page.waitForURL(`**${ROUTES_AUTH.login()}`);

      await page
        .getByPlaceholder(locales.en.auth.data.email.label)
        .fill(input.email);
      await page
        .getByRole('button', { name: locales.en.auth.login.actions.login })
        .click();

      await page.waitForURL(`**${ROUTES_AUTH.login()}/**`);
      await page
        .getByText('Verification code')
        .fill(input.code ?? VALIDATION_CODE_MOCKED);
    },

    /**
     * Utility used to authenticate an admin on the app
     */
    async loginAdmin(input: { email: string; code?: string }) {
      await page.goto(ROUTES_AUTH.login());
      await page.waitForURL(`**${ROUTES_AUTH.login()}`);

      await page
        .getByPlaceholder(locales.en.auth.data.email.label)
        .fill(input.email);
      await page
        .getByRole('button', { name: locales.en.auth.login.actions.login })
        .click();

      await page.waitForURL(`**${ROUTES_AUTH.login()}/**`);
      await page
        .getByText('Verification code')
        .fill(input.code ?? VALIDATION_CODE_MOCKED);
    },
  } as const;
};
