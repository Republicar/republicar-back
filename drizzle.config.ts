import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: [
    './src/users/schema.ts',
    './src/republic/schema.ts',
    './src/expense/schema.ts',
    './src/category/schema.ts',
    './src/subcategory/schema.ts',
  ],
  out: './drizzle',
  dialect: 'sqlite',
  dbCredentials: {
    url: process.env.TURSO_DATABASE_URL || 'file:local.db',
  },
});
