import { TRPCError } from '@trpc/server';
import { Prisma } from "@prisma/client";
import { z } from "zod";

import { zPolicyCategory } from "@/features/policyCategories/schemas";
import { createTRPCRouter, protectedProcedure } from "@/server/config/trpc";
import { ExtendedTRPCError } from '@/server/config/errors';

export const policyCategoriesRouter = createTRPCRouter({
  getCustom: protectedProcedure({ authorizations: ["ADMIN"] })
  .meta({
    openapi: {
      method: "GET",
      path: "/customCategories",
      protect: true,
      tags: ["customCategories"],
    },
  })
  .input(
    z
    .object({
      cursor: z.string().cuid().optional(),
      limit: z.number().min(1).max(100).default(20),
      searchTerm: z.string().optional(),
    })
    .default({})
  )
  .output(
    z.object({
      items: z.array(
        z.object({
          id: z.string().cuid(),
          name: z.string(),
          description: z.string().nullish(),
          blocked: z.boolean(),
        })
      ),
      nextCursor: z.string().cuid().nullish(),
      total: z.number(),
    })
  )
  .query(async ({ ctx, input }) => {
    const where = {
      name: {
        contains: input.searchTerm,
        mode: "insensitive",
      },
      custom: true
    } satisfies Prisma.PolicyCategoryWhereInput;

    const [total, policyCategories] = await ctx.db.$transaction([
      ctx.db.policyCategory.count({ where }),
      ctx.db.policyCategory.findMany({
        // Get an extra item at the end which we'll use as next cursor
        take: input.limit + 1,
        cursor: input.cursor ? { id: input.cursor } : undefined,
        where,
      }),
    ]);

    let nextCursor: typeof input.cursor | undefined = undefined;
    if (policyCategories.length > input.limit) {
      const nextPolicyCategory = policyCategories.pop();
      nextCursor = nextPolicyCategory?.id;
    }

    return { items: policyCategories, nextCursor, total };
  }),

  getAll: protectedProcedure({ authorizations: ["ADMIN"] })
    .meta({
      openapi: {
        method: "GET",
        path: "/policyCategories",
        protect: true,
        tags: ["policyCategories"],
      },
    })
    .input(
      z
        .object({
          cursor: z.string().cuid().optional(),
          limit: z.number().min(1).max(100).default(20),
          searchTerm: z.string().optional(),
        })
        .default({})
    )
    .output(
      z.object({
        items: z.array(
          z.object({
            id: z.string().cuid(),
            name: z.string(),
            description: z.string().nullish(),
            blocked: z.boolean(),
          })
        ),
        nextCursor: z.string().cuid().nullish(),
        total: z.number(),
      })
    )
    .query(async ({ ctx, input }) => {
      const where = {
        name: {
          contains: input.searchTerm,
          mode: "insensitive",
        },
        custom: false,
      } satisfies Prisma.PolicyCategoryWhereInput;

      const [total, policyCategories] = await ctx.db.$transaction([
        ctx.db.policyCategory.count({ where }),
        ctx.db.policyCategory.findMany({
          // Get an extra item at the end which we'll use as next cursor
          take: input.limit + 1,
          cursor: input.cursor ? { id: input.cursor } : undefined,
          where,
        }),
      ]);

      let nextCursor: typeof input.cursor | undefined = undefined;
      if (policyCategories.length > input.limit) {
        const nextPolicyCategory = policyCategories.pop();
        nextCursor = nextPolicyCategory?.id;
      }

      return { items: policyCategories, nextCursor, total };
    }),

    create: protectedProcedure({ authorizations: ['ADMIN'] })
    .meta({
      openapi: {
        method: 'POST',
        path: '/policyCategories',
        protect: true,
        tags: ['policyCategories'],
      },
    })
    .input(
      zPolicyCategory().pick({
        name: true,
        description: true,
        blocked: true,
        custom: true,
        domains: true,
      })
    )
    .output(zPolicyCategory())
    .mutation(async ({ ctx, input }) => {
      try {
        ctx.logger.info('Creating policy category');
        return await ctx.db.policyCategory.create({
          data: input,
        });
      } catch (e) {
        throw new ExtendedTRPCError({
          cause: e,
        });
      }
    }),

    getById: protectedProcedure({ authorizations: ['ADMIN'] })
    .meta({
      openapi: {
        method: 'GET',
        path: '/policyCategories/{id}',
        protect: true,
        tags: ['policyCategories'],
      },
    })
    .input(zPolicyCategory().pick({ id: true }))
    .output(zPolicyCategory())
    .query(async ({ ctx, input }) => {
      ctx.logger.info('Getting category');
      const policyCategory = await ctx.db.policyCategory.findUnique({
        where: { id: input.id },
      });

      if (!policyCategory) {
        ctx.logger.warn('Unable to find category with the provided input');
        throw new TRPCError({
          code: 'NOT_FOUND',
        });
      }

      return policyCategory;
    }),

    updateById: protectedProcedure({ authorizations: ['ADMIN'] })
    .meta({
      openapi: {
        method: 'PUT',
        path: '/policyCategories/{id}',
        protect: true,
        tags: ['policyCategories'],
      },
    })
    .input(
      zPolicyCategory().pick({
        id: true,
        name: true,
        description: true,
        blocked: true,
        domains: true,
      })
    )
    .output(zPolicyCategory())
    .mutation(async ({ ctx, input }) => {
      try {
        ctx.logger.info('Updating category');
        return await ctx.db.policyCategory.update({
          where: { id: input.id },
          data: input,
        });
      } catch (e) {
        throw new ExtendedTRPCError({
          cause: e,
        });
      }
    }),

    removeById: protectedProcedure({ authorizations: ['ADMIN'] })
    .meta({
      openapi: {
        method: 'DELETE',
        path: '/policyCategories/{id}',
        protect: true,
        tags: ['policyCategories'],
      },
    })
    .input(zPolicyCategory().pick({ id: true }))
    .output(zPolicyCategory())
    .mutation(async ({ ctx, input }) => {
      ctx.logger.info({ input }, 'Removing policyCategory');
      try {
        return await ctx.db.policyCategory.delete({
          where: { id: input.id },
        });
      } catch (e) {
        throw new ExtendedTRPCError({
          cause: e,
        });
      }
    }),

});
