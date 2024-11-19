import React from 'react';

import { Button, ButtonGroup, Stack } from '@chakra-ui/react';
import { zodResolver } from '@hookform/resolvers/zod';
import { SubmitHandler, useForm } from 'react-hook-form';
import { useTranslation } from 'react-i18next';

import { ErrorPage } from '@/components/ErrorPage';
import {
  Form,
  FormField,
  FormFieldController,
  FormFieldLabel,
} from '@/components/Form';
import { LoaderFull } from '@/components/LoaderFull';
import { toastCustom } from '@/components/Toast';
import {
  FormFieldsAccountProfile,
  zFormFieldsAccountProfile,
} from '@/features/account/schemas';
import {
  AVAILABLE_LANGUAGES,
  DEFAULT_LANGUAGE_KEY,
} from '@/lib/i18n/constants';
import { trpc } from '@/lib/trpc/client';

export const AccountProfileForm = () => {
  const { t } = useTranslation(['common', 'account']);
  const trpcUtils = trpc.useUtils();
  const account = trpc.account.get.useQuery(undefined, {
    staleTime: Infinity,
  });

  const updateAccount = trpc.account.update.useMutation({
    onSuccess: async () => {
      await trpcUtils.account.invalidate();
      toastCustom({
        status: 'success',
        title: t('account:profile.feedbacks.updateSuccess.title'),
      });
    },
    onError: () => {
      toastCustom({
        status: 'error',
        title: t('account:profile.feedbacks.updateError.title'),
      });
    },
  });

  const form = useForm<FormFieldsAccountProfile>({
    mode: 'onBlur',
    resolver: zodResolver(zFormFieldsAccountProfile()),
    values: {
      name: account.data?.name ?? '',
      language: account.data?.language ?? DEFAULT_LANGUAGE_KEY,
    },
  });

  const onSubmit: SubmitHandler<FormFieldsAccountProfile> = (values) => {
    updateAccount.mutate(values);
  };

  return (
    <>
      {account.isLoading && <LoaderFull />}
      {account.isError && <ErrorPage />}
      {account.isSuccess && (
        <Stack spacing={4}>
          <Form {...form} onSubmit={onSubmit}>
            <Stack spacing={4}>
              <FormField>
                <FormFieldLabel>{t('account:data.name.label')}</FormFieldLabel>
                <FormFieldController
                  control={form.control}
                  name="name"
                  type="text"
                />
              </FormField>
              <FormField>
                <FormFieldLabel>
                  {t('account:data.language.label')}
                </FormFieldLabel>
                <FormFieldController
                  control={form.control}
                  name="language"
                  type="select"
                  options={AVAILABLE_LANGUAGES.map(({ key }) => ({
                    label: t(`common:languages.${key}`),
                    value: key,
                  }))}
                />
              </FormField>

              <ButtonGroup spacing={3}>
                <Button
                  type="submit"
                  variant="@primary"
                  isLoading={updateAccount.isLoading}
                >
                  {t('account:profile.actions.update')}
                </Button>
                {form.formState.isDirty && (
                  <Button onClick={() => form.reset()}>
                    {t('common:actions.cancel')}
                  </Button>
                )}
              </ButtonGroup>
            </Stack>
          </Form>
        </Stack>
      )}
    </>
  );
};
