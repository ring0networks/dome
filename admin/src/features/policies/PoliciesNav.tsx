import React from 'react';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTranslation } from 'react-i18next';
import { LuShieldCheck } from 'react-icons/lu';

import { Nav, NavGroup, NavItem } from '@/components/Nav';
import { ROUTES_POLICY_CATEGORIES } from '@/features/policyCategories/routes';

export const PoliciesNav = () => {
  const { t } = useTranslation(['policies']);
  const pathname = usePathname();
  const isActive = (to: string) => pathname?.startsWith(to);
  return (
    <Nav>
      <NavGroup title={t('policies:nav.title')}>
        <NavItem
          as={Link}
          href={ROUTES_POLICY_CATEGORIES.admin.root()}
          isActive={isActive(ROUTES_POLICY_CATEGORIES.admin.root())}
          icon={LuShieldCheck}
        >
          {t('policies:nav.categories')}
        </NavItem>
      </NavGroup>
    </Nav>
  );
};
