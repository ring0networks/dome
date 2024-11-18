import { Button, Heading, SkeletonText, Stack } from "@chakra-ui/react";
import { zodResolver } from "@hookform/resolvers/zod";
import { useParams, useRouter } from "next/navigation";
import { useForm } from "react-hook-form";

import { ErrorPage } from "@/components/ErrorPage";
import { Form } from "@/components/Form";
import { LoaderFull } from "@/components/LoaderFull";
import { toastCustom } from "@/components/Toast";
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
import { trpc } from "@/lib/trpc/client";
import { isErrorDatabaseConflict } from "@/lib/trpc/errors";

import { useTranslation } from 'react-i18next';

export default function PageAdminPolicyCategoryUpdate() {
  const { t } = useTranslation(['policies']);

  const trpcUtils = trpc.useUtils();

  const params = useParams();
  const router = useRouter();
  const policyCategory = trpc.policyCategories.getById.useQuery(
    {
      id: params?.id?.toString() ?? "",
    },
    {
      staleTime: Infinity,
    }
  );

  const isReady = !policyCategory.isFetching;

  const updatePolicyCategory = trpc.policyCategories.updateById.useMutation({
    onSuccess: async () => {
      await trpcUtils.policyCategories.invalidate();
      toastCustom({
        status: "success",
        title: t('policies:categories.update.action.success')
      });
      router.back();
    },
    onError: (error) => {
      if (isErrorDatabaseConflict(error, "name")) {
        form.setError("name", { message: "Name already used" });
        return;
      }
      toastCustom({
        status: "error",
        title: t('policies:categories.update.action.error')
      });
    },
  });

  const form = useForm<FormFieldsPolicyCategory>({
    resolver: zodResolver(zFormFieldsPolicyCategory()),
    values: {
      name: policyCategory.data?.name ?? "",
      description: policyCategory.data?.description ?? null,
      blocked: policyCategory.data?.blocked ?? false,
      custom: policyCategory.data?.custom ?? false,
      domains: policyCategory.data?.domains ?? null,
    },
  });

  return (
    <Form
      {...form}
      onSubmit={(values) => {
        if (!policyCategory.data?.id) return;
        updatePolicyCategory.mutate({
          id: policyCategory.data.id,
          ...values,
        });
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
                isLoading={updatePolicyCategory.isLoading || updatePolicyCategory.isSuccess}
              >
                {t('policies:categories.update.action.save')}
              </Button>
            </>
          }
        >
          <Stack flex={1} spacing={0}>
            {policyCategory.isLoading && <SkeletonText maxW="6rem" noOfLines={2} />}
            {policyCategory.isSuccess && (
              <Heading size="sm">{policyCategory.data?.name}</Heading>
            )}
          </Stack>
        </AdminLayoutPageTopBar>
        {!isReady && <LoaderFull />}
        {isReady && policyCategory.isError && <ErrorPage />}
        {isReady && policyCategory.isSuccess && (
          <AdminLayoutPageContent>
            <PolicyCategoryForm />
          </AdminLayoutPageContent>
        )}
      </AdminLayoutPage>
    </Form>
  );
}
