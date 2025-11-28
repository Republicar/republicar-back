import { Body, Controller, Post, Request, UseGuards } from '@nestjs/common';
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
  constructor(private readonly expenseService: ExpenseService) {}

  @UseGuards(AuthGuard('jwt'))
  @Post()
  async create(
    @Body() createExpenseDto: CreateExpenseDto,
    @Request() req: RequestWithUser,
  ) {
    return this.expenseService.create(createExpenseDto, req.user.userId);
  }
}
