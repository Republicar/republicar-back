import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { republics } from '../republic/schema';

export const users = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  role: text('role').notNull().default('OWNER'),
  republicId: integer('republic_id').references(
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-member-access
    () => republics.id,
  ),
  createdAt: integer('created_at', { mode: 'timestamp' })
    .notNull()
    .default(new Date()),
});
