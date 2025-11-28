import {
  IsDateString,
  IsNotEmpty,
  IsString,
  Min,
  IsInt,
  IsOptional,
  IsNumber,
} from 'class-validator';

export class CreateExpenseDto {
  @IsString()
  @IsNotEmpty()
  description: string;

  @IsNumber()
  @Min(0)
  amount: number;

  @IsDateString()
  @IsNotEmpty()
  date: string;

  @IsInt()
  @IsNotEmpty()
  categoryId: number;

  @IsInt()
  @IsOptional()
  subcategoryId?: number;
}
