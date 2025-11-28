import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { republics } from '../republic/schema';
import { categories } from '../category/schema';
import { subcategories } from '../subcategory/schema';

export const expenses = sqliteTable('expenses', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  description: text('description').notNull(),
  amount: integer('amount').notNull(), // Amount in cents
  date: integer('date', { mode: 'timestamp' }).notNull(),
  republicId: integer('republic_id')
    .notNull()
    .references(() => republics.id),
  categoryId: integer('category_id')
    .notNull()
    .references(() => categories.id),
  subcategoryId: integer('subcategory_id').references(() => subcategories.id),
  isExcluded: integer('is_excluded', { mode: 'boolean' }).notNull().default(false),
  reportId: integer('report_id'), // No FK constraint to avoid circular dependency if reports import expenses
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});
