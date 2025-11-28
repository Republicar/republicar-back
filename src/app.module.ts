import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { DrizzleTursoModule } from '@knaadh/nestjs-drizzle-turso';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import * as usersSchema from './users/schema';
import * as republicsSchema from './republic/schema';
import * as expensesSchema from './expense/schema';
import * as categoriesSchema from './category/schema';
import * as subcategoriesSchema from './subcategory/schema';
import { AuthModule } from './auth/auth.module';
import { RepublicModule } from './republic/republic.module';
import { OccupantModule } from './occupant/occupant.module';
import { ExpenseModule } from './expense/expense.module';
import { CategoryModule } from './category/category.module';
import { SubcategoryModule } from './subcategory/subcategory.module';

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
          schema: {
            ...usersSchema,
            ...republicsSchema,
            ...expensesSchema,
            ...categoriesSchema,
            ...subcategoriesSchema,
          },
        },
      }),
      inject: [ConfigService],
    }),
    AuthModule,
    RepublicModule,
    OccupantModule,
    ExpenseModule,
    CategoryModule,
    SubcategoryModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
