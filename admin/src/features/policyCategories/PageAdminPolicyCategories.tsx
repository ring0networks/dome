import {
  Button,
  Flex,
  HStack,
  Heading,
  LinkBox,
  LinkOverlay,
  Stack,
  Box
} from "@chakra-ui/react";
import { Form } from "@/components/Form";
import { useQueryState } from "nuqs";
import Link from "next/link";
import { LuPlus } from "react-icons/lu";
import { ResponsiveIconButton } from "@/components/ResponsiveIconButton";

import { PoliciesNav } from '@/features/policies/PoliciesNav';
import { ROUTES_POLICY_CATEGORIES } from "@/features/policyCategories/routes";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { FormField, FormFieldController } from "@/components/Form";
import { zFormFieldsPolicyCategory, FormFieldsPolicyCategory } from "@/features/policyCategories/schemas";

import { useTranslation } from 'react-i18next';

import {
  DataList,
  DataListCell,
  DataListEmptyState,
  DataListErrorState,
  DataListLoadingState,
  DataListRow,
  DataListText,
} from "@/components/DataList";
import { SearchInput } from "@/components/SearchInput";
import {
  AdminLayoutPage,
  AdminLayoutPageContent,
} from "@/features/admin/AdminLayoutPage";
import { trpc } from "@/lib/trpc/client";

export default function PageAdminPolicyCategories() {
  const { t } = useTranslation(['policies']);

  const [searchTerm, setSearchTerm] = useQueryState("s", { defaultValue: "" });

  const policyCategories = trpc.policyCategories.getAll.useInfiniteQuery(
    {
      searchTerm,
    },
    {
      getNextPageParam: (lastPage) => lastPage.nextCursor,
    }
  );

  const customCategories = trpc.policyCategories.getCustom.useInfiniteQuery(
    {
      searchTerm,
    },
    {
      getNextPageParam: (lastPage) => lastPage.nextCursor,
    }
  );

  return (
    <AdminLayoutPage containerMaxWidth="container.xl" nav={<PoliciesNav />}>
      <AdminLayoutPageContent>
        <Stack spacing={4}>
          <HStack spacing={4} alignItems={{ base: "end", md: "center" }}>
            <Flex
              flexDirection={{ base: "column", md: "row" }}
              alignItems={{ base: "start", md: "center" }}
              gap={4}
              flex={1}
            >
              <Heading flex="none" size="md">
                {t('policies:categories.base')}
              </Heading>
              <SearchInput
                value={searchTerm}
                onChange={(value) => setSearchTerm(value || null)}
                size="sm"
                maxW={{ base: "none", md: "20rem" }}
              />
            </Flex>
          </HStack>
          <DataListRow
              bg="gray.300"
              borderRadius="md"
              mb="-16px"
              _dark={{bg:"gray.600"}}
          >
            <DataListCell>
              <DataListText fontWeight="bold">
                {t('policies:categories.layout.header.category')}
              </DataListText>
            </DataListCell>
            <DataListCell>
              <DataListText fontWeight="bold">
                {t('policies:categories.layout.header.blocked')}
              </DataListText>
            </DataListCell>
          </DataListRow>

          <DataList maxH="300px" overflowY="auto">
            {policyCategories.isLoading && <DataListLoadingState />}
            {policyCategories.isError && (
              <DataListErrorState retry={() => policyCategories.refetch()} />
            )}

            {policyCategories.isSuccess &&
              !policyCategories.data.pages.flatMap((p) => p.items).length && (
                <DataListEmptyState searchTerm={searchTerm} />
            )}

            {policyCategories.data?.pages
              .flatMap((p) => p.items)
              .map((policyCategory) => {
                return (
                <DataListRow key={policyCategory.id}>
                  <DataListCell as={LinkBox}>
                    <DataListText fontWeight="bold">
                      <LinkOverlay
                        as={Link}
                        href={ROUTES_POLICY_CATEGORIES.admin.update({ id: policyCategory.id })}
                      >
                        {policyCategory.name}
                      </LinkOverlay>
                    </DataListText>
                  </DataListCell>
                  <DataListCell>
                    <DataListText>
                      <MySwitch category={policyCategory}/>
                    </DataListText>
                  </DataListCell>
                </DataListRow>
              )}
            )}

            {policyCategories.isSuccess && (
              <DataListRow mt="auto">
                <DataListCell>
                  <Button
                    size="sm"
                    onClick={() => policyCategories.fetchNextPage()}
                    isLoading={policyCategories.isFetchingNextPage}
                    isDisabled={!policyCategories.hasNextPage}
                  >
                    Load more
                  </Button>
                </DataListCell>
              </DataListRow>
            )}

          </DataList>
        </Stack>

        <Box h="50px"/>

        <Stack spacing={4}>
          <HStack spacing={4} alignItems={{ base: "end", md: "center" }}>
            <Flex
              flexDirection={{ base: "column", md: "row" }}
              alignItems={{ base: "start", md: "center" }}
              gap={4}
              flex={1}
            >
              <Heading flex="none" size="md">
                {t('policies:categories.custom')}
              </Heading>
            </Flex>
            <ResponsiveIconButton
                as={Link}
                href={ROUTES_POLICY_CATEGORIES.admin.create()}
                variant="@primary"
                size="sm"
                icon={<LuPlus />}
              >
                {t('policies:categories.layout.buttons.create')}
              </ResponsiveIconButton>
          </HStack>

          <DataListRow
            bg="gray.300"
            borderRadius="md"
            mb="-16px"
            _dark={{bg:"gray.600"}}
          >
            <DataListCell>
              <DataListText fontWeight="bold">
                {t('policies:categories.layout.header.category')}
              </DataListText>
            </DataListCell>
            <DataListCell>
              <DataListText fontWeight="bold">
                {t('policies:categories.layout.header.blocked')}
              </DataListText>
            </DataListCell>
          </DataListRow>

          <DataList maxH="300px" overflowY="auto">
            {customCategories.isLoading && <DataListLoadingState />}
            {customCategories.isError && (
              <DataListErrorState retry={() => customCategories.refetch()} />
            )}

            {customCategories.isSuccess &&
              !customCategories.data.pages.flatMap((p) => p.items).length && (
                <DataListEmptyState searchTerm={searchTerm} />
            )}

            {customCategories.data?.pages
              .flatMap((p) => p.items)
              .map((policyCategory) => {
                return (
                <DataListRow key={policyCategory.id}>
                  <DataListCell as={LinkBox}>
                    <DataListText fontWeight="bold">
                      <LinkOverlay
                        as={Link}
                        href={ROUTES_POLICY_CATEGORIES.admin.update({ id: policyCategory.id })}
                      >
                        {policyCategory.name}
                      </LinkOverlay>
                    </DataListText>
                  </DataListCell>
                  <DataListCell>
                    <DataListText>
                      <MySwitch category={policyCategory}/>
                    </DataListText>
                  </DataListCell>
                </DataListRow>
              )}
            )}

            {customCategories.isSuccess && (
              <DataListRow mt="auto">
                <DataListCell>
                  <Button
                    size="sm"
                    onClick={() => customCategories.fetchNextPage()}
                    isLoading={customCategories.isFetchingNextPage}
                    isDisabled={!customCategories.hasNextPage}
                  >
                    Load more
                  </Button>
                </DataListCell>
              </DataListRow>
            )}

          </DataList>
        </Stack>

      </AdminLayoutPageContent>
    </AdminLayoutPage>
  );
}


interface MySwitchOptions {
  category: {
    id: string;
    name?: string;
    description?: string | null;
    blocked?: boolean;
    custom?: boolean;
    domains?: string | null;
  };
}

export function MySwitch(options: MySwitchOptions) {
  const category = options.category;

  const form = useForm<FormFieldsPolicyCategory>({
    resolver: zodResolver(zFormFieldsPolicyCategory()),
    values: {
      name: category.name ?? "",
      description: category.description,
      blocked: category.blocked ?? false,
      custom: category.custom ?? false,
    },
  });

  return (
      <Form {...form}>
        <FormField>
          <FormFieldController
            control={form.control}
            type="switch"
            name="blocked"
            sx={{
            ".chakra-switch__track": {
              _checked: {
                bg: "red.500", // Cor do trilho quando ativado
              },
            },
            }}
          />
        </FormField>
      </Form>
    )
}
