import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { DrizzleTursoModule } from '@knaadh/nestjs-drizzle-turso';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import * as schema from './database/schema';

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
          schema: { ...schema },
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
