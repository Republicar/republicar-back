import {
    Injectable,
    NotFoundException,
    BadRequestException,
} from '@nestjs/common';
import { CreateReportDto, SplitMethod } from './dto/create-report.dto';
import { InjectDrizzle } from '@knaadh/nestjs-drizzle-turso';
import { LibSQLDatabase } from 'drizzle-orm/libsql';
import * as schema from '../republic/schema';
import { reports, reportShares } from './schema';
import { expenses } from '../expense/schema';
import { republics } from '../republic/schema';
import { users } from '../users/schema';
import { InferSelectModel, eq, and, gte, lte, isNull } from 'drizzle-orm';

@Injectable()
export class ReportService {
    constructor(@InjectDrizzle() private db: LibSQLDatabase<typeof schema>) { }

    async create(createReportDto: CreateReportDto, ownerId: number) {
        const { startDate, endDate, splitMethod } = createReportDto;
        const start = new Date(startDate);
        const end = new Date(endDate);

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

        // 2. Fetch Expenses
        const expenseList = await this.db
            .select()
            .from(expenses)
            .where(
                and(
                    eq(expenses.republicId, republicId),
                    gte(expenses.date, start),
                    lte(expenses.date, end),
                    eq(expenses.isExcluded, false),
                    isNull(expenses.reportId), // Only include expenses not yet in a report
                ),
            )
            .execute();

        if (expenseList.length === 0) {
            throw new BadRequestException('No eligible expenses found for this period');
        }

        const totalAmount = expenseList.reduce((sum, exp) => sum + exp.amount, 0);

        // 3. Fetch Occupants
        const occupants = await this.db
            .select()
            .from(users)
            .where(eq(users.republicId, republicId))
            .execute();

        if (occupants.length === 0) {
            throw new BadRequestException('No occupants found in republic');
        }

        // 4. Calculate Shares
        const shares: { occupantId: number; amount: number; percentage: number | null }[] = [];

        if (splitMethod === SplitMethod.EQUAL) {
            const count = occupants.length;
            const baseShare = Math.floor(totalAmount / count);
            let remainder = totalAmount % count;

            for (const occupant of occupants) {
                let amount = baseShare;
                if (remainder > 0) {
                    amount += 1;
                    remainder -= 1;
                }
                shares.push({ occupantId: occupant.id, amount, percentage: null });
            }
        } else if (splitMethod === SplitMethod.PROPORTIONAL) {
            const totalIncome = occupants.reduce((sum, occ) => sum + (occ.income || 0), 0);

            if (totalIncome === 0) {
                throw new BadRequestException('Total income is zero, cannot split proportionally. Please update occupant incomes or use Equal split.');
            }

            let distributedAmount = 0;

            for (let i = 0; i < occupants.length; i++) {
                const occupant = occupants[i];
                const income = occupant.income || 0;

                // Calculate percentage (stored as integer with 2 decimal places, e.g. 2500 = 25.00%)
                // percentage = (income / totalIncome) * 10000
                const percentage = Math.round((income / totalIncome) * 10000);

                // Calculate share
                let amount = Math.floor((totalAmount * income) / totalIncome);

                // Adjust last person to handle rounding errors
                if (i === occupants.length - 1) {
                    amount = totalAmount - distributedAmount;
                }

                distributedAmount += amount;
                shares.push({ occupantId: occupant.id, amount, percentage });
            }
        }

        // 5. Save Report
        const reportResult = await this.db
            .insert(reports)
            .values({
                republicId,
                startDate: start,
                endDate: end,
                totalAmount,
                splitMethod,
                createdAt: new Date(),
            })
            .returning({ id: reports.id })
            .execute();

        const reportId = reportResult[0].id;

        // 6. Save Shares
        for (const share of shares) {
            await this.db
                .insert(reportShares)
                .values({
                    reportId,
                    occupantId: share.occupantId,
                    shareAmount: share.amount,
                    percentage: share.percentage,
                })
                .execute();
        }

        // 7. Update Expenses with Report ID
        for (const expense of expenseList) {
            await this.db
                .update(expenses)
                .set({ reportId })
                .where(eq(expenses.id, expense.id))
                .execute();
        }

        return { message: 'Report generated successfully', reportId };
    }

    async findAll(ownerId: number) {
        const republicResult = await this.db
            .select()
            .from(republics)
            .where(eq(republics.ownerId, ownerId))
            .execute();

        if (republicResult.length === 0) {
            throw new NotFoundException('Republic not found');
        }
        const republicId = republicResult[0].id;

        return this.db
            .select()
            .from(reports)
            .where(eq(reports.republicId, republicId))
            .execute();
    }

    async findOne(id: number, ownerId: number) {
        // Verify ownership
        const republicResult = await this.db
            .select()
            .from(republics)
            .where(eq(republics.ownerId, ownerId))
            .execute();

        if (republicResult.length === 0) {
            throw new NotFoundException('Republic not found');
        }
        const republicId = republicResult[0].id;

        const reportResult = await this.db
            .select()
            .from(reports)
            .where(and(eq(reports.id, id), eq(reports.republicId, republicId)))
            .execute();

        if (reportResult.length === 0) {
            throw new NotFoundException('Report not found');
        }

        const report = reportResult[0];

        const shares = await this.db
            .select({
                occupantName: users.name,
                shareAmount: reportShares.shareAmount,
                percentage: reportShares.percentage
            })
            .from(reportShares)
            .innerJoin(users, eq(reportShares.occupantId, users.id))
            .where(eq(reportShares.reportId, id))
            .execute();

        return { ...report, shares };
    }
}
