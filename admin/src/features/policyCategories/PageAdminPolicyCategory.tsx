import Link from "next/link";
import { LuPenLine, LuTrash2 } from "react-icons/lu";
import { ResponsiveIconButton } from "@/components/ResponsiveIconButton";
import { ROUTES_POLICY_CATEGORIES } from "@/features/policyCategories/routes";

import {
  Box,
  Card,
  CardBody,
  Heading,
  SkeletonText,
  Stack,
  Text,
  IconButton,
} from "@chakra-ui/react";
import { ConfirmModal } from "@/components/ConfirmModal";
import { toastCustom } from "@/components/Toast";
import { useParams, useRouter } from "next/navigation";
import { ErrorPage } from "@/components/ErrorPage";
import { LoaderFull } from "@/components/LoaderFull";
import { AdminBackButton } from "@/features/admin/AdminBackButton";
import {
  AdminLayoutPage,
  AdminLayoutPageContent,
  AdminLayoutPageTopBar,
} from "@/features/admin/AdminLayoutPage";
import { trpc } from "@/lib/trpc/client";

export default function PageAdminPolicyCategory() {
  const router = useRouter();
  const trpcUtils = trpc.useUtils();

  const params = useParams();
  const policyCategory = trpc.policyCategories.getById.useQuery({
    id: params?.id?.toString() ?? "",
  });

  const policyCategoryDelete = trpc.policyCategories.removeById.useMutation({
    onSuccess: async () => {
      await trpcUtils.policyCategories.getAll.invalidate();
      router.replace(ROUTES_POLICY_CATEGORIES.admin.root());
    },
    onError: () => {
      toastCustom({
        status: "error",
        title: "Deletion failed",
        description: "Failed to delete the policyCategory",
      });
    },
  });

  return (
    <AdminLayoutPage showNavBar="desktop" containerMaxWidth="container.md">
      <AdminLayoutPageTopBar
        leftActions={<AdminBackButton />}
        rightActions={
          <>
          {policyCategory?.data?.id && (
            <ResponsiveIconButton
              as={Link}
              href={ROUTES_POLICY_CATEGORIES.admin.update({ id: policyCategory.data.id })}
              icon={<LuPenLine />}
            >
              Edit
            </ResponsiveIconButton>
          )}
          {policyCategory?.data?.id && (
            <ConfirmModal
              title="Confirm deleting the category"
              message={`Would you like to delete "${policyCategory.data.name}"? Delete will be permanent.`}
              onConfirm={() =>
                policyCategory.data &&
                policyCategoryDelete.mutate({
                  id: policyCategory.data.id,
                })
              }
              confirmText="Delete"
              confirmVariant="@dangerSecondary"
            >
              <IconButton
                aria-label="Delete"
                icon={<LuTrash2 />}
                isDisabled={!policyCategory.data}
                isLoading={policyCategoryDelete.isLoading}
              />
            </ConfirmModal>
            )}
          </>
        }
      >
        {policyCategory.isLoading && <SkeletonText maxW="6rem" noOfLines={2} />}
        {policyCategory.isSuccess && <Heading size="sm">{policyCategory.data.name}</Heading>}
      </AdminLayoutPageTopBar>
      <AdminLayoutPageContent>
        {policyCategory.isLoading && <LoaderFull />}
        {policyCategory.isError && <ErrorPage />}
        {policyCategory.isSuccess && (
          <Card>
            <CardBody>
              <Stack spacing={4}>
                <Box>
                  <Text fontSize="sm" fontWeight="bold">
                    Name
                  </Text>
                  <Text>{policyCategory.data.name}</Text>
                </Box>
                <Box>
                  <Text fontSize="sm" fontWeight="bold">
                    Description
                  </Text>
                  <Text>{policyCategory.data.description || <small>-</small>}</Text>
                </Box>
                <Box>
                  <Text fontSize="sm" fontWeight="bold">
                   Blocked
                  </Text>
                  <Text><small>{policyCategory.data.blocked && "Yes" || "No"}</small></Text>
                </Box>
              </Stack>
            </CardBody>
          </Card>
        )}
      </AdminLayoutPageContent>
    </AdminLayoutPage>
  );
}
