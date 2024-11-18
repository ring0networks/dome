import { ROUTES_ADMIN } from "@/features/admin/routes";

export const ROUTES_POLICY_CATEGORIES = {
  admin: {
    root: () => `${ROUTES_ADMIN.baseUrl()}/policyCategories`,
    create: () => `${ROUTES_POLICY_CATEGORIES.admin.root()}/create`,
    policyCategory: (params: { id: string }) =>
      `${ROUTES_POLICY_CATEGORIES.admin.root()}/${params.id}`,
    update: (params: { id: string }) =>
      `${ROUTES_POLICY_CATEGORIES.admin.root()}/${params.id}/update`,
  },
};
