import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import { AppModule } from './app.module';
import { getVersionInfo } from './common/version';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks();

  const port = parseInt(process.env.PORT ?? '3000', 10);
  await app.listen(port, '0.0.0.0');

  const info = getVersionInfo();
  Logger.log(
    `nest-release-demo v${info.version} listening on port ${port} (release dir: ${info.releaseDir})`,
    'Bootstrap',
  );
}
bootstrap();
