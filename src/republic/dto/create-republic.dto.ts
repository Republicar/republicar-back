import { IsNotEmpty, IsNumber, IsString } from 'class-validator';

export class CreateRepublicDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsNumber()
  @IsNotEmpty()
  rooms: number;
}
