import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { OccupantService } from './occupant.service';
import { CreateOccupantDto } from './dto/create-occupant.dto';
import { UpdateOccupantDto } from './dto/update-occupant.dto';
import { AuthGuard } from '@nestjs/passport';

interface RequestWithUser extends Request {
  user: {
    userId: number;
    role: string;
  };
}

@Controller('occupant')
export class OccupantController {
  constructor(private readonly occupantService: OccupantService) {}

  @UseGuards(AuthGuard('jwt'))
  @Post()
  async create(
    @Body() createOccupantDto: CreateOccupantDto,
    @Request() req: RequestWithUser,
  ) {
    // Optional: Check if user is OWNER (though service logic implies it by looking for owned republic)
    // if (req.user.role !== 'OWNER') { throw new ForbiddenException(...) }

    return this.occupantService.create(createOccupantDto, req.user.userId);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get()
  async findAll(@Request() req: RequestWithUser) {
    return this.occupantService.findAll(req.user.userId);
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateOccupantDto: UpdateOccupantDto,
    @Request() req: RequestWithUser,
  ) {
    return this.occupantService.update(+id, updateOccupantDto, req.user.userId);
  }
}
