import {
    Body,
    Controller,
    Get,
    Param,
    Post,
    Request,
    UseGuards,
    ParseIntPipe,
} from '@nestjs/common';
import { ReportService } from './report.service';
import { CreateReportDto } from './dto/create-report.dto';
import { AuthGuard } from '@nestjs/passport';

interface RequestWithUser extends Request {
    user: {
        userId: number;
        role: string;
    };
}

@Controller('report')
export class ReportController {
    constructor(private readonly reportService: ReportService) { }

    @UseGuards(AuthGuard('jwt'))
    @Post()
    async create(
        @Body() createReportDto: CreateReportDto,
        @Request() req: RequestWithUser,
    ) {
        return this.reportService.create(createReportDto, req.user.userId);
    }

    @UseGuards(AuthGuard('jwt'))
    @Get()
    async findAll(@Request() req: RequestWithUser) {
        return this.reportService.findAll(req.user.userId);
    }

    @UseGuards(AuthGuard('jwt'))
    @Get(':id')
    async findOne(
        @Param('id', ParseIntPipe) id: number,
        @Request() req: RequestWithUser,
    ) {
        return this.reportService.findOne(id, req.user.userId);
    }
}
