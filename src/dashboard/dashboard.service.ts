import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectDrizzle } from '@knaadh/nestjs-drizzle-turso';
import { LibSQLDatabase } from 'drizzle-orm/libsql';
import * as schema from '../republic/schema';
import { expenses } from '../expense/schema';
import { republics } from '../republic/schema';
import { users } from '../users/schema';
import { categories } from '../category/schema';
import { eq, and, sql, gte, lte } from 'drizzle-orm';

@Injectable()
export class DashboardService {
    constructor(@InjectDrizzle() private db: LibSQLDatabase<typeof schema>) { }

    async getCurrentMonthSummary(ownerId: number) {
        // 1. Find Republic
        const republicResult = await this.db
            .select()
            .from(republics)
            .where(eq(republics.ownerId, ownerId))
            .execute();

        if (republicResult.length === 0) {
            throw new NotFoundException('Republic not found');
        }
        const republicId = republicResult[0].id;

        // 2. Get current month date range
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

        // 3. Get total expenses for current month
        const expenseList = await this.db
            .select()
            .from(expenses)
            .where(
                and(
                    eq(expenses.republicId, republicId),
                    gte(expenses.date, startOfMonth),
                    lte(expenses.date, endOfMonth),
                ),
            )
            .execute();

        const totalExpenses = expenseList.reduce((sum, exp) => sum + exp.amount, 0);

        // 4. Get occupant count
        const occupants = await this.db
            .select()
            .from(users)
            .where(eq(users.republicId, republicId))
            .execute();

        const occupantCount = occupants.length;
        const averagePerOccupant = occupantCount > 0 ? totalExpenses / occupantCount : 0;

        return {
            month: now.toLocaleString('default', { month: 'long', year: 'numeric' }),
            totalExpenses,
            occupantCount,
            averagePerOccupant: Math.round(averagePerOccupant),
        };
    }

    async getExpensesByCategory(ownerId: number, month?: number, year?: number) {
        // 1. Find Republic
        const republicResult = await this.db
            .select()
            .from(republics)
            .where(eq(republics.ownerId, ownerId))
            .execute();

        if (republicResult.length === 0) {
            throw new NotFoundException('Republic not found');
        }
        const republicId = republicResult[0].id;

        // 2. Determine date range
        const now = new Date();
        const targetMonth = month !== undefined ? month : now.getMonth();
        const targetYear = year !== undefined ? year : now.getFullYear();

        const startOfMonth = new Date(targetYear, targetMonth, 1);
        const endOfMonth = new Date(targetYear, targetMonth + 1, 0, 23, 59, 59);

        // 3. Get expenses grouped by category
        const result = await this.db
            .select({
                categoryId: expenses.categoryId,
                categoryName: categories.name,
                total: sql<number>`SUM(${expenses.amount})`.as('total'),
            })
            .from(expenses)
            .innerJoin(categories, eq(expenses.categoryId, categories.id))
            .where(
                and(
                    eq(expenses.republicId, republicId),
                    gte(expenses.date, startOfMonth),
                    lte(expenses.date, endOfMonth),
                ),
            )
            .groupBy(expenses.categoryId, categories.name)
            .execute();

        return result;
    }

    async getMonthlyTrend(ownerId: number, months: number = 6) {
        // 1. Find Republic
        const republicResult = await this.db
            .select()
            .from(republics)
            .where(eq(republics.ownerId, ownerId))
            .execute();

        if (republicResult.length === 0) {
            throw new NotFoundException('Republic not found');
        }
        const republicId = republicResult[0].id;

        // 2. Calculate date ranges for last N months
        const now = new Date();
        const monthlyData: { month: string; total: number }[] = [];

        for (let i = months - 1; i >= 0; i--) {
            const targetDate = new Date(now.getFullYear(), now.getMonth() - i, 1);
            const startOfMonth = new Date(targetDate.getFullYear(), targetDate.getMonth(), 1);
            const endOfMonth = new Date(targetDate.getFullYear(), targetDate.getMonth() + 1, 0, 23, 59, 59);

            const expenseList = await this.db
                .select()
                .from(expenses)
                .where(
                    and(
                        eq(expenses.republicId, republicId),
                        gte(expenses.date, startOfMonth),
                        lte(expenses.date, endOfMonth),
                    ),
                )
                .execute();

            const total = expenseList.reduce((sum, exp) => sum + exp.amount, 0);

            monthlyData.push({
                month: targetDate.toLocaleString('default', { month: 'short', year: 'numeric' }),
                total,
            });
        }

        return monthlyData;
    }
}
