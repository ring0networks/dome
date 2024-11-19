import React from 'react';

import {
  Box,
  BoxProps,
  Button,
  ButtonProps,
  Flex,
  Stack,
} from '@chakra-ui/react';
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { useTranslation } from 'react-i18next';

import { Form, FormField, FormFieldController } from '@/components/Form';
import { toastCustom } from '@/components/Toast';
import { FormFieldsLogin, zFormFieldsLogin } from '@/features/auth/schemas';
import { LoginHint } from '@/features/devtools/LoginHint';
import { trpc } from '@/lib/trpc/client';
import type { RouterInputs, RouterOutputs } from '@/lib/trpc/types';

type LoginFormProps = BoxProps & {
  onSuccess?: (
    data: RouterOutputs['auth']['login'],
    variables: RouterInputs['auth']['login']
  ) => void;
  buttonVariant?: ButtonProps['variant'];
};

export const LoginForm = ({
  onSuccess = () => undefined,
  buttonVariant = '@primary',
  ...rest
}: LoginFormProps) => {
  const { t } = useTranslation(['auth']);

  const login = trpc.auth.login.useMutation({
    onSuccess,
    onError: () => {
      toastCustom({
        status: 'error',
        title: t('auth:login.feedbacks.loginError.title'),
      });
    },
  });

  const form = useForm<FormFieldsLogin>({
    mode: 'onBlur',
    resolver: zodResolver(zFormFieldsLogin()),
    defaultValues: {
      email: '',
    },
  });

  return (
    <Box {...rest}>
      <Form
        {...form}
        onSubmit={(values) => {
          login.mutate(values);
        }}
      >
        <Stack spacing={4}>
          <FormField>
            <FormFieldController
              type="email"
              control={form.control}
              name="email"
              size="lg"
              placeholder={t('auth:data.email.label')}
            />
          </FormField>
          <Flex>
            <Button
              isLoading={login.isLoading || login.isSuccess}
              type="submit"
              variant={buttonVariant}
              size="lg"
              flex={1}
            >
              {t('auth:login.actions.login')}
            </Button>
          </Flex>

          <LoginHint />
        </Stack>
      </Form>
    </Box>
  );
};
