import {
    Controller,
    Get,
    Request,
    UseGuards,
    Query,
    ParseIntPipe,
} from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { AuthGuard } from '@nestjs/passport';

interface RequestWithUser extends Request {
    user: {
        userId: number;
        role: string;
    };
}

@Controller('dashboard')
export class DashboardController {
    constructor(private readonly dashboardService: DashboardService) { }

    @UseGuards(AuthGuard('jwt'))
    @Get('summary')
    async getCurrentMonthSummary(@Request() req: RequestWithUser) {
        return this.dashboardService.getCurrentMonthSummary(req.user.userId);
    }

    @UseGuards(AuthGuard('jwt'))
    @Get('by-category')
    async getExpensesByCategory(
        @Request() req: RequestWithUser,
        @Query('month', new ParseIntPipe({ optional: true })) month?: number,
        @Query('year', new ParseIntPipe({ optional: true })) year?: number,
    ) {
        return this.dashboardService.getExpensesByCategory(req.user.userId, month, year);
    }

    @UseGuards(AuthGuard('jwt'))
    @Get('monthly-trend')
    async getMonthlyTrend(
        @Request() req: RequestWithUser,
        @Query('months', new ParseIntPipe({ optional: true })) months?: number,
    ) {
        return this.dashboardService.getMonthlyTrend(req.user.userId, months);
    }
}
