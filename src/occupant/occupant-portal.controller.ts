import {
    Controller,
    Get,
    Request,
    UseGuards,
    Param,
    ParseIntPipe,
} from '@nestjs/common';
import { OccupantPortalService } from './occupant-portal.service';
import { AuthGuard } from '@nestjs/passport';

interface RequestWithUser extends Request {
    user: {
        userId: number;
        role: string;
    };
}

@Controller('occupant/portal')
export class OccupantPortalController {
    constructor(private readonly occupantPortalService: OccupantPortalService) { }

    @UseGuards(AuthGuard('jwt'))
    @Get('reports')
    async getMyReports(@Request() req: RequestWithUser) {
        return this.occupantPortalService.getMyReports(req.user.userId);
    }

    @UseGuards(AuthGuard('jwt'))
    @Get('reports/:id')
    async getReportDetails(
        @Param('id', ParseIntPipe) id: number,
        @Request() req: RequestWithUser,
    ) {
        return this.occupantPortalService.getReportDetails(id, req.user.userId);
    }
}
