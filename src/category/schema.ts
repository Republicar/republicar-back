import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { republics } from '../republic/schema';

export const categories = sqliteTable('categories', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  republicId: integer('republic_id')
    .notNull()
    .references(() => republics.id),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});
