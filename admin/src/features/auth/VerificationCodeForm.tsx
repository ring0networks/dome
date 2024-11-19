import { ReactNode } from 'react';

import { Button, HStack, Heading, Stack, Text } from '@chakra-ui/react';
import { TRPCClientErrorLike } from '@trpc/client';
import { parseAsInteger, useQueryState } from 'nuqs';
import { useFormContext } from 'react-hook-form';
import { Trans, useTranslation } from 'react-i18next';

import {
  FormField,
  FormFieldController,
  FormFieldHelper,
  FormFieldLabel,
} from '@/components/Form';
import { FormFieldsVerificationCode } from '@/features/auth/schemas';
import {
  VALIDATION_TOKEN_EXPIRATION_IN_MINUTES,
  getValidationRetryDelayInSeconds,
} from '@/features/auth/utils';
import { ValidationCodeHint } from '@/features/devtools/ValidationCodeHint';
import { AppRouter } from '@/lib/trpc/types';

export type VerificationCodeFormProps = {
  email: string;
  isLoading?: boolean;
  confirmText?: ReactNode;
  confirmVariant?: string;
  autoSubmit?: boolean;
};

export const VerificationCodeForm = ({
  email,
  isLoading,
  confirmText,
  confirmVariant,
  autoSubmit = true,
}: VerificationCodeFormProps) => {
  const { t } = useTranslation(['auth']);
  const form = useFormContext<FormFieldsVerificationCode>();

  return (
    <Stack spacing="4">
      <Stack>
        <Heading size="md">{t('auth:validate.title')}</Heading>
        <Text fontSize="sm">
          <Trans
            t={t}
            i18nKey="auth:validate.description"
            values={{
              email,
              expiration: VALIDATION_TOKEN_EXPIRATION_IN_MINUTES,
            }}
            components={{
              b: <strong />,
            }}
          />
        </Text>
      </Stack>
      <FormField>
        <FormFieldLabel>{t('auth:data.verificationCode.label')}</FormFieldLabel>
        <FormFieldController
          type="otp"
          control={form.control}
          name="code"
          size="lg"
          autoSubmit={autoSubmit}
          autoFocus
        />
        <FormFieldHelper>
          {t('auth:data.verificationCode.helper')}
        </FormFieldHelper>
      </FormField>
      <HStack spacing={8}>
        <Button
          size="lg"
          isLoading={isLoading}
          type="submit"
          variant={confirmVariant || '@primary'}
          flex={1}
        >
          {confirmText || t('auth:validate.actions.confirm')}
        </Button>
      </HStack>

      <ValidationCodeHint />
    </Stack>
  );
};

export const useOnVerificationCodeError = ({
  onError,
}: {
  onError: (error: string) => void;
}) => {
  const { t } = useTranslation(['auth']);
  const [attempts, setAttemps] = useQueryState(
    'attemps',
    parseAsInteger.withDefault(0)
  );

  return async (error: TRPCClientErrorLike<AppRouter>) => {
    if (error.data?.code === 'UNAUTHORIZED') {
      const seconds = getValidationRetryDelayInSeconds(attempts);

      setAttemps((s) => s + 1);

      await new Promise((r) => {
        setTimeout(r, seconds * 1_000);
      });

      onError(t('auth:data.verificationCode.unknown'));

      return;
    }

    if (error.data?.code === 'BAD_REQUEST') {
      onError(t('auth:data.verificationCode.invalid'));
      return;
    }

    onError(t('auth:data.verificationCode.unknown'));
  };
};
