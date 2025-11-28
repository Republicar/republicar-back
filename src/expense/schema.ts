import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { republics } from '../republic/schema';

export const expenses = sqliteTable('expenses', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  description: text('description').notNull(),
  amount: integer('amount').notNull(), // Amount in cents
  date: integer('date', { mode: 'timestamp' }).notNull(),
  republicId: integer('republic_id')
    .notNull()
    .references(() => republics.id),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull().notNull(),
});
