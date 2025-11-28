import {
  IsDateString,
  IsNotEmpty,
  IsNumber,
  IsString,
  Min,
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
}
