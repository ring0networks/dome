"use client";

import { Suspense } from "react";

import PageAdminPolicyCategoryCreate from "@/features/policyCategories/PageAdminPolicyCategoryCreate";

export default function Page() {
  return (
    <Suspense>
      <PageAdminPolicyCategoryCreate />
    </Suspense>
  );
}
