import { Module } from '@nestjs/common';
import { RepublicService } from './republic.service';
import { RepublicController } from './republic.controller';

@Module({
  controllers: [RepublicController],
  providers: [RepublicService],
})
export class RepublicModule {}
