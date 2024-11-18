import { createRepositories } from 'prisma/seed/models/repository';
import { createUsers } from 'prisma/seed/models/user';
import { createPolicyCategories } from 'prisma/seed/models/policyCategory';
import { prisma } from 'prisma/seed/utils';

async function main() {
  await createRepositories();
  await createUsers();
  await createPolicyCategories();
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => {
    prisma.$disconnect();
  });
