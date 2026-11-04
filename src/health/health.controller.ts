import { Controller, Get } from '@nestjs/common';
import { getVersionInfo } from '../common/version';

@Controller()
export class HealthController {
  @Get()
  root() {
    const { name, version } = getVersionInfo();
    return { message: `Welcome to ${name}`, version };
  }

  @Get('health')
  health() {
    const { version } = getVersionInfo();
    return {
      status: 'ok',
      version,
      uptimeSeconds: Math.round(process.uptime()),
      timestamp: new Date().toISOString(),
    };
  }

  @Get('version')
  version() {
    return getVersionInfo();
  }
}
