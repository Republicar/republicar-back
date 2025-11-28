import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectDrizzle } from '@knaadh/nestjs-drizzle-turso';
import { LibSQLDatabase } from 'drizzle-orm/libsql';
import * as schema from '../users/schema';
import { users } from '../users/schema';
import { reports, reportShares } from '../report/schema';
import { eq } from 'drizzle-orm';

@Injectable()
export class OccupantPortalService {
    constructor(@InjectDrizzle() private db: LibSQLDatabase<typeof schema>) { }

    async getMyReports(occupantId: number) {
        // Get all reports where occupant has a share
        const myShares = await this.db
            .select({
                reportId: reportShares.reportId,
                shareAmount: reportShares.shareAmount,
                percentage: reportShares.percentage,
                reportStartDate: reports.startDate,
                reportEndDate: reports.endDate,
                reportTotalAmount: reports.totalAmount,
                reportSplitMethod: reports.splitMethod,
                reportCreatedAt: reports.createdAt,
            })
            .from(reportShares)
            .innerJoin(reports, eq(reportShares.reportId, reports.id))
            .where(eq(reportShares.occupantId, occupantId))
            .execute();

        return myShares.map((share) => ({
            reportId: share.reportId,
            startDate: share.reportStartDate,
            endDate: share.reportEndDate,
            totalAmount: share.reportTotalAmount,
            splitMethod: share.reportSplitMethod,
            myShare: share.shareAmount,
            myPercentage: share.percentage,
            createdAt: share.reportCreatedAt,
        }));
    }

    async getReportDetails(reportId: number, occupantId: number) {
        // Verify occupant has access to this report
        const myShare = await this.db
            .select()
            .from(reportShares)
            .where(
                eq(reportShares.reportId, reportId),
            )
            .execute();

        const occupantShare = myShare.find((s) => s.occupantId === occupantId);

        if (!occupantShare) {
            throw new ForbiddenException('You do not have access to this report');
        }

        // Get report details
        const reportResult = await this.db
            .select()
            .from(reports)
            .where(eq(reports.id, reportId))
            .execute();

        if (reportResult.length === 0) {
            throw new NotFoundException('Report not found');
        }

        const report = reportResult[0];

        // Get all shares for context (so occupant can see how the split was calculated)
        const allShares = await this.db
            .select({
                occupantName: users.name,
                shareAmount: reportShares.shareAmount,
                percentage: reportShares.percentage,
            })
            .from(reportShares)
            .innerJoin(users, eq(reportShares.occupantId, users.id))
            .where(eq(reportShares.reportId, reportId))
            .execute();

        return {
            ...report,
            myShare: occupantShare.shareAmount,
            myPercentage: occupantShare.percentage,
            allShares,
        };
    }
}
