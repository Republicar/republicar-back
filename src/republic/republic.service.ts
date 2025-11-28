import { Injectable } from '@nestjs/common';
import { CreateRepublicDto } from './dto/create-republic.dto';
import { InjectDrizzle } from '@knaadh/nestjs-drizzle-turso';
import { LibSQLDatabase } from 'drizzle-orm/libsql';
import * as schema from '../database/schema';
import { republics } from '../database/schema';

@Injectable()
export class RepublicService {
  constructor(@InjectDrizzle() private db: LibSQLDatabase<typeof schema>) {}

  async create(createRepublicDto: CreateRepublicDto, ownerId: number) {
    const { name, address, rooms } = createRepublicDto;

    await this.db
      .insert(republics)
      .values({
        name,
        address,
        rooms,
        ownerId,
      })
      .execute();

    return { message: 'Republic created successfully' };
  }
}
