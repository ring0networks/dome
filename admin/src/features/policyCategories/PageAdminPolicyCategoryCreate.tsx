import { toastCustom } from "@/components/Toast";
import { isErrorDatabaseConflict } from "@/lib/trpc/errors";
import { useRouter } from 'next/navigation';
import { trpc } from "@/lib/trpc/client";
import { Button, Heading } from "@chakra-ui/react";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";

import { Form } from "@/components/Form";

import { AdminBackButton } from "@/features/admin/AdminBackButton";
import { AdminCancelButton } from "@/features/admin/AdminCancelButton";
import {
  AdminLayoutPage,
  AdminLayoutPageContent,
  AdminLayoutPageTopBar,
} from "@/features/admin/AdminLayoutPage";
import { PolicyCategoryForm } from "@/features/policyCategories/PolicyCategoryForm";
import {
  FormFieldsPolicyCategory,
  zFormFieldsPolicyCategory,
} from "@/features/policyCategories/schemas";

import { useTranslation } from 'react-i18next';

export default function PageAdminPolicyCategoryCreate() {
  const { t } = useTranslation(['policies']);

  const trpcUtils = trpc.useUtils();
  const router = useRouter();

  const createPolicyCategory = trpc.policyCategories.create.useMutation({
    onSuccess: async () => {
      await trpcUtils.policyCategories.getAll.invalidate();
      toastCustom({
        status: 'success',
        title: t('policies:categories.create.action.success')
      });
      router.back();
    },
    onError: (error) => {
      if (isErrorDatabaseConflict(error, "name")) {
        form.setError("name", { message: t('policies:categories.create.action.nameError') });
        return;
      }
      toastCustom({
        status: 'error',
        title: t('policies:categories.create.action.error')
      });
    },
  });

  const form = useForm<FormFieldsPolicyCategory>({
    resolver: zodResolver(zFormFieldsPolicyCategory()),
    defaultValues: {
      name: "",
      description: "",
      blocked: false,
      custom: true,
    },
  });

  return (
    <Form
      {...form}
      onSubmit={(values) => {
        createPolicyCategory.mutate(values);
      }}
    >
      <AdminLayoutPage containerMaxWidth="container.md" showNavBar={false}>
        <AdminLayoutPageTopBar
          leftActions={<AdminBackButton withConfirm={form.formState.isDirty} />}
          rightActions={
            <>
              <AdminCancelButton withConfirm={form.formState.isDirty} />
              <Button
                type="submit"
                variant="@primary"
                isLoading={createPolicyCategory.isLoading || createPolicyCategory.isSuccess}
              >
                { t('policies:categories.create.action.save') }
              </Button>
            </>
          }
        >
          <Heading size="sm">{ t('policies:categories.create.layout.new') }</Heading>
        </AdminLayoutPageTopBar>
        <AdminLayoutPageContent>
          <PolicyCategoryForm />
        </AdminLayoutPageContent>
      </AdminLayoutPage>
    </Form>
  );
}
