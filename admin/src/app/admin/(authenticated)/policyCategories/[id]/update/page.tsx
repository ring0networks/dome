"use client";

import { Suspense } from "react";

import PageAdminPolicyCategoryUpdate from "@/features/policyCategories/PageAdminPolicyCategoryUpdate";

export default function Page() {
  return (
    <Suspense>
      <PageAdminPolicyCategoryUpdate />
    </Suspense>
  );
}
