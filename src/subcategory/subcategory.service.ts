import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateSubcategoryDto } from './dto/create-subcategory.dto';
import { InjectDrizzle } from '@knaadh/nestjs-drizzle-turso';
import { LibSQLDatabase } from 'drizzle-orm/libsql';
import * as schema from '../republic/schema';
import { subcategories } from './schema';
import { categories } from '../category/schema';
import { republics } from '../republic/schema';
import { eq } from 'drizzle-orm';

@Injectable()
export class SubcategoryService {
  constructor(@InjectDrizzle() private db: LibSQLDatabase<typeof schema>) {}

  async create(createSubcategoryDto: CreateSubcategoryDto, ownerId: number) {
    const { name, categoryId } = createSubcategoryDto;

    // 1. Verify category exists and belongs to a republic owned by the user
    const categoryResult = await this.db
      .select()
      .from(categories)
      .where(eq(categories.id, categoryId))
      .execute();

    if (categoryResult.length === 0) {
      throw new NotFoundException('Category not found');
    }

    const category = categoryResult[0];

    // Check ownership of the republic associated with the category
    const republicResult = await this.db
      .select()
      .from(republics)
      .where(eq(republics.id, category.republicId))
      .execute();

    if (republicResult.length === 0 || republicResult[0].ownerId !== ownerId) {
      throw new NotFoundException('Category not found or access denied');
    }

    // 2. Create subcategory
    await this.db
      .insert(subcategories)
      .values({
        name,
        categoryId,
        createdAt: new Date(),
      })
      .execute();

    return { message: 'Subcategory created successfully' };
  }

  async findAll(categoryId: number, ownerId: number) {
    // 1. Verify category exists and belongs to a republic owned by the user
    const categoryResult = await this.db
      .select()
      .from(categories)
      .where(eq(categories.id, categoryId))
      .execute();

    if (categoryResult.length === 0) {
      throw new NotFoundException('Category not found');
    }

    const category = categoryResult[0];

    const republicResult = await this.db
      .select()
      .from(republics)
      .where(eq(republics.id, category.republicId))
      .execute();

    if (republicResult.length === 0 || republicResult[0].ownerId !== ownerId) {
      throw new NotFoundException('Category not found or access denied');
    }

    // 2. Find subcategories
    return this.db
      .select()
      .from(subcategories)
      .where(eq(subcategories.categoryId, categoryId))
      .execute();
  }
}
