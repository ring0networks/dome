import { Stack } from "@chakra-ui/react";
import { useFormContext } from "react-hook-form";

import { useTranslation } from 'react-i18next';

import { FormField, FormFieldLabel, FormFieldController } from "@/components/Form";
import { FormFieldsPolicyCategory } from "@/features/policyCategories/schemas";

export const PolicyCategoryForm = () => {
  const { t } = useTranslation(['policies']);

  const form = useFormContext<FormFieldsPolicyCategory>();

  return (
    <Stack spacing={4}>
      <FormField>
        <FormFieldLabel>{t('policies:categories.layout.form.name')}</FormFieldLabel>
        <FormFieldController control={form.control} type="text" name="name" />
      </FormField>

      <FormField>
        <FormFieldLabel optionalityHint="optional">{t('policies:categories.layout.form.description')}</FormFieldLabel>
        <FormFieldController
          control={form.control}
          type="textarea"
          name="description"
          rows={6}
        />
      </FormField>

      <FormField>
        <FormFieldLabel optionalityHint="optional">{t('policies:categories.layout.form.blocked')}</FormFieldLabel>
        <FormFieldController
          control={form.control}
          type="switch"
          name="blocked"
        />
      </FormField>

      { form.getValues().custom && (
        <FormField>
          <FormFieldLabel optionalityHint="optional">{t('policies:categories.layout.form.domains')}</FormFieldLabel>
          <FormFieldController
            control={form.control}
            type="textarea"
            name="domains"
            rows={12}
          />
        </FormField>
      )}

    </Stack>
  );
};
