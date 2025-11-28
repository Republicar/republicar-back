import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { users } from '../users/schema';

export const republics = sqliteTable('republics', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  address: text('address').notNull(),
  rooms: integer('rooms').notNull(),
  ownerId: integer('owner_id')
    .notNull()
    .references(() => users.id),
  createdAt: integer('created_at', { mode: 'timestamp' })
    .notNull()
    .default(new Date()),
});
