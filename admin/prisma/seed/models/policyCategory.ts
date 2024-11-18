import { prisma } from "prisma/seed/utils";
var capitalize = require('capitalize')

const base_categories_pt = [
  [ "abuso", true ],
  [ "anúncios", true ],
  [ "básico", true ],
  [ "criptomoeda", true ],
  [ "drogas", true ],
  [ "fraude", true ],
  [ "notícias", false ],
  [ "saúde", false ],
  [ "entretenimento", false ],
  [ "negócios", false ],
  [ "educação", false ],
  [ "jogos", false ],
  [ "social", false ],
  [ "vídeo", false ],
  [ "jogos de azar", true ],
  [ "malware", true ],
  [ "phishing", true ],
  [ "pirataria", true ],
  [ "pornografia", true ],
  [ "ransomware", true ],
  [ "redirecionamento", true ],
  [ "golpe", true ],
];

const custom_categories = [
  [ "torrent", true ],
  [ "tracking", true ],
  [ "vaping", true ],
];

export async function createPolicyCategories() {
  console.log(`⏳ Seeding policy categories`);

  for (const category of base_categories_pt) {
    const cat = capitalize.words(category[0]);
    if (!(await prisma.policyCategory.findUnique({ where: { name: cat } }))) {
      await prisma.policyCategory.create({
        data: {
          name: cat,
          description: cat + " websites",
          blocked: Boolean(category[1]),
          custom: false,
        },
      });
    }
  }

  for (const category of custom_categories) {
    const cat = capitalize.words(category[0]);
    if (!(await prisma.policyCategory.findUnique({ where: { name: cat } }))) {
      await prisma.policyCategory.create({
        data: {
          name: cat,
          description: cat + " websites",
          blocked: Boolean(category[1]),
          custom: true,
        },
      });
    }
  }
}
