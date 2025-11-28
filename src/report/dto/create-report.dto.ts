import { IsDateString, IsEnum, IsNotEmpty } from 'class-validator';

export enum SplitMethod {
    EQUAL = 'EQUAL',
    PROPORTIONAL = 'PROPORTIONAL',
}

export class CreateReportDto {
    @IsDateString()
    @IsNotEmpty()
    startDate: string;

    @IsDateString()
    @IsNotEmpty()
    endDate: string;

    @IsEnum(SplitMethod)
    @IsNotEmpty()
    splitMethod: SplitMethod;
}
