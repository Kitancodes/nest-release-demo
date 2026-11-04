import { Controller, Get } from '@nestjs/common';

const USERS = [
  { id: 1, name: 'Ada Lovelace', role: 'admin' },
  { id: 2, name: 'Alan Turing', role: 'engineer' },
  { id: 3, name: 'Grace Hopper', role: 'engineer' },
];

@Controller('api/users')
export class UsersController {
  @Get()
  findAll() {
    return { count: USERS.length, data: USERS };
  }
}
