import { Module } from '@nestjs/common';
import { OccupantService } from './occupant.service';
import { OccupantController } from './occupant.controller';

@Module({
  controllers: [OccupantController],
  providers: [OccupantService],
})
export class OccupantModule {}
