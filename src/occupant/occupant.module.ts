import { Module } from '@nestjs/common';
import { OccupantService } from './occupant.service';
import { OccupantController } from './occupant.controller';
import { OccupantPortalController } from './occupant-portal.controller';
import { OccupantPortalService } from './occupant-portal.service';

@Module({
  controllers: [OccupantController, OccupantPortalController],
  providers: [OccupantService, OccupantPortalService],
})
export class OccupantModule { }
