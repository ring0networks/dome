import { z } from "zod";
import { zu } from "@/lib/zod/zod-utils";

export type PolicyCategory = z.infer<ReturnType<typeof zPolicyCategory>>;
export const zPolicyCategory = () =>
  z.object({
    id: z.string().cuid(),
    name: zu.string.nonEmpty(z.string()),
    description: z.string().nullish(),
    blocked: z.boolean({
      required_error: "Blocked is required",
      invalid_type_error: "Blocked must be a boolean",
    }),
    custom: z.boolean(),
    domains: z.string().nullish(),
  });

export type FormFieldsPolicyCategory = z.infer<ReturnType<typeof zFormFieldsPolicyCategory>>;
export const zFormFieldsPolicyCategory = () =>
  zPolicyCategory().pick({
    name: true,
    description: true,
    blocked: true,
    custom: true,
    domains:true
  });
