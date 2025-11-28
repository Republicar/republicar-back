import { Body, Controller, Post, Request, UseGuards } from '@nestjs/common';
import { RepublicService } from './republic.service';
import { CreateRepublicDto } from './dto/create-republic.dto';
import { AuthGuard } from '@nestjs/passport';

interface RequestWithUser extends Request {
  user: {
    userId: number;
  };
}

@Controller('republic')
export class RepublicController {
  constructor(private readonly republicService: RepublicService) {}

  @UseGuards(AuthGuard('jwt'))
  @Post()
  async create(
    @Body() createRepublicDto: CreateRepublicDto,
    @Request() req: RequestWithUser,
  ) {
    return this.republicService.create(createRepublicDto, req.user.userId);
  }
}
