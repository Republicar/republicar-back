/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment */
import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CreateOccupantDto } from './dto/create-occupant.dto';
import { UpdateOccupantDto } from './dto/update-occupant.dto';
import { InjectDrizzle } from '@knaadh/nestjs-drizzle-turso';
import { LibSQLDatabase } from 'drizzle-orm/libsql';
import * as schema from '../database/schema';
import { users, republics } from '../database/schema';
import { InferSelectModel } from 'drizzle-orm';

type Republic = InferSelectModel<typeof republics>;
type User = InferSelectModel<typeof users>;

import * as bcrypt from 'bcrypt';
import { eq } from 'drizzle-orm';

@Injectable()
export class OccupantService {
  constructor(@InjectDrizzle() private db: LibSQLDatabase<typeof schema>) {}

  async create(createOccupantDto: CreateOccupantDto, ownerId: number) {
    const { name, email, password } = createOccupantDto;

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

    // 2. Check if user already exists

    const existingUser: User[] = await this.db
      .select()
      .from(users)
      .where(eq(users.email, email))
      .execute();

    if (existingUser.length > 0) {
      throw new ConflictException('User with this email already exists');
    }

    // 3. Hash password
    const salt = await bcrypt.genSalt();
    const passwordHash = await bcrypt.hash(password, salt);

    // 4. Create user with role OCCUPANT and republicId

    await this.db
      .insert(users)
      .values({
        name,
        email,
        passwordHash,
        role: 'OCCUPANT',
        republicId,
      })
      .execute();

    return { message: 'Occupant added successfully' };
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

    // 2. Find all occupants of this republic

    const occupants: User[] = await this.db
      .select()
      .from(users)
      .where(eq(users.republicId, republicId))
      .execute();

    // 3. Return occupants (excluding sensitive data)
    return occupants.map((occupant) => {
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { passwordHash, ...result } = occupant;
      return result;
    });
  }

  async update(
    id: number,
    updateOccupantDto: UpdateOccupantDto,
    ownerId: number,
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

    // 2. Check if the occupant belongs to the republic
    const occupant: User[] = await this.db
      .select()
      .from(users)
      .where(eq(users.id, id))
      .execute();

    if (occupant.length === 0) {
      throw new NotFoundException('Occupant not found');
    }

    if (occupant[0].republicId !== republicId) {
      throw new NotFoundException('Occupant not found in your republic');
    }

    // 3. Check for duplicate email if email is being updated
    if (updateOccupantDto.email) {
      const existingUser: User[] = await this.db
        .select()
        .from(users)
        .where(eq(users.email, updateOccupantDto.email))
        .execute();

      if (existingUser.length > 0 && existingUser[0].id !== id) {
        throw new ConflictException('Email already in use');
      }
    }

    // 4. Update occupant
    await this.db
      .update(users)
      .set(updateOccupantDto)
      .where(eq(users.id, id))
      .execute();

    return { message: 'Occupant updated successfully' };
  }
}
