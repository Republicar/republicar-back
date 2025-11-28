import {
  Body,
  Controller,
  Post,
  Request,
  UseGuards,
  Get,
  Query,
  Patch,
  Param,
  ParseIntPipe,
} from '@nestjs/common';
import { ExpenseService } from './expense.service';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { AuthGuard } from '@nestjs/passport';

interface RequestWithUser extends Request {
  user: {
    userId: number;
    role: string;
  };
}

@Controller('expense')
export class ExpenseController {
  constructor(private readonly expenseService: ExpenseService) { }

  @UseGuards(AuthGuard('jwt'))
  @Post()
  async create(
    @Body() createExpenseDto: CreateExpenseDto,
    @Request() req: RequestWithUser,
  ) {
    return this.expenseService.create(createExpenseDto, req.user.userId);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get()
  async findAll(
    @Request() req: RequestWithUser,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('categoryId') categoryId?: string,
  ) {
    return this.expenseService.findAll(req.user.userId, {
      startDate,
      endDate,
      categoryId: categoryId ? parseInt(categoryId, 10) : undefined,
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch(':id/exclude')
  async toggleExclusion(
    @Param('id', ParseIntPipe) id: number,
    @Request() req: RequestWithUser,
  ) {
    return this.expenseService.toggleExclusion(id, req.user.userId);
  }
}
