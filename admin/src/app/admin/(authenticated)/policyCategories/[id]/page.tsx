"use client";

import { Suspense } from "react";

import PageAdminPolicyCategory from "@/features/policyCategories/PageAdminPolicyCategory";

export default function Page() {
  return (
    <Suspense>
      <PageAdminPolicyCategory />
    </Suspense>
  );
}
