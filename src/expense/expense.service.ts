import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { InjectDrizzle } from '@knaadh/nestjs-drizzle-turso';
import { LibSQLDatabase } from 'drizzle-orm/libsql';
import * as schema from '../republic/schema';
import { expenses } from './schema';
import { republics } from '../republic/schema';
import { categories } from '../category/schema';
import { subcategories } from '../subcategory/schema';
import { InferSelectModel, eq, and, gte, lte } from 'drizzle-orm';

type Republic = InferSelectModel<typeof republics>;

@Injectable()
export class ExpenseService {
  constructor(@InjectDrizzle() private db: LibSQLDatabase<typeof schema>) { }

  async create(createExpenseDto: CreateExpenseDto, ownerId: number) {
    const { description, amount, date, categoryId, subcategoryId } =
      createExpenseDto;

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

    // 2. Validate Category
    const categoryResult = await this.db
      .select()
      .from(categories)
      .where(eq(categories.id, categoryId))
      .execute();

    if (categoryResult.length === 0) {
      throw new NotFoundException('Category not found');
    }

    const category = categoryResult[0];
    if (category.republicId !== republicId) {
      throw new NotFoundException('Category does not belong to this republic');
    }

    // 3. Validate Subcategory (if provided)
    if (subcategoryId) {
      const subcategoryResult = await this.db
        .select()
        .from(subcategories)
        .where(eq(subcategories.id, subcategoryId))
        .execute();

      if (subcategoryResult.length === 0) {
        throw new NotFoundException('Subcategory not found');
      }

      const subcategory = subcategoryResult[0];
      if (subcategory.categoryId !== categoryId) {
        throw new BadRequestException(
          'Subcategory does not belong to the specified category',
        );
      }
    }

    // 4. Create expense
    await this.db
      .insert(expenses)
      .values({
        description,
        amount,
        date: new Date(date),
        republicId,
        categoryId,
        subcategoryId: subcategoryId || null,
        createdAt: new Date(),
      })
      .execute();

    return { message: 'Expense created successfully' };
  }

  async findAll(
    ownerId: number,
    filters: { startDate?: string; endDate?: string; categoryId?: number },
  ) {
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

    // 2. Build query
    const conditions = [eq(expenses.republicId, republicId)];

    if (filters.startDate) {
      conditions.push(gte(expenses.date, new Date(filters.startDate)));
    }

    if (filters.endDate) {
      conditions.push(lte(expenses.date, new Date(filters.endDate)));
    }

    if (filters.categoryId) {
      conditions.push(eq(expenses.categoryId, filters.categoryId));
    }

    // 3. Execute query
    return this.db
      .select()
      .from(expenses)
      .where(and(...conditions))
      .execute();
  }

  async toggleExclusion(id: number, ownerId: number) {
    // 1. Verify ownership
    const expenseResult = await this.db
      .select()
      .from(expenses)
      .where(eq(expenses.id, id))
      .execute();

    if (expenseResult.length === 0) {
      throw new NotFoundException('Expense not found');
    }
    const expense = expenseResult[0];

    const republicResult = await this.db
      .select()
      .from(republics)
      .where(eq(republics.id, expense.republicId))
      .execute();

    if (republicResult.length === 0 || republicResult[0].ownerId !== ownerId) {
      throw new NotFoundException('Expense not found or access denied');
    }

    if (expense.reportId) {
      throw new BadRequestException('Cannot modify expense that is already included in a report');
    }

    // 2. Toggle
    await this.db
      .update(expenses)
      .set({ isExcluded: !expense.isExcluded })
      .where(eq(expenses.id, id))
      .execute();

    return { message: 'Expense exclusion status updated', isExcluded: !expense.isExcluded };
  }
}
