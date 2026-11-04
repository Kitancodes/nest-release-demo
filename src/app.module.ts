import { Module } from '@nestjs/common';
import { HealthController } from './health/health.controller';
import { ProductsController } from './products/products.controller';
import { UsersController } from './users/users.controller';

@Module({
  controllers: [HealthController, ProductsController, UsersController],
})
export class AppModule {}
