import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';
import { republics } from '../republic/schema';
import { users } from '../users/schema';

export const reports = sqliteTable('reports', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    republicId: integer('republic_id')
        .notNull()
        .references(() => republics.id),
    startDate: integer('start_date', { mode: 'timestamp' }).notNull(),
    endDate: integer('end_date', { mode: 'timestamp' }).notNull(),
    totalAmount: integer('total_amount').notNull(), // in cents
    splitMethod: text('split_method').notNull(), // 'EQUAL' | 'PROPORTIONAL'
    status: text('status').notNull().default('OPEN'), // 'OPEN' | 'CLOSED'
    createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});

export const reportShares = sqliteTable('report_shares', {
    id: integer('id').primaryKey({ autoIncrement: true }),
    reportId: integer('report_id')
        .notNull()
        .references(() => reports.id),
    occupantId: integer('occupant_id')
        .notNull()
        .references(() => users.id),
    shareAmount: integer('share_amount').notNull(), // in cents
    percentage: integer('percentage'), // stored as integer (e.g. 2500 for 25.00%) or null for equal split
});
