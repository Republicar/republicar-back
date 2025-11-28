import {
  Body,
  Controller,
  Get,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { CategoryService } from './category.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { AuthGuard } from '@nestjs/passport';

interface RequestWithUser extends Request {
  user: {
    userId: number;
    role: string;
  };
}

@Controller('category')
export class CategoryController {
  constructor(private readonly categoryService: CategoryService) {}

  @UseGuards(AuthGuard('jwt'))
  @Post()
  async create(
    @Body() createCategoryDto: CreateCategoryDto,
    @Request() req: RequestWithUser,
  ) {
    return this.categoryService.create(createCategoryDto, req.user.userId);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get()
  async findAll(@Request() req: RequestWithUser) {
    return this.categoryService.findAll(req.user.userId);
  }
}
