import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  role: text('role').notNull().default('OWNER'),
  republicId: integer('republic_id'), // Removed .references() to avoid circular dependency with republics table during creation

  createdAt: integer('created_at', { mode: 'timestamp' }).notNull().notNull(),
});
