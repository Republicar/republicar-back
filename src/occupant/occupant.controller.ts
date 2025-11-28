import { Body, Controller, Post, Request, UseGuards } from '@nestjs/common';
import { OccupantService } from './occupant.service';
import { CreateOccupantDto } from './dto/create-occupant.dto';
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
}
