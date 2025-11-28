import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { categories } from '../category/schema';

export const subcategories = sqliteTable('subcategories', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  categoryId: integer('category_id')
    .notNull()
    .references(() => categories.id),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});
