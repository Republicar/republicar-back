import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateCategoryDto } from './dto/create-category.dto';
import { InjectDrizzle } from '@knaadh/nestjs-drizzle-turso';
import { LibSQLDatabase } from 'drizzle-orm/libsql';
import * as schema from '../republic/schema';
import { categories } from './schema';
import { republics } from '../republic/schema';
import { InferSelectModel, eq } from 'drizzle-orm';

type Republic = InferSelectModel<typeof republics>;

@Injectable()
export class CategoryService {
  constructor(@InjectDrizzle() private db: LibSQLDatabase<typeof schema>) {}

  async create(createCategoryDto: CreateCategoryDto, ownerId: number) {
    const { name } = createCategoryDto;

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

    // 2. Create category
    await this.db
      .insert(categories)
      .values({
        name,
        republicId,
        createdAt: new Date(),
      })
      .execute();

    return { message: 'Category created successfully' };
  }

  async findAll(ownerId: number) {
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

    // 2. Find categories for the republic
    return this.db
      .select()
      .from(categories)
      .where(eq(categories.republicId, republicId))
      .execute();
  }
}
