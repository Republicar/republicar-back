import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { DrizzleTursoModule } from '@knaadh/nestjs-drizzle-turso';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import * as usersSchema from './users/schema';
import * as republicsSchema from './republic/schema';
import { AuthModule } from './auth/auth.module';
import { RepublicModule } from './republic/republic.module';
import { OccupantModule } from './occupant/occupant.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    DrizzleTursoModule.registerAsync({
      useFactory: (configService: ConfigService) => ({
        turso: {
          config: {
            url: configService.get<string>('TURSO_DATABASE_URL')!,
            authToken: configService.get<string>('TURSO_AUTH_TOKEN'),
          },
        },
        config: {
          schema: { ...usersSchema, ...republicsSchema },
        },
      }),
      inject: [ConfigService],
    }),
    AuthModule,
    RepublicModule,
    OccupantModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
