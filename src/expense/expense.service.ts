import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { InjectDrizzle } from '@knaadh/nestjs-drizzle-turso';
import { LibSQLDatabase } from 'drizzle-orm/libsql';
import * as schema from '../republic/schema';
import { expenses } from './schema';
import { republics } from '../republic/schema';
import { InferSelectModel, eq } from 'drizzle-orm';

type Republic = InferSelectModel<typeof republics>;

@Injectable()
export class ExpenseService {
  constructor(@InjectDrizzle() private db: LibSQLDatabase<typeof schema>) {}

  async create(createExpenseDto: CreateExpenseDto, ownerId: number) {
    const { description, amount, date } = createExpenseDto;

    // 1. Find the republic owned by the user
    const republic: Republic[] = await this.db
      .select()
      .from(republics)
      .where(eq(republics.ownerId, ownerId))
      .execute();

    if (republic.length === 0) {
      throw new NotFoundException('Republic not found for this owner');
    }

    const republicId = republic[0].id;

    // 2. Create expense
    await this.db
      .insert(expenses)
      .values({
        description,
        amount,
        date: new Date(date),
        republicId,
        createdAt: new Date(),
      })
      .execute();

    return { message: 'Expense registered successfully' };
  }
}
