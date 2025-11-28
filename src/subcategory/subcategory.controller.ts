import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { SubcategoryService } from './subcategory.service';
import { CreateSubcategoryDto } from './dto/create-subcategory.dto';
import { AuthGuard } from '@nestjs/passport';

interface RequestWithUser extends Request {
  user: {
    userId: number;
    role: string;
  };
}

@Controller('subcategory')
export class SubcategoryController {
  constructor(private readonly subcategoryService: SubcategoryService) {}

  @UseGuards(AuthGuard('jwt'))
  @Post()
  async create(
    @Body() createSubcategoryDto: CreateSubcategoryDto,
    @Request() req: RequestWithUser,
  ) {
    return this.subcategoryService.create(
      createSubcategoryDto,
      req.user.userId,
    );
  }

  @UseGuards(AuthGuard('jwt'))
  @Get(':categoryId')
  async findAll(
    @Param('categoryId', ParseIntPipe) categoryId: number,
    @Request() req: RequestWithUser,
  ) {
    return this.subcategoryService.findAll(categoryId, req.user.userId);
  }
}
