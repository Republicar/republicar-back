import { PartialType } from '@nestjs/swagger';
import { CreateOccupantDto } from './create-occupant.dto';

export class UpdateOccupantDto extends PartialType(CreateOccupantDto) {}
